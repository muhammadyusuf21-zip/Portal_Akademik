import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';
import 'mhs_class_detail_page.dart';

class MahasiswaDashboard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onLogout;
  final Function(int)? onTabSelect;

  const MahasiswaDashboard({
    super.key,
    required this.profile,
    required this.onLogout,
    this.onTabSelect,
  });

  @override
  State<MahasiswaDashboard> createState() => _MahasiswaDashboardState();
}

class _MahasiswaDashboardState extends State<MahasiswaDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _studentDetails;
  Map<String, dynamic>? _activeSemester;
  List<Map<String, dynamic>> _mySchedules = [];
  List<Map<String, dynamic>> _announcements = [];
  double _ipk = 0.0;
  int _totalSks = 0;
  List<Map<String, dynamic>> _pendingAssignments = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;

      // 1. Get Mahasiswa Details
      final stdData = await SupabaseConfig.getStudentDetails();
      if (stdData == null) {
        throw Exception("Profil Mahasiswa tidak ditemukan di database.");
      }
      _studentDetails = stdData;

      // 2. Get Active Semester
      final List<dynamic> semData = await client
          .from('semester')
          .select()
          .eq('status', true)
          .limit(1);

      if (semData.isNotEmpty) {
        _activeSemester = semData.first;
      }

      // 3. Get Student Schedule if semester active exists
      if (_activeSemester != null) {
        final List<dynamic> krsData = await client
            .from('krs')
            .select(
              '*, jadwal(*, kelas(*, mata_kuliah(*), dosen(users(nama))), semester(*))',
            )
            .eq('mahasiswa_id', _studentDetails!['id'])
            .eq('semester_id', _activeSemester!['id'])
            .eq('status', 'disetujui');

        _mySchedules = List<Map<String, dynamic>>.from(krsData);
      }

      // Calculate registered SKS
      int sksSum = 0;
      for (var row in _mySchedules) {
        final sks = row['jadwal']?['kelas']?['mata_kuliah']?['sks'];
        if (sks != null) {
          sksSum += (sks as num).toInt();
        }
      }
      _totalSks = sksSum;

      // 4. Get announcements (general and class specific for approved courses)
      final List<String> enrolledClassIds = _mySchedules
          .map((k) => k['jadwal']['kelas_id'].toString())
          .toList();

      final clientQuery = client
          .from('pengumuman')
          .select('*, users(nama), kelas(*)');

      List<dynamic> annData = [];
      if (enrolledClassIds.isNotEmpty) {
        annData = await clientQuery
            .or('kelas_id.is.null,kelas_id.in.(${enrolledClassIds.join(",")})')
            .order('created_at', ascending: false);
      } else {
        annData = await clientQuery
            .isFilter('kelas_id', null)
            .order('created_at', ascending: false);
      }
      _announcements = List<Map<String, dynamic>>.from(annData);

      // 5. Calculate Cumulative GPA (IPK)
      final List<dynamic> gradesData = await client
          .from('nilai')
          .select('*, kelas(*, mata_kuliah(*))')
          .eq('mahasiswa_id', _studentDetails!['id']);

      double totalPoints = 0;
      int totalSksWithGrades = 0;
      for (var row in gradesData) {
        final sks = row['kelas']?['mata_kuliah']?['sks'];
        final grade = row['grade'];
        if (sks != null && grade != null) {
          final sksInt = (sks as num).toInt();
          double gp = 0.0;
          switch (grade.toString().toUpperCase()) {
            case 'A':
              gp = 4.0;
              break;
            case 'B':
              gp = 3.0;
              break;
            case 'C':
              gp = 2.0;
              break;
            case 'D':
              gp = 1.0;
              break;
            case 'E':
              gp = 0.0;
              break;
          }
          totalPoints += sksInt * gp;
          totalSksWithGrades += sksInt;
        }
      }
      _ipk = totalSksWithGrades > 0 ? totalPoints / totalSksWithGrades : 0.0;

      // 6. Get Pending Assignments (tugas yang harus dikerjakan)
      _pendingAssignments = [];
      if (enrolledClassIds.isNotEmpty) {
        final List<dynamic> allAssignments = await client
            .from('tugas')
            .select('*, kelas(*, mata_kuliah(*))')
            .inFilter('kelas_id', enrolledClassIds)
            .order('deadline', ascending: true);

        final List<dynamic> mySubmissions = await client
            .from('pengumpulan_tugas')
            .select('tugas_id')
            .eq('mahasiswa_id', _studentDetails!['id']);

        final submittedTugasIds = mySubmissions
            .map((s) => s['tugas_id'].toString())
            .toSet();

        _pendingAssignments = List<Map<String, dynamic>>.from(
          allAssignments.where(
            (t) => !submittedTugasIds.contains(t['id'].toString()),
          ),
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppTheme.showSnackBar(
          context,
          "Gagal memuat dashboard: $e",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prodi = _studentDetails?['program_studi']?['nama'] ?? '-';
    final nim = _studentDetails?['nim'] ?? '-';
    final semesterName = _activeSemester?['nama'] ?? 'Belum ada semester aktif';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Academic Header Gradient (tombol refresh & logout dipindah ke bawah)
                    AppTheme.buildHeaderGradient(
                      context: context,
                      title: "Hai, ${widget.profile['nama']}!",
                      subtitle: prodi,
                      metaText: "NIM: $nim",
                      badgeText: "Semester Aktif: $semesterName",
                      icon: Icons.school_outlined,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Grid (IPK & SKS)
                          _buildStatsGrid(),
                          const SizedBox(height: 24),

                          // Pending Assignments
                          _buildPendingAssignments(),
                          const SizedBox(height: 28),

                          // MyAcademic Grid Menu
                          _buildMyAcademicGrid(),
                          const SizedBox(height: 28),

                          // Course List
                          const Text(
                            "Mata Kuliah Semester Ini",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildEnrolledClasses(),
                          const SizedBox(height: 28),

                          // Berita
                          const Text(
                            "Berita",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Seluruh informasi terkait kegiatan di perguruan tinggi akan dimuat di bagian ini.",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
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
            onPressed: _loadDashboardData,
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

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: AppTheme.buildStatCard(
            label: "IP Kumulatif (IPK)",
            value: _ipk.toStringAsFixed(2),
            icon: Icons.stars_outlined,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppTheme.buildStatCard(
            label: "SKS Terdaftar",
            value: "$_totalSks SKS",
            icon: Icons.collections_bookmark_outlined,
            color: AppTheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingAssignments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tugas Yang Harus Dikerjakan",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        if (_pendingAssignments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Semua tugas sudah selesai dikerjakan!",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingAssignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tugas = _pendingAssignments[index];
              final title = tugas['judul'] ?? 'Tugas Tanpa Judul';
              final desc = tugas['deskripsi'] ?? '';
              final deadlineStr = tugas['deadline'] != null
                  ? DateTime.parse(
                      tugas['deadline'],
                    ).toLocal().toString().substring(0, 16)
                  : '-';
              final mkName =
                  tugas['kelas']?['mata_kuliah']?['nama'] ?? 'Mata Kuliah';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                mkName,
                                style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.alarm_on_outlined,
                                  size: 14,
                                  color: AppTheme.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Batas Waktu: $deadlineStr",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () {
                          final sId = tugas['kelas_id'].toString();
                          final sched = _mySchedules.firstWhere(
                            (k) => k['jadwal']['kelas_id'].toString() == sId,
                            orElse: () => {},
                          );

                          if (sched.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MhsClassDetailPage(
                                  kelasItem: sched['jadwal']['kelas'],
                                  mahasiswaId: _studentDetails!['id'],
                                  jadwalItem: sched['jadwal'],
                                ),
                              ),
                            ).then((_) => _loadDashboardData());
                          } else {
                            AppTheme.showSnackBar(
                              context,
                              "Detail kelas untuk tugas ini tidak ditemukan.",
                              backgroundColor: Colors.orange,
                            );
                          }
                        },
                        child: const Text(
                          "KERJAKAN",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEnrolledClasses() {
    if (_mySchedules.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: Colors.grey.shade400,
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Anda belum mengambil KRS atau KRS Anda belum disetujui Admin.",
                  style: TextStyle(color: AppTheme.textLight, fontSize: 12),
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
      itemCount: _mySchedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _mySchedules[index];
        final j = item['jadwal'] ?? {};
        final k = j['kelas'] ?? {};
        final mk = k['mata_kuliah'] ?? {};
        final dName = k['dosen'] != null ? k['dosen']['users']['nama'] : '-';
        final timeStr =
            "${j['jam_mulai'].substring(0, 5)} - ${j['jam_selesai'].substring(0, 5)}";
        final scheduleText = "${j['hari']}, $timeStr";
        final roomText = j['ruangan'] != null
            ? "Ruangan ${j['ruangan']}"
            : null;

        return AppTheme.buildCourseCard(
          code: mk['kode'] ?? '-',
          name: mk['nama'] ?? '-',
          teacher: dName,
          schedule: scheduleText,
          sks: (mk['sks'] as num?)?.toInt() ?? 0,
          room: roomText,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MhsClassDetailPage(
                  kelasItem: k,
                  mahasiswaId: _studentDetails!['id'],
                  jadwalItem: j,
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
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              "Belum ada berita yang dibagikan",
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
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
        final dateStr = "${date.day}/${date.month}/${date.year}";
        final isGeneral = ann['kelas_id'] == null;
        final scopeText = isGeneral
            ? "PENGUMUMAN UMUM"
            : "KELAS ${ann['kelas']['nama']}";

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isGeneral
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        scopeText,
                        style: TextStyle(
                          color: isGeneral ? Colors.blue : Colors.purple,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                Text(
                  "Oleh: ${ann['users']['nama']}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyAcademicGrid() {
    final items = [
      _GridItem(
        label: "KRS",
        icon: Icons.assignment_outlined,
        bgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        onTap: () {
          if (widget.onTabSelect != null) {
            widget.onTabSelect!(1);
          }
        },
      ),
      _GridItem(
        label: "KHS",
        icon: Icons.grade_outlined,
        bgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        onTap: () {
          if (widget.onTabSelect != null) {
            widget.onTabSelect!(2);
          }
        },
      ),
      _GridItem(
        label: "Nilai",
        icon: Icons.fact_check_outlined,
        bgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        onTap: () {
          if (widget.onTabSelect != null) {
            widget.onTabSelect!(2);
          }
        },
      ),
      _GridItem(
        label: "IPK",
        icon: Icons.stars_outlined,
        bgColor: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFEF6C00),
        onTap: () {
          if (widget.onTabSelect != null) {
            widget.onTabSelect!(2);
          }
        },
      ),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "MyAcademic",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Gunakan menu ini untuk melihat informasi dan mengelola data akademik Anda.",
              style: TextStyle(fontSize: 12, color: AppTheme.textLight),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GridItem {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  _GridItem({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });
}
