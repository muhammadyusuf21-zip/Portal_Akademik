import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/supabase_config.dart';
import 'utils/theme.dart';
import 'pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint("Gagal menginisialisasi Supabase: $e");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academic',
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}
