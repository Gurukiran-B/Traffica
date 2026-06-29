import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/gradient_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    // Wait for 3 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Navigate to login screen after splash
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0052CC), Color(0xFF2E7DFF)],
                  ),
                ),
                child: const Icon(Icons.traffic_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 18),
              Text('Traffica', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const SizedBox(
                width: 200,
                child: LinearProgressIndicator(minHeight: 5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
