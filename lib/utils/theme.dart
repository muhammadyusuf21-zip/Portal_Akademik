import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === WARNA (tidak berubah) ===
  static const Color primary = Color(0xFF1B4332);
  static const Color primaryDark = Color(0xFF081C15);
  static const Color secondary = Color(0xFF2D6A4F);
  static const Color accent = Color(0xFFD97706);

  static const Color bgLight = Color(0xFFF4F7F5);
  static const Color cardLight = Color(0xB2EBF5F0);
  static const Color textDark = Color(0xFF111827);
  static const Color textLight = Color(0xFF526058);
  static const Color borderLight = Color(0xFFD8E2DC);

  // === GRADIENTS (tidak berubah) ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF2D6A4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, Color(0xFF081C15)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF40916C), Color(0xFF1B4332)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === THEME DATA ===
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        error: const Color(0xFFEF4444),
        surface: bgLight,
      ),
      scaffoldBackgroundColor: bgLight,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        labelStyle: const TextStyle(color: textLight, fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // === GRADIENT BUTTON (pill shape — baru) ===
  static Widget buildGradientButton({
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: buttonGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF40916C).withOpacity(0.40),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === 1. HEADER GRADIENT (baru: flat + dekorasi lingkaran + ikon kotak kiri) ===
  static Widget buildHeaderGradient({
    required BuildContext context,
    required String title,
    required String subtitle,
    String? metaText,
    String? badgeText,
    IconData icon = Icons.school_outlined,
    List<Widget>? actions,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: primaryGradient),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Lingkaran dekorasi kanan atas
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 60,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Konten utama
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (actions != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  Row(
                    children: [
                      // Ikon kotak rounded (baru, ganti circle avatar)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (metaText != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                metaText,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            if (badgeText != null) ...[
                              const SizedBox(height: 10),
                              // Badge amber (bukan pill putih)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badgeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === 2. STAT CARD (baru: horizontal dua-warna, ikon kiri + teks kanan) ===
  static Widget buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderLight, width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // Panel ikon berwarna
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  color: color.withOpacity(0.1),
                  child: Center(child: Icon(icon, color: color, size: 26)),
                ),
                // Panel teks
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: textLight,
                            height: 1.3,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === 3. MENU LIST ITEM (baru: card putih shadow, chevron bukan arrow_forward_ios) ===
  static Widget buildMenuListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderLight, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: textLight),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: textLight,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // === 4. COURSE CARD (baru: top accent bar 4px, tanpa left strip) ===
  static Widget buildCourseCard({
    required String code,
    required String name,
    required String teacher,
    required String schedule,
    required int sks,
    String? room,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top accent gradient bar (baru, ganti left strip)
                Container(
                  height: 4,
                  decoration: const BoxDecoration(gradient: buttonGradient),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                color: secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$sks SKS",
                              style: const TextStyle(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: textLight,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              teacher,
                              style: const TextStyle(
                                fontSize: 12,
                                color: textLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (room != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                room,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: textLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            size: 14,
                            color: primary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            schedule,
                            style: TextStyle(
                              fontSize: 11,
                              color: primary.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === 5. GRADE CARD (badge kotak rounded, bukan circle) ===
  static Widget buildGradeCard({
    required String studentName,
    required String nim,
    required String courseName,
    required String grade,
    required String scoreBreakdown,
    required double finalScore,
  }) {
    Color gradeColor;
    switch (grade.toUpperCase()) {
      case 'A':
        gradeColor = const Color(0xFF15803D);
        break;
      case 'B':
        gradeColor = const Color(0xFF0F766E);
        break;
      case 'C':
        gradeColor = const Color(0xFFB45309);
        break;
      default:
        gradeColor = const Color(0xFFB91C1C);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: gradeColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Badge kotak rounded (bukan circle)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: gradeColor.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  grade,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: gradeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textDark,
                    ),
                  ),
                  Text(
                    "NIM: $nim | $courseName",
                    style: const TextStyle(fontSize: 11, color: textLight),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scoreBreakdown,
                    style: const TextStyle(fontSize: 10, color: textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  "Nilai Akhir",
                  style: TextStyle(fontSize: 9, color: textLight),
                ),
                const SizedBox(height: 2),
                Text(
                  finalScore.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === 6. SEARCH BAR (baru: white card dengan shadow, ikon primary) ===
  static Widget buildSearchBar({
    required String hintText,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search, color: primary.withOpacity(0.6), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: textLight, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                fillColor: Colors.transparent,
                filled: false,
              ),
              style: const TextStyle(fontSize: 14, color: textDark),
            ),
          ),
        ],
      ),
    );
  }

  // === SNACKBAR (tidak berubah) ===
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
  }) {
    Color bg = backgroundColor ?? primary;
    IconData defaultIcon = icon ?? Icons.info_outline;

    if (backgroundColor == Colors.red || backgroundColor == accent) {
      bg = const Color(0xFFEF4444);
      defaultIcon = icon ?? Icons.error_outline;
    } else if (backgroundColor == Colors.green) {
      bg = const Color(0xFF10B981);
      defaultIcon = icon ?? Icons.check_circle_outline;
    } else if (backgroundColor == Colors.orange) {
      bg = const Color(0xFFF59E0B);
      defaultIcon = icon ?? Icons.warning_amber_outlined;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(defaultIcon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.0),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // === SETUP SCREEN (tidak berubah) ===
  static Widget buildSetupScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.settings_suggest, size: 80, color: primary),
              const SizedBox(height: 24),
              const Text(
                "Supabase Belum Dikonfigurasi",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Silakan masukkan Supabase URL dan Anon Key Anda di file berikut agar aplikasi dapat terhubung ke database:",
                style: TextStyle(fontSize: 14, color: textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "lib/utils/supabase_config.dart",
                  style: TextStyle(
                    fontFamily: "monospace",
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === GRADIENT CARD (tidak berubah) ===
  static Widget buildGradientCard({
    required Widget child,
    LinearGradient gradient = primaryGradient,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
