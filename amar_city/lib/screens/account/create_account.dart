import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../services/supabase_service.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'Citizen';
  String? _selectedDepartment;
  bool _isLoading = false;

  static const List<String> _departments = [
    'Public Health & Sanitation Department',
    'Trade License Issuance & Registration Department',
    'Waste Management Department',
    'Engineering Department',
  ];

  // Animation
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
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _buildStars();
    _buildBirds();
    _setupAnimations();
  }

  void _buildStars() {
    for (int i = 0; i < 60; i++) {
      _stars.add(_StarData(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 2.0 + 0.5,
        phase: _rng.nextDouble(),
      ));
    }
  }

  void _buildBirds() {
    for (int i = 0; i < 6; i++) {
      _birds.add(_BirdData(
        startX: -0.1 - _rng.nextDouble() * 0.4,
        y: 0.08 + _rng.nextDouble() * 0.15,
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _starCtrl.dispose();
    _birdCtrl.dispose();
    _wingCtrl.dispose();
    super.dispose();
  }

  void _handleCreateAccount() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (_selectedRole == 'Officer' && _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
        department: _selectedDepartment,
      );
      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Account created! Please check your email to verify.')),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Back button + title row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Glassmorphism card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1.5),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create your account',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Join AmarCity community',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.7)),
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              label: 'FULL NAME',
                              hint: 'Rahim Ahmed',
                              icon: Icons.person_outline,
                              controller: _nameController,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'EMAIL ADDRESS',
                              hint: 'rahim@example.com',
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              label: 'PASSWORD',
                              hint: 'Enter your password',
                              controller: _passwordController,
                              obscure: _obscurePassword,
                              onToggle: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              label: 'CONFIRM PASSWORD',
                              hint: 'Re-enter your password',
                              controller: _confirmPasswordController,
                              obscure: _obscureConfirmPassword,
                              onToggle: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                            const SizedBox(height: 20),
                            Text('ACCOUNT TYPE',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.85),
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 12),
                            Row(children: [
                              _buildRoleButton(
                                  'Citizen', Icons.person, 'General public'),
                              const SizedBox(width: 12),
                              _buildRoleButton('Officer', Icons.work,
                                  'Municipality staff'),
                            ]),
                            if (_selectedRole == 'Officer') ...[
                              const SizedBox(height: 20),
                              ..._buildDepartmentSection(),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleCreateAccount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0066CC),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Color(0xFF0066CC),
                                            strokeWidth: 2))
                                    : const Text('Create Account',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.7)),
                                  children: [
                                    TextSpan(
                                      text: 'Sign in',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap =
                                            () => Navigator.of(context).pop(),
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Glass style text field
  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.85),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
            prefixIcon:
                Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.white, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.85),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
            prefixIcon: Icon(Icons.lock_outlined,
                color: Colors.white.withOpacity(0.8), size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.white, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButton(String role, IconData icon, String subtitle) {
    final bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(0.25),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.07),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  size: 26),
              const SizedBox(height: 6),
              Text(role,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.6))),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.45)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDepartmentSection() {
    return [
      Text('DEPARTMENT',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
              letterSpacing: 0.5)),
      const SizedBox(height: 12),
      ..._departments.map((dept) {
        final isSelected = _selectedDepartment == dept;
        return GestureDetector(
          onTap: () => setState(() => _selectedDepartment = dept),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? Colors.white.withOpacity(0.18)
                  : Colors.white.withOpacity(0.07),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(dept,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.7))),
                ),
              ],
            ),
          ),
        );
      }),
    ];
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
