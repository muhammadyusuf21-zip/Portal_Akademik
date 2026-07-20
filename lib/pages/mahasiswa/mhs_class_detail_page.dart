import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';
import '../../utils/format_utils.dart';

class MhsClassDetailPage extends StatefulWidget {
  final Map<String, dynamic> kelasItem;
  final String mahasiswaId;
  final Map<String, dynamic> jadwalItem;

  const MhsClassDetailPage({
    super.key,
    required this.kelasItem,
    required this.mahasiswaId,
    required this.jadwalItem,
  });

  @override
  State<MhsClassDetailPage> createState() => _MhsClassDetailPageState();
}

class _MhsClassDetailPageState extends State<MhsClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _materiList = [];
  List<Map<String, dynamic>> _tugasList = [];
  Map<String, dynamic>? _myGrade;

  // Maps assignment ID -> student submission details (if any)
  final Map<String, Map<String, dynamic>> _mySubmissions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClassContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClassContent() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      final kId = widget.kelasItem['id'];
      final mId = widget.mahasiswaId;

      final futures = await Future.wait([
        // 1. Get materials
        client
            .from('materi')
            .select()
            .eq('kelas_id', kId)
            .order('created_at', ascending: false),
        // 2. Get assignments
        client
            .from('tugas')
            .select()
            .eq('kelas_id', kId)
            .order('created_at', ascending: false),
        // 3. Get my submissions
        client.from('pengumpulan_tugas').select().eq('mahasiswa_id', mId),
        // 4. Get my final grade
        client
            .from('nilai')
            .select()
            .eq('kelas_id', kId)
            .eq('mahasiswa_id', mId)
            .maybeSingle(),
      ]);

      _materiList = List<Map<String, dynamic>>.from(futures[0] as List);
      _tugasList = List<Map<String, dynamic>>.from(futures[1] as List);

      final submissionsList = List<Map<String, dynamic>>.from(
        futures[2] as List,
      );
      _mySubmissions.clear();
      for (var sub in submissionsList) {
        if (sub['tugas_id'] != null) {
          _mySubmissions[sub['tugas_id'].toString()] = sub;
        }
      }

      _myGrade = futures[3] as Map<String, dynamic>?;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat materi/tugas: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _snack(String msg, Color color) {
    AppTheme.showSnackBar(context, msg, backgroundColor: color);
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      // Use platformDefault on web so it opens in a new tab
      if (kIsWeb) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback: try launching directly since canLaunchUrl can return false on Android 11+
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            throw Exception("Could not launch $url");
          }
        }
      }
    } catch (e) {
      _snack("Gagal membuka tautan: $e", Colors.red);
    }
  }

  Future<void> _submitTugas(
    String tugasId,
    String tugasTitle,
    Map<String, dynamic>? existingSub,
  ) async {
    FilePickerResult? pickerResult = await FilePicker.pickFiles();
    if (pickerResult == null) return;

    final file = pickerResult!.files.first;

    // Check if confirming overwrite
    if (existingSub != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Ubah Jawaban"),
          content: const Text(
            "Anda sudah mengumpulkan jawaban. Apakah Anda yakin ingin menggantinya dengan file baru?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Ganti"),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.name}";
      // Use just the filename as path (bucket 'tugas' already provides the namespace)
      final storagePath = fileName;

      // 1. Upload to Storage
      if (kIsWeb) {
        if (file.bytes != null) {
          await client.storage
              .from('tugas')
              .uploadBinary(
                storagePath,
                file.bytes!,
                fileOptions: const FileOptions(upsert: true),
              );
        } else {
          throw Exception("File bytes kosong (web)");
        }
      } else {
        if (file.path != null) {
          await client.storage
              .from('tugas')
              .upload(
                storagePath,
                File(file.path!),
                fileOptions: const FileOptions(upsert: true),
              );
        } else {
          throw Exception("File path kosong (mobile)");
        }
      }

      final fileUrl = client.storage.from('tugas').getPublicUrl(storagePath);

      // 2. Insert or update db row
      if (existingSub == null) {
        await client.from('pengumpulan_tugas').insert({
          'tugas_id': tugasId,
          'mahasiswa_id': widget.mahasiswaId,
          'file_jawaban': fileUrl,
          'waktu_kumpul': DateTime.now().toIso8601String(),
        });
        _snack("Tugas berhasil dikumpulkan", Colors.green);
      } else {
        // If there was a previous file in storage, delete it
        final oldUrl = existingSub['file_jawaban'].toString();
        if (oldUrl.contains('/storage/v1/object/public/tugas/')) {
          final oldUri = Uri.parse(oldUrl);
          final pathSegment = oldUri.pathSegments.last;
          await client.storage.from('tugas').remove([pathSegment]);
        }

        await client
            .from('pengumpulan_tugas')
            .update({
              'file_jawaban': fileUrl,
              'waktu_kumpul': DateTime.now().toIso8601String(),
            })
            .eq('id', existingSub['id']);
        _snack("Jawaban berhasil diubah", Colors.green);
      }

      _loadClassContent();
    } catch (e) {
      setState(() => _isLoading = false);
      _snack("Gagal mengumpulkan tugas: $e", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mk = widget.kelasItem['mata_kuliah'] ?? {};
    final mkName = mk['nama'] ?? '';
    final cName = widget.kelasItem['nama'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text("Kelas $cName - $mkName"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined), text: "Materi"),
            Tab(icon: Icon(Icons.assignment_outlined), text: "Tugas"),
            Tab(icon: Icon(Icons.grade_outlined), text: "Nilai Akhir"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMateriTab(),
                _buildTugasTab(),
                _buildGradesTab(),
              ],
            ),
    );
  }

  Widget _buildMateriTab() {
    if (_materiList.isEmpty) {
      return const Center(child: Text("Belum ada materi kuliah di kelas ini."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _materiList.length,
      itemBuilder: (context, index) {
        final item = _materiList[index];
        IconData icon = Icons.insert_drive_file;
        if (item['tipe_file'] == 'video') icon = Icons.video_library;
        if (item['tipe_file'] == 'link') icon = Icons.link;

        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(icon)),
            title: Text(
              item['judul'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Format: ${item['tipe_file'].toUpperCase()}"),
            trailing: const Icon(Icons.download),
            onTap: () => _openLink(item['url_file'].toString()),
          ),
        );
      },
    );
  }

  Widget _buildTugasTab() {
    if (_tugasList.isEmpty) {
      return const Center(child: Text("Belum ada tugas kuliah di kelas ini."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tugasList.length,
      itemBuilder: (context, index) {
        final item = _tugasList[index];
        final tId = item['id'].toString();
        final title = item['judul'] ?? '';
        final desc = item['deskripsi'] ?? 'Tidak ada deskripsi.';

        final dl = DateTime.parse(item['deadline']).toLocal();
        final dlStr =
            "${dl.day}/${dl.month}/${dl.year} ${dl.hour.toString().padLeft(2, '0')}:${dl.minute.toString().padLeft(2, '0')}";

        final hasAttachment =
            item['url_file'] != null && item['url_file'].toString().isNotEmpty;
        final isPassed = DateTime.now().isAfter(dl);

        final mySub = _mySubmissions[tId];
        final isSubmitted = mySub != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSubmitted
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isSubmitted ? "SUDAH KUMPUL" : "BELUM KUMPUL",
                        style: TextStyle(
                          color: isSubmitted ? Colors.green : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Deadline: $dlStr",
                  style: TextStyle(
                    color: isPassed ? Colors.red : AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 20),
                Text(desc, style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                if (hasAttachment)
                  TextButton.icon(
                    icon: const Icon(Icons.attach_file, size: 16),
                    label: const Text(
                      "Unduh Lampiran Soal",
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _openLink(item['url_file']),
                  ),

                // Show grades if graded
                if (isSubmitted && mySub['nilai'] != null) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Text(
                        "Nilai: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        mySub['nilai'].toString(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (mySub['komentar'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Umpan Balik: ${mySub['komentar']}",
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],

                // Action buttons to submit or edit answers
                if (!isPassed) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(isSubmitted ? Icons.edit : Icons.upload),
                      label: Text(
                        isSubmitted ? "UBAH JAWABAN" : "KUMPULKAN JAWABAN",
                      ),
                      onPressed: () => _submitTugas(tId, title, mySub),
                    ),
                  ),
                ] else if (!isSubmitted) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "Tenggat waktu pengumpulan telah lewat.",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradesTab() {
    if (_myGrade == null) {
      return const Center(child: Text("Nilai akhir belum diinput oleh Dosen"));
    }

    final t = formatNilai(_myGrade!['nilai_tugas']);
    final uts = formatNilai(_myGrade!['nilai_uts']);
    final uas = formatNilai(_myGrade!['nilai_uas']);
    final akhir = formatNilai(_myGrade!['nilai_akhir']);
    final grade = _myGrade!['grade'] ?? '-';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Text(
                        "NILAI AKHIR KULIAH",
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primary.withOpacity(0.08),
                        child: Text(
                          grade,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Skor Akhir: $akhir",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const Divider(height: 40),
                      _buildGradeRow("Skor Rata-Rata Tugas (30%)", t),
                      const SizedBox(height: 12),
                      _buildGradeRow("Ujian Tengah Semester / UTS (30%)", uts),
                      const SizedBox(height: 12),
                      _buildGradeRow("Ujian Akhir Semester / UAS (40%)", uas),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeRow(String label, String score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
        ),
        Text(
          score,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
