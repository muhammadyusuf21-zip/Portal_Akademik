import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ==========================================
  // TODO: ISI DENGAN CREDENTIALS SUPABASE ANDA
  // ==========================================
  static const String supabaseUrl = "https://vtwtgxcxryruruvopsnm.supabase.co"; // Contoh: "https://xxxx.supabase.co"
  static const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ0d3RneGN4cnlydXJ1dm9wc25tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5OTA4NjksImV4cCI6MjA5OTU2Njg2OX0.JTrqmNlF30__l-MlwnzbEwY5MB0Sy2Zrc3DUyWhB_TM"; // Contoh: "eyJhbGciOiJIUzI1Ni..."

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
