import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';
import 'class_detail_page.dart';

class DosenDashboard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onLogout;

  const DosenDashboard({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  @override
  State<DosenDashboard> createState() => _DosenDashboardState();
}

class _DosenDashboardState extends State<DosenDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _dosenDetails;
  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadDosenData();
  }

  Future<void> _loadDosenData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;

      // Get Dosen Profile Row
      final details = await SupabaseConfig.getDosenDetails();
      if (details == null) {
        throw Exception("Profil Dosen tidak ditemukan di database.");
      }
      _dosenDetails = details;

      // Get Classes taught by this Dosen
      final List<dynamic> classesData = await client
          .from('kelas')
          .select('*, mata_kuliah(*), jadwal(*)')
          .eq('dosen_id', _dosenDetails!['id']);

      _kelasList = List<Map<String, dynamic>>.from(classesData);

      // Get General Announcements
      final List<dynamic> annData = await client
          .from('pengumuman')
          .select('*, users(nama)')
          .isFilter('kelas_id', null)
          .order('created_at', ascending: false);

      _announcements = List<Map<String, dynamic>>.from(annData);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppTheme.showSnackBar(
          context,
          "Gagal memuat dashboard dosen: $e",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nidn = _dosenDetails?['nidn'] ?? '-';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDosenData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Academic Header Gradient (tombol refresh & logout dipindah ke bawah)
                    AppTheme.buildHeaderGradient(
                      context: context,
                      title: "Selamat Datang, ${widget.profile['nama']}!",
                      subtitle: "Dosen Pengampu",
                      metaText: "NIDN: $nidn",
                      badgeText: "Dashboard Dosen",
                      icon: Icons.co_present_outlined,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Mata Kuliah Yang Diampu",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildClassesList(),
                          const SizedBox(height: 28),

                          const Text(
                            "Pengumuman Akademik Umum",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAnnouncementsList(),
                          const SizedBox(height: 28),

                          // Tombol Refresh & Logout di posisi bawah
                          _buildBottomActions(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loadDosenData,
            icon: const Icon(Icons.refresh),
            label: const Text("Muat Ulang"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textDark,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassesList() {
    if (_kelasList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.class_outlined,
                  color: Colors.grey.shade400,
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Anda belum ditugaskan mengajar di kelas manapun.",
                  style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _kelasList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final k = _kelasList[index];
        final mk = k['mata_kuliah'] ?? {};
        final j = k['jadwal'];

        String scheduleText = "Belum dijadwalkan";
        String? roomText;
        if (j != null) {
          final timeStr =
              "${j['jam_mulai'].substring(0, 5)} - ${j['jam_selesai'].substring(0, 5)}";
          scheduleText = "${j['hari']}, $timeStr";
          roomText = j['ruangan'] != null ? "Ruangan ${j['ruangan']}" : null;
        }

        return AppTheme.buildCourseCard(
          code: mk['kode'] ?? '-',
          name: mk['nama'] ?? '-',
          teacher: "Kelas: ${k['nama']} (Kuota: ${k['kuota']} Mahasiswa)",
          schedule: scheduleText,
          sks: (mk['sks'] as num?)?.toInt() ?? 0,
          room: roomText,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClassDetailPage(
                  kelasItem: k,
                  dosenId: _dosenDetails!['id'],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementsList() {
    if (_announcements.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              "Tidak ada pengumuman akademik umum",
              style: TextStyle(color: AppTheme.textLight, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ann = _announcements[index];
        final date = DateTime.parse(ann['created_at']).toLocal();
        final dateString = "${date.day}/${date.month}/${date.year}";
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ann['judul'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ann['isi'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Oleh: ${ann['users']['nama']}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateString,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
