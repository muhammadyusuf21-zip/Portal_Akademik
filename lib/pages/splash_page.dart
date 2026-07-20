import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Lingkaran dekorasi kiri bawah (baru)
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Lingkaran dekorasi kanan atas (baru)
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Konten tengah
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Logo: easeOutBack scale (baru, lebih smooth dari bounceOut)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: scale.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // 2. Teks: slide-up + fade (baru)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 40.0, end: 0.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, offset, child) {
                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: Opacity(
                        opacity: (1 - offset / 40).clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      const Text(
                        "PORTAL AKADEMIK",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Accent divider amber (baru, ganti garis polos)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 40,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 24,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Sistem Akademik Universitas Potensi Utama",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Bottom indicator: dot loader (baru, ganti circular progress)
            Positioned(
              bottom: 50,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1400),
                builder: (context, opacity, child) {
                  return Opacity(opacity: opacity, child: child);
                },
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == 1 ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == 1
                                ? AppTheme.accent
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Memuat Platform...",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
