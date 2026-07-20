import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_config.dart';
import '../utils/theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingProdi = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Form Fields - Step 1: Akun & Role
  String _selectedRole = 'mahasiswa'; // 'mahasiswa' or 'dosen'
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();

  // Form Fields - Step 2: Detil Profil
  final TextEditingController _nimController = TextEditingController(); // Mahasiswa only
  final TextEditingController _nidnController = TextEditingController(); // Dosen only
  final TextEditingController _alamatController = TextEditingController();
  
  String? _selectedProdiId; // Mahasiswa only
  int _selectedAngkatan = DateTime.now().year; // Mahasiswa only

  List<Map<String, dynamic>> _prodiList = [];

  @override
  void initState() {
    super.initState();
    _fetchProgramStudi();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _namaController.dispose();
    _nimController.dispose();
    _nidnController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _fetchProgramStudi() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final List<dynamic> data = await SupabaseConfig.client
          .from('program_studi')
          .select('id, nama, kode')
          .order('nama');
      
      if (mounted) {
        setState(() {
          _prodiList = List<Map<String, dynamic>>.from(data);
          if (_prodiList.isNotEmpty) {
            _selectedProdiId = _prodiList.first['id'];
          }
          _isLoadingProdi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProdi = false);
        _snack("Gagal memuat program studi: $e", Colors.orange);
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.isEmpty ||
          _namaController.text.trim().isEmpty) {
        _snack("Semua field wajib diisi", Colors.orange);
        return;
      }
      if (_passwordController.text.length < 6) {
        _snack("Password minimal 6 karakter", Colors.orange);
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _snack("Password dan konfirmasi tidak sama", Colors.orange);
        return;
      }
      setState(() => _currentStep = 1);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRole == 'mahasiswa') {
      if (_nimController.text.trim().isEmpty) {
        _snack("NIM wajib diisi", Colors.orange);
        return;
      }
      if (_selectedProdiId == null) {
        _snack("Silakan pilih program studi", Colors.orange);
        return;
      }
    } else {
      if (_nidnController.text.trim().isEmpty) {
        _snack("NIDN wajib diisi", Colors.orange);
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> metadata = {
        'role': _selectedRole,
        'nama': _namaController.text.trim(),
        'alamat': _alamatController.text.trim(),
      };

      if (_selectedRole == 'mahasiswa') {
        metadata['nim'] = _nimController.text.trim();
        metadata['program_studi_id'] = _selectedProdiId;
        metadata['angkatan'] = _selectedAngkatan;
      } else {
        metadata['nidn'] = _nidnController.text.trim();
      }

      final response = await SupabaseConfig.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: metadata,
      );

      if (response.user != null) {
        _snack("Registrasi berhasil! Silakan login", Colors.green);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      }
    } on AuthException catch (e) {
      final errStr = e.message.toLowerCase();
      if (errStr.contains("mahasiswa_nim_key") || errStr.contains("nim") && errStr.contains("already exists")) {
        _snack("Registrasi gagal: NIM sudah terdaftar", Colors.red);
      } else if (errStr.contains("dosen_nidn_key") || errStr.contains("nidn") && errStr.contains("already exists")) {
        _snack("Registrasi gagal: NIDN sudah terdaftar", Colors.red);
      } else if (errStr.contains("database error saving new user")) {
        _snack("Registrasi gagal: NIM/NIDN atau Email sudah terdaftar", Colors.red);
      } else {
        _snack(e.message, Colors.red);
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains("mahasiswa_nim_key") || errStr.contains("nim") && errStr.contains("already exists")) {
        _snack("Registrasi gagal: NIM sudah terdaftar", Colors.red);
      } else if (errStr.contains("dosen_nidn_key") || errStr.contains("nidn") && errStr.contains("already exists")) {
        _snack("Registrasi gagal: NIDN sudah terdaftar", Colors.red);
      } else if (errStr.contains("database error saving new user") || errStr.contains("duplicate key value")) {
        _snack("Registrasi gagal: NIM/NIDN atau Email sudah terdaftar", Colors.red);
      } else {
        _snack("Gagal registrasi: $e", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    AppTheme.showSnackBar(context, msg, backgroundColor: color);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 800;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Gradient
            Container(
              width: double.infinity,
              height: size.height * (isWide ? 0.3 : 0.35),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person_add_outlined, size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Pendaftaran Akun",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStepIndicator(),
                  ],
                ),
              ),
            ),
            // Floating Card Form
            Transform.translate(
              offset: const Offset(0, -32),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? (size.width - 500) / 2 : 24),
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.04),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, "Akun"),
        _buildStepLine(_currentStep >= 1),
        _buildStepDot(1, "Profil"),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
            border: Border.all(
              color: isActive ? Colors.white : Colors.white30,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            "${step + 1}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isActive ? AppTheme.primary : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        )
      ],
    );
  }

  Widget _buildStepLine(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 48,
      height: 2,
      color: active ? Colors.white : Colors.white.withOpacity(0.2),
      margin: const EdgeInsets.only(left: 6, right: 6, bottom: 14),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Informasi Akun",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const Divider(height: 20),
        
        const Text(
          "Daftar Sebagai:",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textLight),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleButton('mahasiswa', Icons.school_outlined, "Mahasiswa"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleButton('dosen', Icons.supervisor_account_outlined, "Dosen"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        const Text(
          "Nama Lengkap",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _namaController,
          decoration: const InputDecoration(
            hintText: "Nama Lengkap Anda",
            prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
          ),
          validator: (val) => val == null || val.trim().isEmpty ? "Nama wajib diisi" : null,
        ),
        const SizedBox(height: 16),

        const Text(
          "Email",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: "name@universitas.ac.id",
            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return "Email wajib diisi";
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
              return "Format email tidak valid";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        const Text(
          "Password",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            hintText: "Minimal 6 karakter",
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        const Text(
          "Konfirmasi Password",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          decoration: InputDecoration(
            hintText: "Ulangi password",
            prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppTheme.primary),
            suffixIcon: IconButton(
              icon: Icon(_showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _nextStep,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("LANJUTKAN"),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_outlined, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Sudah punya akun? Masuk"),
          ),
        )
      ],
    );
  }

  Widget _buildRoleButton(String role, IconData icon, String title) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textLight, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primary : AppTheme.textLight,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final isMhs = _selectedRole == 'mahasiswa';
    final currentYear = DateTime.now().year;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
              onPressed: () => setState(() => _currentStep = 0),
            ),
            const SizedBox(width: 4),
            const Text(
              "Profil Tambahan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ],
        ),
        const Divider(height: 20),
        
        if (isMhs) ...[
          const Text(
            "NIM (Nomor Induk Mahasiswa)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nimController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Contoh: 231500001",
              prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primary),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? "NIM wajib diisi" : null,
          ),
          const SizedBox(height: 16),
          
          const Text(
            "Program Studi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          _isLoadingProdi
              ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
              : DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedProdiId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.school_outlined, color: AppTheme.primary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _prodiList.map((prodi) {
                    return DropdownMenuItem<String>(
                      value: prodi['id'],
                      child: Text(
                        "${prodi['kode']} - ${prodi['nama']}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedProdiId = val);
                  },
                  validator: (val) => val == null ? "Pilih program studi" : null,
                ),
          const SizedBox(height: 16),
          
          const Text(
            "Angkatan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: _selectedAngkatan,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.primary),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: List.generate(10, (index) => currentYear - index).map((year) {
              return DropdownMenuItem<int>(
                value: year,
                child: Text("Tahun $year"),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedAngkatan = val);
            },
          ),
        ] else ...[
          const Text(
            "NIDN (Nomor Induk Dosen Nasional)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nidnController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Contoh: 0011028801",
              prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primary),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? "NIDN wajib diisi" : null,
          ),
        ],
        const SizedBox(height: 16),
        
        const Text(
          "Alamat Lengkap",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _alamatController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: "Tulis alamat lengkap rumah Anda",
            prefixIcon: Icon(Icons.home_outlined, color: AppTheme.primary),
          ),
          validator: (val) => val == null || val.trim().isEmpty ? "Alamat wajib diisi" : null,
        ),
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text("DAFTAR SEKARANG"),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}