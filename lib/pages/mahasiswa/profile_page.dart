import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> studentDetails;
  final bool isTab;

  const ProfilePage({super.key, required this.studentDetails, this.isTab = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _alamatController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _alamatController = TextEditingController(text: widget.studentDetails['alamat'] ?? '');
  }

  @override
  void dispose() {
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final client = SupabaseConfig.client;
      await client.from('mahasiswa').update({
        'alamat': _alamatController.text.trim(),
      }).eq('id', widget.studentDetails['id']);

      if (mounted) {
        AppTheme.showSnackBar(context, "Profil berhasil disimpan", backgroundColor: Colors.green);
        if (!widget.isTab) {
          Navigator.pop(context, true);
        } else {
          setState(() => _isSaving = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppTheme.showSnackBar(context, "Gagal memperbarui profil: $e", backgroundColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.studentDetails['users'] ?? {};
    final nama = user['nama'] ?? '';
    final email = user['email'] ?? '';
    final nim = widget.studentDetails['nim'] ?? '';
    final prodi = widget.studentDetails['program_studi']?['nama'] ?? '-';
    final angkatan = widget.studentDetails['angkatan']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profil Anda"),
        automaticallyImplyLeading: !widget.isTab,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  Text("Mahasiswa | NIM: $nim", style: const TextStyle(fontSize: 13, color: AppTheme.textLight)),
                  const Divider(height: 32),
                  
                  // Read-Only Fields
                  _buildReadOnlyField("Program Studi", prodi, Icons.school_outlined),
                  const SizedBox(height: 12),
                  _buildReadOnlyField("Angkatan", angkatan, Icons.calendar_today_outlined),
                  const SizedBox(height: 12),
                  _buildReadOnlyField("Email Akun", email, Icons.email_outlined),
                  const SizedBox(height: 20),
                  
                  // Editable Fields Label
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Alamat Lengkap",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Editable Fields Input
                  TextFormField(
                    controller: _alamatController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Tulis alamat rumah lengkap Anda di sini...",
                      prefixIcon: Icon(Icons.home_outlined, color: AppTheme.primary),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? "Alamat wajib diisi" : null,
                  ),
                  const SizedBox(height: 28),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text("SIMPAN PERUBAHAN"),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.textDark, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
