import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';

class SubmissionGradingPage extends StatefulWidget {
  final Map<String, dynamic> tugasItem;
  final String kelasName;

  const SubmissionGradingPage({super.key, required this.tugasItem, required this.kelasName});

  @override
  State<SubmissionGradingPage> createState() => _SubmissionGradingPageState();
}

class _SubmissionGradingPageState extends State<SubmissionGradingPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _submissionsList = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> data = await SupabaseConfig.client
          .from('pengumpulan_tugas')
          .select('*, mahasiswa(*, users(nama))')
          .eq('tugas_id', widget.tugasItem['id']);

      if (mounted) {
        setState(() {
          _submissionsList = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat pengumpulan tugas: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openFile(String url) async {
    try {
      final uri = Uri.parse(url);
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuka file: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _gradeSubmission(Map<String, dynamic> item) async {
    final scoreController = TextEditingController(text: item['nilai']?.toString() ?? '');
    final commentController = TextEditingController(text: item['komentar'] ?? '');
    final studentName = item['mahasiswa']['users']['nama'] ?? '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Beri Nilai: $studentName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Nilai Tugas (0-100)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Komentar/Umpan Balik"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Simpan")),
        ],
      ),
    );

    if (ok == true) {
      final score = double.tryParse(scoreController.text);
      if (score == null || score < 0 || score > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nilai harus angka antara 0-100"), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        await SupabaseConfig.client.from('pengumpulan_tugas').update({
          'nilai': score,
          'komentar': commentController.text.trim(),
        }).eq('id', item['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Penilaian berhasil disimpan"), backgroundColor: Colors.green),
        );
        _loadSubmissions();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan nilai: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.tugasItem['judul'] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text("Penilaian: $title"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _submissionsList.isEmpty
              ? const Center(child: Text("Belum ada mahasiswa yang mengumpulkan tugas ini"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _submissionsList.length,
                  itemBuilder: (context, index) {
                    final item = _submissionsList[index];
                    final m = item['mahasiswa'] ?? {};
                    final nama = m['users'] != null ? m['users']['nama'] : '-';
                    final nim = m['nim'] ?? '';
                    final score = item['nilai']?.toString() ?? 'Belum dinilai';
                    final comment = item['komentar'] ?? 'Tidak ada komentar';
                    
                    final submitTime = DateTime.parse(item['waktu_kumpul']).toLocal();
                    final timeStr = "${submitTime.day}/${submitTime.month}/${submitTime.year} ${submitTime.hour.toString().padLeft(2, '0')}:${submitTime.minute.toString().padLeft(2, '0')}";
                    final fileUrl = item['file_jawaban'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text("NIM: $nim | Kumpul: $timeStr", style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _gradeSubmission(item),
                                  child: const Text("Beri Nilai"),
                                )
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text("Nilai: ", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text(
                                      score,
                                      style: TextStyle(
                                        color: item['nilai'] != null ? Colors.green : AppTheme.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                if (fileUrl.isNotEmpty)
                                  TextButton.icon(
                                    icon: const Icon(Icons.download, size: 16),
                                    label: const Text("Lihat Jawaban", style: TextStyle(fontSize: 12)),
                                    onPressed: () => _openFile(fileUrl),
                                  )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Umpan Balik: $comment",
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textLight),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
