import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';
import '../../utils/format_utils.dart';
import 'grading_page.dart';

class ClassDetailPage extends StatefulWidget {
  final Map<String, dynamic> kelasItem;
  final String dosenId;
  final int initialTabIndex;

  const ClassDetailPage({
    super.key,
    required this.kelasItem,
    required this.dosenId,
    this.initialTabIndex = 0,
  });

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _studentKrsList = [];
  List<Map<String, dynamic>> _materiList = [];
  List<Map<String, dynamic>> _tugasList = [];
  List<Map<String, dynamic>> _gradesList = [];
  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadAllClassData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllClassData() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      final kId = widget.kelasItem['id'];
      final jId = widget.kelasItem['jadwal']?['id'];

      final futures = await Future.wait([
        // 1. KRS status of students in this schedule
        jId != null
            ? client
                  .from('krs')
                  .select('*, mahasiswa(*, users(nama))')
                  .eq('jadwal_id', jId)
            : Future.value([]),
        // 2. Materials
        client
            .from('materi')
            .select()
            .eq('kelas_id', kId)
            .order('created_at', ascending: false),
        // 3. Assignments
        client
            .from('tugas')
            .select()
            .eq('kelas_id', kId)
            .order('created_at', ascending: false),
        // 4. Student Grades
        client
            .from('nilai')
            .select('*, mahasiswa(*, users(nama))')
            .eq('kelas_id', kId),
        // 5. Announcements for this class
        client
            .from('pengumuman')
            .select('*, users(nama)')
            .eq('kelas_id', kId)
            .order('created_at', ascending: false),
      ]);

      if (mounted) {
        setState(() {
          _studentKrsList = List<Map<String, dynamic>>.from(futures[0] as List);
          _materiList = List<Map<String, dynamic>>.from(futures[1] as List);
          _tugasList = List<Map<String, dynamic>>.from(futures[2] as List);
          _gradesList = List<Map<String, dynamic>>.from(futures[3] as List);
          _announcements = List<Map<String, dynamic>>.from(futures[4] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error memuat detail kelas: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _snack(String msg, Color color) {
    AppTheme.showSnackBar(context, msg, backgroundColor: color);
  }

  Future<void> _uploadMateri() async {
    final titleController = TextEditingController();
    String tipe = 'pdf';
    String url = '';
    FilePickerResult? pickerResult;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isLink = tipe == 'link';
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Unggah Materi Kuliah"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Judul Materi"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipe,
                  decoration: const InputDecoration(
                    labelText: "Tipe File/Sumber",
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pdf', child: Text("PDF Document")),
                    DropdownMenuItem(
                      value: 'word',
                      child: Text("Word Document"),
                    ),
                    DropdownMenuItem(value: 'ppt', child: Text("PowerPoint")),
                    DropdownMenuItem(value: 'video', child: Text("Video")),
                    DropdownMenuItem(value: 'gambar', child: Text("Gambar")),
                    DropdownMenuItem(
                      value: 'link',
                      child: Text("Tautan Eksternal (Drive/YouTube)"),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => tipe = val);
                  },
                ),
                const SizedBox(height: 16),
                if (!isLink) ...[
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text("Pilih File"),
                        onPressed: () async {
                          pickerResult = await FilePicker.pickFiles();
                          if (pickerResult != null) {
                            setDialogState(() {
                              url = pickerResult!.files.first.name;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          url.isEmpty ? "Belum ada file terpilih" : url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "URL Tautan (e.g. YouTube/Drive)",
                    ),
                    onChanged: (val) => url = val,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Simpan"),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      if (titleController.text.trim().isEmpty || url.isEmpty) {
        _snack("Judul dan file/link wajib diisi", Colors.orange);
        return;
      }

      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;
        String finalUrl = url;

        // Upload file to bucket if not a link
        if (tipe != 'link' && pickerResult != null) {
          final file = pickerResult!.files.first;
          final fileName =
              "${DateTime.now().millisecondsSinceEpoch}_${file.name}";
          final storagePath = fileName;

          if (kIsWeb) {
            if (file.bytes != null) {
              await client.storage
                  .from('materi')
                  .uploadBinary(
                    storagePath,
                    file.bytes!,
                    fileOptions: const FileOptions(upsert: true),
                  );
            } else {
              throw Exception("Web file bytes empty");
            }
          } else {
            if (file.path != null) {
              await client.storage
                  .from('materi')
                  .upload(
                    storagePath,
                    File(file.path!),
                    fileOptions: const FileOptions(upsert: true),
                  );
            } else {
              throw Exception("Mobile file path empty");
            }
          }
          finalUrl = client.storage.from('materi').getPublicUrl(storagePath);
        }

        // Insert into database
        await client.from('materi').insert({
          'kelas_id': widget.kelasItem['id'],
          'dosen_id': widget.dosenId,
          'judul': titleController.text.trim(),
          'tipe_file': tipe,
          'url_file': finalUrl,
        });

        _snack("Materi berhasil diunggah", Colors.green);
        _loadAllClassData();
      } catch (e) {
        setState(() => _isLoading = false);
        _snack("Gagal mengunggah materi: $e", Colors.red);
      }
    }
  }

  Future<void> _deleteMateri(String id, String url) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Materi"),
        content: const Text("Yakin ingin menghapus materi kuliah ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;

        // Try deleting from storage if it is a Supabase public URL
        if (url.contains('/storage/v1/object/public/materi/')) {
          final uri = Uri.parse(url);
          final pathSegment = uri.pathSegments.last;
          await client.storage.from('materi').remove([pathSegment]);
        }

        await client.from('materi').delete().eq('id', id);
        _snack("Materi berhasil dihapus", Colors.green);
        _loadAllClassData();
      } catch (e) {
        setState(() => _isLoading = false);
        _snack("Gagal menghapus: $e", Colors.red);
      }
    }
  }

  // ===========================================================================
  // 2. TUGAS CRUD
  // ===========================================================================
  Future<void> _createTugas() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = const TimeOfDay(hour: 23, minute: 59);

    FilePickerResult? pickerResult;
    String attachmentName = "";

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Buat Tugas Baru"),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Judul Tugas"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Deskripsi Tugas",
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deadline Pickers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tanggal: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      ),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null)
                            setDialogState(() => selectedDate = date);
                        },
                        child: const Text("Pilih"),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Jam: ${selectedTime.format(ctx)}"),
                      TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                          );
                          if (time != null)
                            setDialogState(() => selectedTime = time);
                        },
                        child: const Text("Pilih"),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Attachment
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text("Lampiran Soal"),
                        onPressed: () async {
                          pickerResult = await FilePicker.pickFiles();
                          if (pickerResult != null) {
                            setDialogState(() {
                              attachmentName = pickerResult!.files.first.name;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          attachmentName.isEmpty
                              ? "Tidak ada lampiran"
                              : attachmentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Buat"),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      if (titleController.text.trim().isEmpty) return;

      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;
        String? finalUrl;

        // Upload attachment file if selected
        if (pickerResult != null) {
          final file = pickerResult!.files.first;
          final fileName =
              "${DateTime.now().millisecondsSinceEpoch}_${file.name}";
          final storagePath = fileName;

          if (kIsWeb) {
            if (file.bytes != null) {
              await client.storage
                  .from('tugas')
                  .uploadBinary(
                    storagePath,
                    file.bytes!,
                    fileOptions: const FileOptions(upsert: true),
                  );
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
            }
          }
          finalUrl = client.storage.from('tugas').getPublicUrl(storagePath);
        }

        final deadlineDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        await client.from('tugas').insert({
          'kelas_id': widget.kelasItem['id'],
          'dosen_id': widget.dosenId,
          'judul': titleController.text.trim(),
          'deskripsi': descController.text.trim(),
          'deadline': deadlineDateTime.toIso8601String(),
          'url_file': finalUrl,
        });

        _snack("Tugas berhasil dibuat", Colors.green);
        _loadAllClassData();
      } catch (e) {
        setState(() => _isLoading = false);
        _snack("Gagal membuat tugas: $e", Colors.red);
      }
    }
  }

  Future<void> _deleteTugas(String id, String? url) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Tugas"),
        content: const Text(
          "Yakin ingin menghapus tugas ini beserta seluruh pengumpulan mahasiswa?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;

        if (url != null && url.contains('/storage/v1/object/public/tugas/')) {
          final uri = Uri.parse(url);
          final pathSegment = uri.pathSegments.last;
          await client.storage.from('tugas').remove([pathSegment]);
        }

        await client.from('tugas').delete().eq('id', id);
        _snack("Tugas berhasil dihapus", Colors.green);
        _loadAllClassData();
      } catch (e) {
        setState(() => _isLoading = false);
        _snack("Gagal menghapus tugas: $e", Colors.red);
      }
    }
  }

  // ===========================================================================
  // 3. GRADING PANEL (INPUT NILAI)
  // ===========================================================================
  Future<void> _editNilai(Map<String, dynamic> gradeRow) async {
    final tController = TextEditingController(
      text: gradeRow['nilai_tugas']?.toString() ?? '',
    );
    final uController = TextEditingController(
      text: gradeRow['nilai_uts']?.toString() ?? '',
    );
    final aController = TextEditingController(
      text: gradeRow['nilai_uas']?.toString() ?? '',
    );
    final mName = gradeRow['mahasiswa']['users']['nama'] ?? '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Input Nilai: $mName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Nilai Tugas (30%)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: uController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Nilai UTS (30%)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Nilai UAS (40%)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );

    if (ok == true) {
      final tScore = double.tryParse(tController.text) ?? 0.0;
      final uScore = double.tryParse(uController.text) ?? 0.0;
      final aScore = double.tryParse(aController.text) ?? 0.0;

      if (tScore < 0 ||
          tScore > 100 ||
          uScore < 0 ||
          uScore > 100 ||
          aScore < 0 ||
          aScore > 100) {
        _snack("Nilai harus berada di rentang 0 - 100", Colors.orange);
        return;
      }

      // Compute Final Score (Nilai Akhir)
      final double finalScore =
          (tScore * 0.3) + (uScore * 0.3) + (aScore * 0.4);

      // Calculate Grade Letter
      String grade = 'E';
      if (finalScore >= 85) {
        grade = 'A';
      } else if (finalScore >= 70) {
        grade = 'B';
      } else if (finalScore >= 55) {
        grade = 'C';
      } else if (finalScore >= 40) {
        grade = 'D';
      }

      setState(() => _isLoading = true);
      try {
        await SupabaseConfig.client
            .from('nilai')
            .update({
              'nilai_tugas': tScore,
              'nilai_uts': uScore,
              'nilai_uas': aScore,
              'nilai_akhir': finalScore,
              'grade': grade,
            })
            .eq('id', gradeRow['id']);

        _snack("Nilai berhasil disimpan", Colors.green);
        _loadAllClassData();
      } catch (e) {
        setState(() => _isLoading = false);
        _snack("Gagal menyimpan nilai: $e", Colors.red);
      }
    }
  }

  // ===========================================================================
  // 4. ANNOUNCEMENTS
  // ===========================================================================
  Future<void> _createAnnouncement() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Buat Pengumuman Kelas"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Judul"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Isi"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Kirim"),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (titleController.text.trim().isEmpty ||
          contentController.text.trim().isEmpty)
        return;
      setState(() => _isLoading = true);
      try {
        await SupabaseConfig.client.from('pengumuman').insert({
          'judul': titleController.text.trim(),
          'isi': contentController.text.trim(),
          'kelas_id': widget.kelasItem['id'],
          'dibuat_oleh': SupabaseConfig.currentUser!.id,
        });
        _snack("Pengumuman diposkan", Colors.green);
        _loadAllClassData();
      } catch (e) {
        setState(() => _isLoading = false);
        _snack("Gagal memposkan pengumuman: $e", Colors.red);
      }
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    try {
      await SupabaseConfig.client.from('pengumuman').delete().eq('id', id);
      _loadAllClassData();
    } catch (e) {
      _snack("Gagal menghapus: $e", Colors.red);
    }
  }

  // ===========================================================================
  // BUILD METHOD & INTERFACE
  // ===========================================================================
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
          isScrollable: true,
          tabs: const [
            Tab(text: "Mahasiswa & KRS"),
            Tab(text: "Materi Kuliah"),
            Tab(text: "Tugas"),
            Tab(text: "Input Nilai"),
            Tab(text: "Pengumuman"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStudentKrsTab(),
                _buildMateriTab(),
                _buildTugasTab(),
                _buildGradesTab(),
                _buildAnnouncementsTab(),
              ],
            ),
    );
  }

  // 1. Student list with KRS status
  Widget _buildStudentKrsTab() {
    if (_studentKrsList.isEmpty) {
      return const Center(child: Text("Belum ada mahasiswa terdaftar"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _studentKrsList.length,
      itemBuilder: (context, index) {
        final item = _studentKrsList[index];
        final m = item['mahasiswa'] ?? {};
        final nama = m['users'] != null ? m['users']['nama'] : '-';
        final nim = m['nim'] ?? '';
        final status = item['status'] ?? 'draft';

        Color badgeColor = Colors.grey;
        if (status == 'disetujui') badgeColor = Colors.green;
        if (status == 'menunggu') badgeColor = Colors.orange;
        if (status == 'ditolak') badgeColor = Colors.red;

        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(
              nama,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("NIM: $nim"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 2. Materials CRUD list
  Widget _buildMateriTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text("UNGGAH MATERI BARU"),
              onPressed: _uploadMateri,
            ),
          ),
        ),
        Expanded(
          child: _materiList.isEmpty
              ? const Center(child: Text("Belum ada materi kuliah diunggah"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _materiList.length,
                  itemBuilder: (context, index) {
                    final item = _materiList[index];
                    IconData icon = Icons.insert_drive_file;
                    if (item['tipe_file'] == 'video')
                      icon = Icons.video_library;
                    if (item['tipe_file'] == 'link') icon = Icons.link;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(icon)),
                        title: Text(
                          item['judul'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Tipe: ${item['tipe_file'].toUpperCase()}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppTheme.accent,
                          ),
                          onPressed: () => _deleteMateri(
                            item['id'].toString(),
                            item['url_file'].toString(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 3. Assignments CRUD list
  Widget _buildTugasTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("BUAT TUGAS BARU"),
              onPressed: _createTugas,
            ),
          ),
        ),
        Expanded(
          child: _tugasList.isEmpty
              ? const Center(child: Text("Belum ada tugas kuliah dibuat"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tugasList.length,
                  itemBuilder: (context, index) {
                    final item = _tugasList[index];
                    final dl = DateTime.parse(item['deadline']).toLocal();
                    final dlStr =
                        "${dl.day}/${dl.month}/${dl.year} ${dl.hour.toString().padLeft(2, '0')}:${dl.minute.toString().padLeft(2, '0')}";

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.task)),
                        title: Text(
                          item['judul'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Deadline: $dlStr"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              child: const Text("NILAI TUGAS"),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubmissionGradingPage(
                                    tugasItem: item,
                                    kelasName: widget.kelasItem['nama'],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppTheme.accent,
                              ),
                              onPressed: () => _deleteTugas(
                                item['id'].toString(),
                                item['url_file']?.toString(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 4. Input Grades tab
  Widget _buildGradesTab() {
    if (_gradesList.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada mahasiswa terdaftar (KRS harus disetujui dahulu)",
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _gradesList.length,
      itemBuilder: (context, index) {
        final item = _gradesList[index];
        final m = item['mahasiswa'] ?? {};
        final nama = m['users'] != null ? m['users']['nama'] : '-';
        final nim = m['nim'] ?? '';

        final t = formatNilai(item['nilai_tugas']);
        final uts = formatNilai(item['nilai_uts']);
        final uas = formatNilai(item['nilai_uas']);
        final akhir = formatNilai(item['nilai_akhir']);
        final grade = item['grade'] ?? '-';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => _editNilai(item),
                      child: const Text(
                        "Input Nilai",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                Text(
                  "NIM: $nim | Grade: $grade",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildScoreVal("Tugas", t),
                    _buildScoreVal("UTS", uts),
                    _buildScoreVal("UAS", uas),
                    _buildScoreVal("Akhir", akhir),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreVal(String label, String score) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
        ),
        const SizedBox(height: 2),
        Text(
          score,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  // 5. Announcements List tab
  Widget _buildAnnouncementsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.announcement),
              label: const Text("BUAT PENGUMUMAN KELAS"),
              onPressed: _createAnnouncement,
            ),
          ),
        ),
        Expanded(
          child: _announcements.isEmpty
              ? const Center(
                  child: Text("Belum ada pengumuman untuk kelas ini"),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final ann = _announcements[index];
                    final date = DateTime.parse(ann['created_at']).toLocal();
                    final dateStr = "${date.day}/${date.month}/${date.year}";

                    return Card(
                      child: ListTile(
                        title: Text(
                          ann['judul'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(ann['isi'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              "Tanggal: $dateStr",
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppTheme.accent,
                          ),
                          onPressed: () =>
                              _deleteAnnouncement(ann['id'].toString()),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
