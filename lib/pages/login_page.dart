import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_config.dart';
import '../utils/theme.dart';
import 'register_page.dart';
import 'dashboard_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        final profile = await SupabaseConfig.getCurrentUserProfile();
        if (profile != null) {
          final String role = profile['role'] ?? 'mahasiswa';
          _snack("Login berhasil sebagai ${role.toUpperCase()}", Colors.green);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardShell(role: role, profile: profile),
            ),
          );
        } else {
          await SupabaseConfig.client.auth.signOut();
          _snack("Akun Anda belum tersinkronisasi di database.", Colors.orange);
        }
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.toLowerCase().contains("invalid login credentials") ||
          msg.toLowerCase().contains("invalid credentials") ||
          msg.toLowerCase().contains("password")) {
        msg = "Kata sandi Anda salah";
      }
      _snack(msg, Colors.red);
    } catch (e) {
      _snack("Terjadi kesalahan: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    AppTheme.showSnackBar(context, msg, backgroundColor: color);
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return AppTheme.buildSetupScreen(context);
    }

    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: isWide ? _buildWideLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildWideLayout() {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height,
      color: AppTheme.bgLight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppTheme.borderLight, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Row(
                children: [
                  // Panel KIRI: Form (dibalik dari sebelumnya)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: _buildFormFields(isWide: true),
                        ),
                      ),
                    ),
                  ),
                  // Panel KANAN: Branding dengan dekorasi (dibalik)
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Background gradient
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                            ),
                          ),
                        ),
                        // Lingkaran dekorasi
                        Positioned(
                          top: -60,
                          left: -60,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -40,
                          right: -40,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 80,
                          left: 40,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Konten branding
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.school,
                                  size: 44,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 28),
                              const Text(
                                "Sistem Informasi\nAkademik",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: 40,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppTheme.accent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Kelola jadwal, KRS, materi kuliah, tugas, dan nilai dalam satu platform akademik terintegrasi.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.82),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Stack(
        children: [
          // Lingkaran dekorasi kiri bawah
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Konten utama center
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Logo + judul di atas
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "PORTAL AKADEMIK",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Academic Management Platform",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Card form (centered, bukan floating offset)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Form(
                      key: _formKey,
                      child: _buildFormFields(isWide: false),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields({required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Masuk Akun",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Gunakan email dan password terdaftar Anda",
          style: TextStyle(color: AppTheme.textLight, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Email Label
        const Text(
          "Email",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        // Email Input
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: "name@universitas.ac.id",
            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return "Email wajib diisi";
            if (!RegExp(
              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
            ).hasMatch(val.trim())) {
              return "Format email tidak valid";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Password Label
        const Text(
          "Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        // Password Input
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            hintText: "********",
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.textLight,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return "Password wajib diisi";
            if (val.length < 6) return "Password minimal 6 karakter";
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Login Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text("MASUK"),
          ),
        ),
        const SizedBox(height: 16),

        // Registration Links
        Center(
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            ),
            child: const Text("Belum punya akun? Daftar di sini"),
          ),
        ),
      ],
    );
  }
}
