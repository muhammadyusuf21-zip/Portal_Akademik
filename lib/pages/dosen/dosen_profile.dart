import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';

class DosenProfilePage extends StatefulWidget {
  final Map<String, dynamic> dosenDetails;
  final bool isTab;

  const DosenProfilePage({super.key, required this.dosenDetails, this.isTab = false});

  @override
  State<DosenProfilePage> createState() => _DosenProfilePageState();
}

class _DosenProfilePageState extends State<DosenProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _alamatController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _alamatController = TextEditingController(text: widget.dosenDetails['alamat'] ?? '');
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
      await client.from('dosen').update({
        'alamat': _alamatController.text.trim(),
      }).eq('id', widget.dosenDetails['id']);

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
    final currentUser = SupabaseConfig.currentUser;
    final email = currentUser?.email ?? '';
    final nama = widget.dosenDetails['users']?['nama'] ?? widget.dosenDetails['nama'] ?? currentUser?.userMetadata?['nama'] ?? 'Dosen';
    final nidn = widget.dosenDetails['nidn'] ?? '-';

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
                  Text(
                    nama,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    textAlign: TextAlign.center,
                  ),
                  Text("Dosen Pengampu | NIDN: $nidn", style: const TextStyle(fontSize: 13, color: AppTheme.textLight)),
                  const Divider(height: 32),

                  // Read-Only Fields
                  _buildReadOnlyField("NIDN", nidn, Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _buildReadOnlyField("Email Akun", email, Icons.email_outlined),
                  const SizedBox(height: 20),

                  // Editable Fields Label
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Data Yang Dapat Diubah",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Alamat Input
                  TextFormField(
                    controller: _alamatController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Alamat Tinggal",
                      hintText: "Masukkan alamat lengkap Anda",
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.location_on_outlined),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Alamat tidak boleh kosong";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SIMPAN PERUBAHAN", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.textDark, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
