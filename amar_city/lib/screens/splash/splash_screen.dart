import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateToHome();
  }

  void _initializeAnimations() {
    // Fade animation for the entire content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Scale animation for logo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Slide animation for text
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    // Start animations in sequence
    _fadeController.forward();
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _slideController.forward();
    });
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3), () {});
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
      // Or use: Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (context) => const HomePage()),
      // );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF001F5C), // Dark blue top
                const Color(0xFF004B9E), // Medium blue
                const Color(0xFF0066CC), // Bright blue bottom
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
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
              
              // Animated App Name
              SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
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
                    // Animated Tagline
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
              
              // Version Info with Loading Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Divider(
                      color: Colors.white24,
                      height: 1,
                    ),
                    const SizedBox(height: 20),
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
                    // Loading Indicator
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

