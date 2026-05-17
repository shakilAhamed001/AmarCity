// Flutter material design import
import 'package:flutter/material.dart';

// SplashScreen — App চালু হলে প্রথমে এই screen দেখায়
// TickerProviderStateMixin — animation এর জন্য দরকার
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ৩টি আলাদা animation controller
  late AnimationController _fadeController;   // পুরো screen fade in
  late AnimationController _scaleController;  // Logo scale up
  late AnimationController _slideController;  // Text slide up

  // Animation object গুলো
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Animation setup করা হচ্ছে
    _initializeAnimations();
    // ৩ সেকেন্ড পর login screen এ navigate করবে
    _navigateToHome();
  }

  // সব animation initialize ও start করার function
  void _initializeAnimations() {
    // Fade animation — 1.5 সেকেন্ডে পুরো screen fade in হবে
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Scale animation — logo 0.5x থেকে 1x size এ আসবে (elastic effect)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Slide animation — text নিচ থেকে উপরে আসবে
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // নিচে শুরু
      end: Offset.zero,            // স্বাভাবিক position এ শেষ
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    // Fade ও scale animation একসাথে শুরু হচ্ছে
    _fadeController.forward();
    _scaleController.forward();
    // Slide animation ৩০০ms delay এ শুরু হচ্ছে
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _slideController.forward();
    });
  }

  // ৩ সেকেন্ড পর login screen এ navigate করার function
  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3), () {});
    if (mounted) {
      // Current route replace করে login screen এ যাচ্ছে
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    // Memory leak এড়াতে সব controller dispose করা হচ্ছে
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FadeTransition — পুরো screen fade in হবে
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          // Blue gradient background
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF001F5C), // উপরে গাঢ় নীল
                const Color(0xFF004B9E), // মাঝে মাঝারি নীল
                const Color(0xFF0066CC), // নিচে উজ্জ্বল নীল
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ScaleTransition — logo scale up হবে
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white24,
                      width: 2,
                    ),
                    // Logo এর চারপাশে glow effect
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.cyan.shade300,
                          Colors.blue.shade400,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.apartment,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // SlideTransition — app name ও tagline slide up হবে
              SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // App name
                    const Text(
                      'AmarCity',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tagline
                    const Text(
                      'SMART MUNICIPALITY',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),

              // Version info ও loading indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Divider(
                      color: Colors.white24,
                      height: 1,
                    ),
                    const SizedBox(height: 20),
                    // Version number
                    const Text(
                      'Version 1.0.0 - Dhaka',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Bangladesh',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Circular loading indicator — app load হচ্ছে বোঝাতে
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
