import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF001F5C);
  static const primary = Color(0xFFFFFFFF);
  static const primaryLight = Color(0xFFAFA9EC);
  static const primaryFaint = Color(0x33FFFFFF);
  static const textDark = Color(0xFFFFFFFF);
  static const textMid = Color(0xFFCCCCFF);
  static const shimmer = Color(0xFFE0E8FF);
  static const star = Color(0xFFFFFFFF);
  static const cityFill = Color(0xFF0A2E7A);
  static const cityStroke = Color(0xFF3A5FBF);
  static const progressBg = Color(0x33FFFFFF);
  static const progressFill = Color(0xFFFFFFFF);
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconCtrl;
  late AnimationController _textCtrl;
  late AnimationController _tagCtrl;
  late AnimationController _taglineCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _cityCtrl;
  late AnimationController _starCtrl;
  late AnimationController _progressCtrl;
  late AnimationController _birdCtrl;
  late AnimationController _wingCtrl;

  late Animation<double> _iconScale;
  late Animation<double> _iconRotate;
  late Animation<double> _iconOpacity;

  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  late Animation<double> _tagOpacity;
  late Animation<Offset> _tagSlide;

  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;

  late Animation<double> _shimmerAnim;
  late Animation<double> _citySlide;
  late Animation<double> _progressAnim;
  late Animation<double> _wingAnim;

  final List<_ParticleData> _particles = [];
  final List<_StarData> _stars = [];
  final List<_BirdData> _birds = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _buildParticles();
    _buildStars();
    _buildBirds();
    _setupAnimations();
    _startSequence();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  void _buildParticles() {
    final colors = [
      const Color(0xFF534AB7),
      const Color(0xFF1A56FF),
      const Color(0xFF1D9E75),
      const Color(0xFFBA7517),
      const Color(0xFFAFA9EC),
    ];
    for (int i = 0; i < 18; i++) {
      _particles.add(_ParticleData(
        x: _rng.nextDouble(),
        size: _rng.nextDouble() * 5 + 2,
        color: colors[_rng.nextInt(colors.length)],
      ));
    }
  }

  void _buildStars() {
    for (int i = 0; i < 60; i++) {
      _stars.add(_StarData(
        x: _rng.nextDouble(),
        y: _rng.nextDouble() * 0.7,
        size: _rng.nextDouble() * 2.0 + 0.5,
        phase: _rng.nextDouble(),
      ));
    }
  }

  void _buildBirds() {
    for (int i = 0; i < 6; i++) {
      _birds.add(_BirdData(
        startX: -0.1 - _rng.nextDouble() * 0.4,
        y: 0.42 + _rng.nextDouble() * 0.12,
        speed: 0.06 + _rng.nextDouble() * 0.08,
        scale: 0.6 + _rng.nextDouble() * 0.6,
        phase: _rng.nextDouble(),
      ));
    }
  }

  void _setupAnimations() {
    _iconCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _iconScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
    ]).animate(_iconCtrl);

    _iconRotate = Tween(begin: -0.26, end: 0.0)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut));

    _iconOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _textOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _tagCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _tagOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut));
    _tagSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut));

    _taglineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _taglineOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));
    _taglineSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 10000))..repeat();

    // Shimmer on text
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _shimmerAnim = Tween(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // City skyline rising from bottom
    _cityCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _citySlide = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _cityCtrl, curve: Curves.easeOut));

    // Twinkling stars
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

    // Progress bar
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _progressAnim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut));

    // Birds flying across screen
    _birdCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 8000))..repeat();

    // Wing flap
    _wingCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..repeat(reverse: true);
    _wingAnim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _wingCtrl, curve: Curves.easeInOut));
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _iconCtrl.forward();
    _cityCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _tagCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _progressCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _taglineCtrl.forward();
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _textCtrl.dispose();
    _tagCtrl.dispose();
    _taglineCtrl.dispose();
    _ringCtrl.dispose();
    _particleCtrl.dispose();
    _shimmerCtrl.dispose();
    _cityCtrl.dispose();
    _starCtrl.dispose();
    _progressCtrl.dispose();
    _birdCtrl.dispose();
    _wingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Twinkling stars
          AnimatedBuilder(
            animation: _starCtrl,
            builder: (_, __) => CustomPaint(
              painter: _StarPainter(stars: _stars, progress: _starCtrl.value),
              child: const SizedBox.expand(),
            ),
          ),

          // Floating particles
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(particles: _particles, progress: _particleCtrl.value),
              child: const SizedBox.expand(),
            ),
          ),

          // Pulse rings
          Center(
            child: AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  for (final delay in [0.0, 0.27, 0.54]) _buildRing(delay),
                ],
              ),
            ),
          ),

          // City skyline + trees at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _cityCtrl,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _citySlide.value * 200),
                child: Opacity(
                  opacity: (1.0 - _citySlide.value).clamp(0.0, 1.0),
                  child: CustomPaint(
                    size: Size(size.width, 160),
                    painter: _CitySkylinePainter(),
                  ),
                ),
              ),
            ),
          ),

          // Birds
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

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo icon
                AnimatedBuilder(
                  animation: _iconCtrl,
                  builder: (_, __) => Opacity(
                    opacity: _iconOpacity.value,
                    child: Transform.rotate(
                      angle: _iconRotate.value,
                      child: Transform.scale(
                        scale: _iconScale.value,
                        child: const _AppIcon(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // App name with shimmer
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: AnimatedBuilder(
                      animation: _shimmerAnim,
                      builder: (_, __) => ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: const [
                            Color(0xFFFFFFFF),
                            Color(0xFFE0E8FF),
                            Color(0xFFFFFFFF),
                            Color(0xFFCCCCFF),
                            Color(0xFFFFFFFF),
                          ],
                          stops: [
                            (_shimmerAnim.value - 0.4).clamp(0.0, 1.0),
                            (_shimmerAnim.value - 0.1).clamp(0.0, 1.0),
                            _shimmerAnim.value.clamp(0.0, 1.0),
                            (_shimmerAnim.value + 0.1).clamp(0.0, 1.0),
                            (_shimmerAnim.value + 0.4).clamp(0.0, 1.0),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'AmarCity',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle
                FadeTransition(
                  opacity: _tagOpacity,
                  child: SlideTransition(
                    position: _tagSlide,
                    child: const Text(
                      'SMART MUNICIPALITY PLATFORM',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _C.primary,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Progress bar
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) => Opacity(
                    opacity: _progressCtrl.value > 0 ? 1.0 : 0.0,
                    child: Column(
                      children: [
                        Container(
                          width: 160,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _C.progressBg,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: _progressAnim.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _C.progressFill,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.6),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Tagline
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: const Text(
                      'Connecting citizens to solutions',
                      style: TextStyle(fontSize: 11, color: _C.textMid),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRing(double delay) {
    final t = (_ringCtrl.value + delay) % 1.0;
    final opacity = (1.0 - t) * 0.08;
    final scale = 0.5 + t * 2.0;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _C.primary.withOpacity(opacity), width: 1),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// APP ICON
// ─────────────────────────────────────────────

class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _C.primaryFaint,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white30, width: 1.5),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(40, 40),
          painter: _CityLogoPainter(),
        ),
      ),
    );
  }
}

class _CityLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;
    final rrect = (Rect r) => RRect.fromRectAndRadius(r, const Radius.circular(2));

    paint.color = Colors.white54;
    canvas.drawRRect(rrect(Rect.fromLTWH(w * 0.09, h * 0.52, w * 0.23, h * 0.38)), paint);

    paint.color = Colors.white;
    canvas.drawRRect(rrect(Rect.fromLTWH(w * 0.38, h * 0.33, w * 0.23, h * 0.57)), paint);

    paint.color = Colors.white70;
    canvas.drawRRect(rrect(Rect.fromLTWH(w * 0.67, h * 0.43, w * 0.23, h * 0.47)), paint);

    paint.color = Colors.white24;
    canvas.drawRRect(rrect(Rect.fromLTWH(w * 0.45, h * 0.66, w * 0.10, h * 0.24)), paint);

    paint.color = Colors.white60;
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), w * 0.07, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// BIRDS
// ─────────────────────────────────────────────

class _BirdData {
  final double startX, y, speed, scale, phase;
  const _BirdData({
    required this.startX,
    required this.y,
    required this.speed,
    required this.scale,
    required this.phase,
  });
}

class _BirdPainter extends CustomPainter {
  final List<_BirdData> birds;
  final double progress;
  final double wingAngle;

  const _BirdPainter({required this.birds, required this.progress, required this.wingAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.75)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final b in birds) {
      final x = ((b.startX + (progress + b.phase) * b.speed * 3) % 1.4 - 0.1) * size.width;
      final y = b.y * size.height + sin((progress + b.phase) * 2 * pi * 2) * 6;
      final s = b.scale * 10;
      final flap = sin(wingAngle * pi) * 0.5;

      // Left wing
      final path = Path();
      path.moveTo(x, y);
      path.quadraticBezierTo(x - s * 0.8, y - s * flap, x - s * 1.6, y + s * 0.1);

      // Right wing
      final path2 = Path();
      path2.moveTo(x, y);
      path2.quadraticBezierTo(x + s * 0.8, y - s * flap, x + s * 1.6, y + s * 0.1);

      canvas.drawPath(path, paint);
      canvas.drawPath(path2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BirdPainter old) =>
      old.progress != progress || old.wingAngle != wingAngle;
}

// ─────────────────────────────────────────────
// CITY SKYLINE
// ─────────────────────────────────────────────

class _CitySkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _C.cityFill;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = _C.cityStroke
      ..strokeWidth = 1.0;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Buildings
    final buildings = [
      [0.0, 0.6, 0.08, 1.0],
      [0.06, 0.45, 0.06, 1.0],
      [0.10, 0.55, 0.07, 1.0],
      [0.16, 0.35, 0.06, 1.0],
      [0.21, 0.50, 0.05, 1.0],
      [0.25, 0.25, 0.08, 1.0],
      [0.32, 0.40, 0.06, 1.0],
      [0.37, 0.20, 0.07, 1.0],
      [0.43, 0.38, 0.06, 1.0],
      [0.48, 0.15, 0.09, 1.0],
      [0.56, 0.30, 0.06, 1.0],
      [0.61, 0.45, 0.07, 1.0],
      [0.67, 0.22, 0.08, 1.0],
      [0.74, 0.38, 0.06, 1.0],
      [0.79, 0.50, 0.07, 1.0],
      [0.85, 0.32, 0.06, 1.0],
      [0.90, 0.55, 0.05, 1.0],
      [0.94, 0.42, 0.06, 1.0],
    ];

    path.moveTo(0, h);
    for (final b in buildings) {
      final x = b[0] * w;
      final top = b[1] * h;
      final bw = b[2] * w;
      path.lineTo(x, h);
      path.lineTo(x, top);
      path.lineTo(x + bw, top);
      path.lineTo(x + bw, h);
    }
    path.lineTo(w, h);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Windows
    final winPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x55A0C4FF);

    for (final b in buildings) {
      final x = b[0] * w;
      final top = b[1] * h;
      final bw = b[2] * w;
      final bh = h - top;
      final cols = (bw / 6).floor().clamp(1, 4);
      final rows = (bh / 10).floor().clamp(1, 6);
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          canvas.drawRect(
            Rect.fromLTWH(
              x + c * (bw / cols) + 1.5,
              top + r * (bh / rows) + 2,
              bw / cols - 3,
              bh / rows - 4,
            ),
            winPaint,
          );
        }
      }
    }

    // Trees in foreground
    _drawTree(canvas, w * 0.04, h * 0.62, 18, w);
    _drawTree(canvas, w * 0.13, h * 0.68, 14, w);
    _drawTree(canvas, w * 0.88, h * 0.65, 16, w);
    _drawTree(canvas, w * 0.96, h * 0.70, 13, w);
    _drawTree(canvas, w * 0.72, h * 0.72, 12, w);
    _drawTree(canvas, w * 0.30, h * 0.74, 11, w);
  }

  void _drawTree(Canvas canvas, double x, double baseY, double size, double w) {
    final trunkPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF1A3A6A);

    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF0D4A2A);

    final leafStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1A7A40)
      ..strokeWidth = 0.8;

    // Trunk
    canvas.drawRect(
      Rect.fromLTWH(x - size * 0.1, baseY - size * 0.5, size * 0.2, size * 0.5),
      trunkPaint,
    );

    // Layered triangles (pine tree)
    for (int i = 0; i < 3; i++) {
      final layerY = baseY - size * 0.4 - i * size * 0.35;
      final layerW = size * (1.0 - i * 0.2);
      final treePath = Path()
        ..moveTo(x, layerY - size * 0.5)
        ..lineTo(x - layerW * 0.6, layerY)
        ..lineTo(x + layerW * 0.6, layerY)
        ..close();
      canvas.drawPath(treePath, leafPaint);
      canvas.drawPath(treePath, leafStroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// STARS
// ─────────────────────────────────────────────

class _StarData {
  final double x, y, size, phase;
  const _StarData({required this.x, required this.y, required this.size, required this.phase});
}

class _StarPainter extends CustomPainter {
  final List<_StarData> stars;
  final double progress;

  const _StarPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final twinkle = (sin((progress + s.phase) * 2 * pi) * 0.5 + 0.5);
      paint.color = _C.star.withOpacity(twinkle * 0.7 + 0.1);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
// PARTICLES
// ─────────────────────────────────────────────

class _ParticleData {
  final double x, size;
  final Color color;
  const _ParticleData({required this.x, required this.size, required this.color});
}

class _ParticlePainter extends CustomPainter {
  final List<_ParticleData> particles;
  final double progress;

  const _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final y = size.height * (1.0 - progress);
      paint.color = p.color.withOpacity(0.15);
      canvas.drawCircle(Offset(p.x * size.width, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress;
}
