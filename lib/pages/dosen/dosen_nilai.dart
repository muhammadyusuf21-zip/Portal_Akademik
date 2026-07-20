import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';
import 'class_detail_page.dart';

class DosenNilaiPage extends StatefulWidget {
  final Map<String, dynamic> dosenDetails;

  const DosenNilaiPage({super.key, required this.dosenDetails});

  @override
  State<DosenNilaiPage> createState() => _DosenNilaiPageState();
}

class _DosenNilaiPageState extends State<DosenNilaiPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      // Get classes taught by this lecturer
      final List<dynamic> data = await client
          .from('kelas')
          .select('*, mata_kuliah(*), jadwal(*)')
          .eq('dosen_id', widget.dosenDetails['id']);

      if (mounted) {
        setState(() {
          _classes = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppTheme.showSnackBar(context, "Gagal memuat daftar kelas: $e", backgroundColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Input Nilai Mahasiswa"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClasses,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadClasses,
              child: _classes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.grade_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text("Tidak ada kelas mengajar aktif.", style: TextStyle(color: AppTheme.textLight)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _classes.length,
                      itemBuilder: (context, index) {
                        final k = _classes[index];
                        final mk = k['mata_kuliah'] ?? {};
                        final j = k['jadwal'];

                        String scheduleText = "Belum dijadwalkan";
                        if (j != null) {
                          final timeStr = "${j['jam_mulai'].substring(0, 5)} - ${j['jam_selesai'].substring(0, 5)}";
                          scheduleText = "${j['hari']}, $timeStr";
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mk['nama'] ?? '-',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Kode: ${mk['kode'] ?? '-'} | SKS: ${mk['sks'] ?? 0} | Kelas: ${k['nama'] ?? '-'}",
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        scheduleText,
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ClassDetailPage(
                                          kelasItem: k,
                                          dosenId: widget.dosenDetails['id'],
                                          initialTabIndex: 3, // Tab index for "Input Nilai"
                                        ),
                                      ),
                                    ).then((_) => _loadClasses());
                                  },
                                  icon: const Icon(Icons.edit_note, size: 16),
                                  label: const Text("Nilai", style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
