import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/supabase_config.dart';
import 'login_page.dart';
import 'admin/admin_dashboard.dart';
import 'dosen/dosen_dashboard.dart';
import 'dosen/dosen_jadwal.dart';
import 'dosen/dosen_nilai.dart';
import 'dosen/dosen_profile.dart';
import 'mahasiswa/mahasiswa_dashboard.dart';
import 'mahasiswa/krs_page.dart';
import 'mahasiswa/khs_page.dart';
import 'mahasiswa/profile_page.dart';

class DashboardShell extends StatefulWidget {
  final String role;
  final Map<String, dynamic> profile;

  const DashboardShell({super.key, required this.role, required this.profile});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;
  bool _isMhsLoading = false;
  Map<String, dynamic>? _studentDetails;
  Map<String, dynamic>? _activeSemester;

  bool _isDosenLoading = false;
  Map<String, dynamic>? _dosenDetails;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'mahasiswa') {
      _loadMahasiswaData();
    } else if (widget.role == 'dosen') {
      _loadDosenData();
    }
  }

  Future<void> _loadDosenData() async {
    setState(() => _isDosenLoading = true);
    try {
      final user = SupabaseConfig.currentUser;
      if (user != null) {
        final dsn = await SupabaseConfig.client
            .from('dosen')
            .select('*, users(nama, email)')
            .eq('user_id', user.id)
            .maybeSingle();

        setState(() {
          _dosenDetails = dsn;
          _isDosenLoading = false;
        });
      } else {
        setState(() => _isDosenLoading = false);
      }
    } catch (_) {
      setState(() => _isDosenLoading = false);
    }
  }

  Future<void> _loadMahasiswaData() async {
    setState(() => _isMhsLoading = true);
    try {
      final std = await SupabaseConfig.getStudentDetails();
      final List<dynamic> sem = await SupabaseConfig.client
          .from('semester')
          .select()
          .eq('status', true)
          .limit(1);

      setState(() {
        _studentDetails = std;
        if (sem.isNotEmpty) {
          _activeSemester = sem.first;
        }
        _isMhsLoading = false;
      });
    } catch (_) {
      setState(() => _isMhsLoading = false);
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.accent),
            SizedBox(width: 8),
            Text("Logout"),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari cistem akademik ini?",
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
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseConfig.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget _buildMahasiswaShell() {
    if (_isMhsLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> pages = [
      MahasiswaDashboard(
        profile: widget.profile,
        onLogout: _logout,
        onTabSelect: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      if (_studentDetails != null && _activeSemester != null)
        KrsPage(
          studentDetails: _studentDetails!,
          activeSemester: _activeSemester!,
          isTab: true,
        )
      else
        const Scaffold(
          body: Center(
            child: Text(
              "Data KRS tidak tersedia (Tidak ada semester akademik aktif).",
            ),
          ),
        ),
      if (_studentDetails != null)
        KhsPage(
          studentDetails: _studentDetails!,
          activeSemester: _activeSemester,
          isTab: true,
        )
      else
        const Scaffold(body: Center(child: Text("Data KHS tidak tersedia."))),
      if (_studentDetails != null)
        ProfilePage(studentDetails: _studentDetails!, isTab: true)
      else
        const Scaffold(
          body: Center(child: Text("Data profil tidak tersedia.")),
        ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      // Floating pill nav bar (baru)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              elevation: 0,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white54,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 10,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_outlined),
                  label: "Beranda",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.edit_document),
                  activeIcon: Icon(Icons.edit_document),
                  label: "KRS",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.grade_outlined),
                  activeIcon: Icon(Icons.grade_outlined),
                  label: "KHS",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person_outline),
                  label: "Profil",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDosenShell() {
    if (_isDosenLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> pages = [
      DosenDashboard(profile: widget.profile, onLogout: _logout),
      if (_dosenDetails != null)
        DosenJadwalPage(dosenDetails: _dosenDetails!)
      else
        const Scaffold(
          body: Center(child: Text("Data Jadwal Mengajar tidak tersedia.")),
        ),
      if (_dosenDetails != null)
        DosenNilaiPage(dosenDetails: _dosenDetails!)
      else
        const Scaffold(
          body: Center(child: Text("Data Input Nilai tidak tersedia.")),
        ),
      if (_dosenDetails != null)
        DosenProfilePage(dosenDetails: _dosenDetails!, isTab: true)
      else
        const Scaffold(
          body: Center(child: Text("Data profil tidak tersedia.")),
        ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      // Floating pill nav bar (baru)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              elevation: 0,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white54,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 10,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_outlined),
                  label: "Beranda",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today_outlined),
                  label: "Jadwal",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.grade_outlined),
                  activeIcon: Icon(Icons.grade_outlined),
                  label: "Beri Nilai",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person_outline),
                  label: "Profil",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.role) {
      case 'admin':
        return AdminDashboard(profile: widget.profile, onLogout: _logout);
      case 'dosen':
        return _buildDosenShell();
      case 'mahasiswa':
        return _buildMahasiswaShell();
      default:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                const SizedBox(height: 12),
                Text(
                  "Role '${widget.role}' tidak dikenali.",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _logout,
                  child: const Text("Kembali ke Login"),
                ),
              ],
            ),
          ),
        );
    }
  }
}
