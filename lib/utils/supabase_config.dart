import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ==========================================
  // TODO: ISI DENGAN CREDENTIALS SUPABASE ANDA
  // ==========================================
  static const String supabaseUrl = "https://xxxx.supabase.co"; 
  static const String supabaseAnonKey = "anon public key"; // Contoh: "eyJhbGciOiJIUzI1Ni..."

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseUrl.startsWith("http") &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey.length > 50;

  static SupabaseClient get client => Supabase.instance.client;

  // Helpers to get current auth details
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // Ambil data user dari tabel public.users
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  // Ambil data mahasiswa (beserta program studi)
  static Future<Map<String, dynamic>?> getStudentDetails() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await client
          .from('mahasiswa')
          .select('*, program_studi(*)')
          .eq('user_id', user.id)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  // Ambil data dosen
  static Future<Map<String, dynamic>?> getDosenDetails() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await client
          .from('dosen')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }
}
