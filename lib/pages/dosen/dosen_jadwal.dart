import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';

class DosenJadwalPage extends StatefulWidget {
  final Map<String, dynamic> dosenDetails;

  const DosenJadwalPage({super.key, required this.dosenDetails});

  @override
  State<DosenJadwalPage> createState() => _DosenJadwalPageState();
}

class _DosenJadwalPageState extends State<DosenJadwalPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      // Get classes with schedules
      final List<dynamic> data = await client
          .from('kelas')
          .select('*, mata_kuliah(*), jadwal(*)')
          .eq('dosen_id', widget.dosenDetails['id']);

      if (mounted) {
        setState(() {
          _schedules = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppTheme.showSnackBar(context, "Gagal memuat jadwal: $e", backgroundColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Jadwal Mengajar"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedules,
              child: _schedules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text("Tidak ada jadwal mengajar aktif.", style: TextStyle(color: AppTheme.textLight)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _schedules.length,
                      itemBuilder: (context, index) {
                        final k = _schedules[index];
                        final mk = k['mata_kuliah'] ?? {};
                        final j = k['jadwal'];

                        String scheduleText = "Belum dijadwalkan";
                        String roomText = "-";
                        if (j != null) {
                          final timeStr = "${j['jam_mulai'].substring(0, 5)} - ${j['jam_selesai'].substring(0, 5)}";
                          scheduleText = "${j['hari']}, $timeStr";
                          roomText = j['ruangan'] ?? "-";
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                        mk['nama'] ?? '-',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "Kelas ${k['nama'] ?? '-'}",
                                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Kode: ${mk['kode'] ?? '-'} | ${mk['sks'] ?? 0} SKS",
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_outlined, size: 16, color: AppTheme.textLight),
                                    const SizedBox(width: 8),
                                    Text(scheduleText, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.room_outlined, size: 16, color: AppTheme.textLight),
                                    const SizedBox(width: 8),
                                    Text("Ruangan: $roomText", style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                                  ],
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
