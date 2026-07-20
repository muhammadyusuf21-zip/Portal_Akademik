import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';
import 'manage_users_page.dart';
import 'akademik_page.dart';
import 'krs_manage_page.dart';
import 'admin_all_grades_page.dart';
import 'admin_all_assignments_page.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onLogout;

  const AdminDashboard({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  int _totalMhs = 0;
  int _totalDosen = 0;
  int _totalMatkul = 0;
  int _pendingKrs = 0;
  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;

      final futures = await Future.wait([
        client.from('mahasiswa').select('id'),
        client.from('dosen').select('id'),
        client.from('mata_kuliah').select('id'),
        client.from('krs').select('id').eq('status', 'menunggu'),
        client
            .from('pengumuman')
            .select('*, users(nama)')
            .isFilter('kelas_id', null)
            .order('created_at', ascending: false),
      ]);

      if (mounted) {
        setState(() {
          _totalMhs = (futures[0] as List).length;
          _totalDosen = (futures[1] as List).length;
          _totalMatkul = (futures[2] as List).length;
          _pendingKrs = (futures[3] as List).length;
          _announcements = List<Map<String, dynamic>>.from(futures[4] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppTheme.showSnackBar(
          context,
          "Error memuat data dashboard: $e",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _createAnnouncement() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Buat Pengumuman Umum"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Judul Pengumuman"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Isi Pengumuman"),
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

    if (result == true) {
      if (titleController.text.trim().isEmpty ||
          contentController.text.trim().isEmpty) {
        AppTheme.showSnackBar(
          context,
          "Judul dan isi tidak boleh kosong",
          backgroundColor: Colors.orange,
        );
        return;
      }

      try {
        await SupabaseConfig.client.from('pengumuman').insert({
          'judul': titleController.text.trim(),
          'isi': contentController.text.trim(),
          'dibuat_oleh': SupabaseConfig.currentUser!.id,
          'kelas_id': null, // Pengumuman umum
        });
        _loadData();
        AppTheme.showSnackBar(
          context,
          "Pengumuman berhasil diterbitkan",
          backgroundColor: Colors.green,
        );
      } catch (e) {
        AppTheme.showSnackBar(
          context,
          "Gagal mengirim pengumuman: $e",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Pengumuman"),
        content: const Text("Yakin ingin menghapus pengumuman ini?"),
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
      try {
        await SupabaseConfig.client.from('pengumuman').delete().eq('id', id);
        _loadData();
        AppTheme.showSnackBar(
          context,
          "Pengumuman berhasil dihapus",
          backgroundColor: Colors.green,
        );
      } catch (e) {
        AppTheme.showSnackBar(
          context,
          "Gagal menghapus: $e",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Academic Header Gradient (tombol refresh & logout dipindah ke bawah)
                    AppTheme.buildHeaderGradient(
                      context: context,
                      title: "Selamat Datang, ${widget.profile['nama']}!",
                      subtitle: "Administrator Akademik",
                      metaText: "",
                      badgeText: "Portal Administrator",
                      icon: Icons.admin_panel_settings_outlined,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Grid
                          const Text(
                            "Statistik Akademik",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStatsGrid(),
                          const SizedBox(height: 28),

                          // Actions Menu
                          const Text(
                            "Menu Pengelolaan",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildActionsMenu(),
                          const SizedBox(height: 28),

                          // Announcements Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Pengumuman Akademik",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _createAnnouncement,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text("Buat"),
                              ),
                            ],
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
            onPressed: _loadData,
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
    final isWide = MediaQuery.of(context).size.width >= 600;
    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        AppTheme.buildStatCard(
          label: "Mahasiswa",
          value: _totalMhs.toString(),
          icon: Icons.people_outline,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageUsersPage()),
          ),
        ),
        AppTheme.buildStatCard(
          label: "Dosen",
          value: _totalDosen.toString(),
          icon: Icons.supervisor_account_outlined,
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageUsersPage()),
          ),
        ),
        AppTheme.buildStatCard(
          label: "Mata Kuliah",
          value: _totalMatkul.toString(),
          icon: Icons.menu_book_outlined,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageAkademikPage()),
          ),
        ),
        AppTheme.buildStatCard(
          label: "Menunggu KRS",
          value: _pendingKrs.toString(),
          icon: Icons.pending_actions_outlined,
          color: _pendingKrs > 0 ? AppTheme.accent : Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KrsApprovalPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsMenu() {
    return Column(
      children: [
        AppTheme.buildMenuListItem(
          icon: Icons.person_add_outlined,
          title: "Kelola Pengguna",
          subtitle: "Tambah, Edit, dan Hapus akun Dosen & Mahasiswa",
          color: Colors.blue.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageUsersPage()),
          ),
        ),
        const SizedBox(height: 12),
        AppTheme.buildMenuListItem(
          icon: Icons.folder_open_outlined,
          title: "Kelola Data Akademik",
          subtitle: "Program Studi, Semester, Mata Kuliah, Kelas, & Jadwal",
          color: Colors.purple.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageAkademikPage()),
          ),
        ),
        const SizedBox(height: 12),
        AppTheme.buildMenuListItem(
          icon: Icons.assignment_turned_in_outlined,
          title: "Persetujuan KRS Mahasiswa",
          subtitle: "Periksa, setujui, atau tolak KRS mahasiswa",
          color: Colors.amber.shade700,
          badge: _pendingKrs > 0 ? _pendingKrs.toString() : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KrsApprovalPage()),
          ),
        ),
        const SizedBox(height: 12),
        AppTheme.buildMenuListItem(
          icon: Icons.grade_outlined,
          title: "Laporan Nilai Mahasiswa",
          subtitle: "Lihat transkrip nilai akhir seluruh mahasiswa",
          color: Colors.green.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAllGradesPage()),
          ),
        ),
        const SizedBox(height: 12),
        AppTheme.buildMenuListItem(
          icon: Icons.task_outlined,
          title: "Monitoring Tugas Kuliah",
          subtitle: "Pantau seluruh penugasan yang diberikan dosen",
          color: Colors.red.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAllAssignmentsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsList() {
    if (_announcements.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.announcement_outlined,
                  color: Colors.grey.shade400,
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Belum ada pengumuman umum",
                  style: TextStyle(color: AppTheme.textLight, fontSize: 13),
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
      itemCount: _announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ann = _announcements[index];
        final author = ann['users'] != null ? ann['users']['nama'] : 'Admin';
        final date = DateTime.parse(ann['created_at']).toLocal();
        final dateString =
            "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

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
                    Expanded(
                      child: Text(
                        ann['judul'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                      onPressed: () =>
                          _deleteAnnouncement(ann['id'].toString()),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  ann['isi'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Oleh: $author",
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
