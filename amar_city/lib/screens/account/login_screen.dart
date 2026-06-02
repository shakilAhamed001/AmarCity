import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../services/supabase_service.dart';
import '../forget_password/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _starCtrl;
  late AnimationController _birdCtrl;
  late AnimationController _wingCtrl;
  late Animation<double> _wingAnim;

  final List<_StarData> _stars = [];
  final List<_BirdData> _birds = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _buildStars();
    _buildBirds();
    _setupAnimations();
  }

  void _buildStars() {
    for (int i = 0; i < 60; i++) {
      _stars.add(_StarData(
        x: _rng.nextDouble(),
        y: _rng.nextDouble() * 0.55,
        size: _rng.nextDouble() * 2.0 + 0.5,
        phase: _rng.nextDouble(),
      ));
    }
  }

  void _buildBirds() {
    for (int i = 0; i < 6; i++) {
      _birds.add(_BirdData(
        startX: -0.1 - _rng.nextDouble() * 0.4,
        y: 0.18 + _rng.nextDouble() * 0.18,
        speed: 0.06 + _rng.nextDouble() * 0.08,
        scale: 0.6 + _rng.nextDouble() * 0.6,
        phase: _rng.nextDouble(),
      ));
    }
  }

  void _setupAnimations() {
    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _birdCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 8000))
      ..repeat();
    _wingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..repeat(reverse: true);
    _wingAnim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _wingCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _starCtrl.dispose();
    _birdCtrl.dispose();
    _wingCtrl.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.user != null && mounted) {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .maybeSingle();
        final role = (profile?['role'] as String? ?? '').toLowerCase();
        if (!mounted) return;
        if (role == 'admin') {
          Navigator.of(context).pushReplacementNamed('/admin');
        } else if (role == 'officer') {
          Navigator.of(context).pushReplacementNamed('/officer');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.contains('email_not_confirmed')) {
          message = 'Please verify your email first. Check your inbox.';
        } else if (message.contains('invalid_credentials')) {
          message = 'Invalid email or password.';
        } else if (message.contains('user_already_exists') ||
            message.contains('User already registered')) {
          message =
              'This email is already registered. Please verify your email or try logging in.';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF001F5C),
                  Color(0xFF004B9E),
                  Color(0xFF0066CC),
                ],
              ),
            ),
          ),

          // Twinkling stars
          AnimatedBuilder(
            animation: _starCtrl,
            builder: (_, __) => CustomPaint(
              painter: _StarPainter(stars: _stars, progress: _starCtrl.value),
              child: const SizedBox.expand(),
            ),
          ),

          // Flying birds
          AnimatedBuilder(
            animation: Listenable.merge([_birdCtrl, _wingCtrl]),
            builder: (_, __) => CustomPaint(
              painter: _BirdPainter(
                birds: _birds,
                progress: _birdCtrl.value,
                wingAngle: _wingAnim.value,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // Main scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.cyan.shade300,
                                Colors.blue.shade400,
                              ],
                            ),
                          ),
                          child: const Icon(Icons.apartment,
                              color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'AmarCity',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'SMART MUNICIPALITY PLATFORM',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Glass card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Welcome back',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 5),
                            Text('Sign in to your civic dashboard',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.7))),
                            const SizedBox(height: 25),
                            Text('EMAIL ADDRESS',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.8),
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _fieldDecoration(
                                hint: 'rahim@example.com',
                                icon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('PASSWORD',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.8),
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _fieldDecoration(
                                hint: 'Enter your password',
                                icon: Icons.lock_outlined,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen()),
                                ),
                                child: Text('Forgot Password?',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.85),
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0066CC),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : const Text('Sign in securely',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.5)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(children: [
                              Expanded(
                                  child: Container(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.2))),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or continue with',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.5))),
                              ),
                              Expanded(
                                  child: Container(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.2))),
                            ]),
                            const SizedBox(height: 20),
                            Row(children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: Text('Google',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 14)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: Text('Facebook',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 14)),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 20),
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: 'New to AmarCity? ',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.7)),
                                  children: [
                                    TextSpan(
                                      text: 'Create account',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => Navigator.of(context)
                                            .pushNamed('/create_account'),
                                    ),
                                    const TextSpan(
                                      text: ' ↗',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
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
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Star data ──
class _StarData {
  final double x, y, size, phase;
  const _StarData(
      {required this.x,
      required this.y,
      required this.size,
      required this.phase});
}

class _StarPainter extends CustomPainter {
  final List<_StarData> stars;
  final double progress;
  const _StarPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final twinkle = sin((progress + s.phase) * 2 * pi) * 0.5 + 0.5;
      paint.color = Colors.white.withOpacity(twinkle * 0.7 + 0.1);
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.progress != progress;
}

// ── Bird data ──
class _BirdData {
  final double startX, y, speed, scale, phase;
  const _BirdData(
      {required this.startX,
      required this.y,
      required this.speed,
      required this.scale,
      required this.phase});
}

class _BirdPainter extends CustomPainter {
  final List<_BirdData> birds;
  final double progress;
  final double wingAngle;
  const _BirdPainter(
      {required this.birds,
      required this.progress,
      required this.wingAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.75)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final b in birds) {
      final x =
          ((b.startX + (progress + b.phase) * b.speed * 3) % 1.4 - 0.1) *
              size.width;
      final y =
          b.y * size.height + sin((progress + b.phase) * 2 * pi * 2) * 6;
      final s = b.scale * 10;
      final flap = sin(wingAngle * pi) * 0.5;

      canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(
                x - s * 0.8, y - s * flap, x - s * 1.6, y + s * 0.1),
          paint);
      canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(
                x + s * 0.8, y - s * flap, x + s * 1.6, y + s * 0.1),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BirdPainter old) =>
      old.progress != progress || old.wingAngle != wingAngle;
}
