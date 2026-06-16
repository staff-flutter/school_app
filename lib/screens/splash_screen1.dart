import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _sparkleController;
  late AnimationController _finalController;
  late Future<void> _authFuture;

  int _phase = 0;
  final List<_IconParticle> _particles = [];
  final List<_BackgroundSparkle> _bgSparkles = [];
  final Random _rand = Random();

  static const Color kBg = Color(0xFF0A1A3F);

  final List<String> _emojis = [
    '📚', '🔬', '🧮', '🌍',
    '✏️', '🎓', '🧬', '📐',
  ];

  @override
  void initState() {
    super.initState();

    // Main controller for the burst and retract
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Background twinkling
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Final UI reveal controller
    _finalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Initialize background star field
    for (int i = 0; i < 60; i++) {
      _bgSparkles.add(_BackgroundSparkle(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        size: _rand.nextDouble() * 2.0 + 0.5,
        opacity: _rand.nextDouble(),
        speed: _rand.nextDouble() * 0.05 + 0.02,
      ));
    }

    _authFuture = _resolveAuth();
    _initParticles();
    _runSequence();
  }

  void _initParticles() {
    for (int i = 0; i < _emojis.length; i++) {
      final angle = (i * 2 * pi) / _emojis.length;
      _particles.add(_IconParticle(
        emoji: _emojis[i],
        angle: angle,
      ));
    }
  }

  Future<void> _runSequence() async {
    // --- PHASE 0: Emerge from center ---
    setState(() => _phase = 0);
    await _mainController.animateTo(
      0.55,
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic, // Elegant expansion
    );

    // Pause to appreciate the icons
    await Future.delayed(const Duration(milliseconds: 400));

    // --- PHASE 1: Retract to center ---
    setState(() => _phase = 1);
    await _mainController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInBack, // Pulling back in
    );

    // --- PHASE 2: Show Final UI ---
    setState(() => _phase = 2);
    await _finalController.forward();

    // --- HOLD: Keep the logo on screen for 2 seconds ---
    await Future.delayed(const Duration(seconds: 2));

    await _checkAuthAndNavigate();
  }

  Future<void> _resolveAuth() async {
    final controller = Get.find<AuthController>();
    final token = controller.storage.read('token');
    final userData = controller.storage.read('user');
    if (token != null && userData != null) {
      controller.user.value = User.fromJson(userData);
      final schoolData = controller.storage.read('userSchool');
      if (schoolData != null) {
        controller.userSchool.value = Map<String, dynamic>.from(schoolData);
      }
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    await _authFuture;
    final controller = Get.find<AuthController>();
    try {
      final token = controller.storage.read('token');
      final userData = controller.storage.read('user');

      if (token != null && userData != null) {
        final userRole = controller.user.value?.role?.toLowerCase();
        const restrictedRoles = ['accountant', 'parent'];

        if (restrictedRoles.contains(userRole)) {
          controller.navigateBasedOnRole();
          return;
        }

        final authResult = await controller.isAuthenticated();
        if (authResult['ok'] == true) {
          controller.navigateBasedOnRole();
          return;
        }
      }
      Get.offAllNamed('/login');
    } catch (e) {
      Get.offAllNamed('/login');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _sparkleController.dispose();
    _finalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          if (_phase < 2)
            AnimatedBuilder(
              animation: Listenable.merge([_mainController, _sparkleController]),
              builder: (context, _) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _StardustPainter(
                  progress: _mainController.value,
                  phase: _phase,
                  particles: _particles,
                  bgSparkles: _bgSparkles,
                  time: _sparkleController.value,
                ),
              ),
            ),
          if (_phase == 2)
            AnimatedBuilder(
              animation: _finalController,
              builder: (context, _) => _buildFinalUI(_finalController.value),
            ),
        ],
      ),
    );
  }

  Widget _buildFinalUI(double value) {
    final curve = Curves.easeOutCubic.transform(value);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [const Color(0xFF1565C0).withOpacity(0.4 * curve), kBg],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curve)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3 * curve),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: const Center(child: Text('🏫', style: TextStyle(fontSize: 50))),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SCHOOL APP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'LEARNING BEGINS HERE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                _LoadingDots(visible: value > 0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StardustPainter extends CustomPainter {
  final double progress;
  final int phase;
  final List<_IconParticle> particles;
  final List<_BackgroundSparkle> bgSparkles;
  final double time;

  const _StardustPainter({
    required this.progress,
    required this.phase,
    required this.particles,
    required this.bgSparkles,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background stars
    for (var s in bgSparkles) {
      final x = s.x * size.width;
      final y = ((s.y * size.height) - (time * 30 * s.speed)) % size.height;
      canvas.drawCircle(
        Offset(x, y),
        s.size,
        Paint()..color = Colors.white.withOpacity(s.opacity * (1.0 - progress)),
      );
    }

    // Emoji Logic
    for (var p in particles) {
      double radius;
      double opacity;

      if (phase == 0) {
        final t = (progress / 0.55).clamp(0.0, 1.0);
        radius = 150 * Curves.easeOutBack.transform(t);
        opacity = t.clamp(0.0, 1.0);
      } else {
        final t = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
        radius = 150 * (1.0 - Curves.easeInQuart.transform(t));
        opacity = (1.0 - t).clamp(0.0, 1.0);
      }

      final x = center.dx + cos(p.angle) * radius;
      final y = center.dy + sin(p.angle) * radius;

      final tp = TextPainter(
        text: TextSpan(text: p.emoji, style: const TextStyle(fontSize: 28)),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.saveLayer(Rect.fromLTWH(x - 20, y - 20, 40, 40), Paint()..color = Colors.white.withOpacity(opacity));
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StardustPainter old) => true;
}

class _LoadingDots extends StatefulWidget {
  final bool visible;
  const _LoadingDots({required this.visible});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with TickerProviderStateMixin {
  late List<AnimationController> _dots;

  @override
  void initState() {
    super.initState();
    _dots = List.generate(3, (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    ));
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _dots[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var d in _dots) d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _dots[i],
        builder: (context, _) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.3 + (0.7 * _dots[i].value)),
          ),
        ),
      )),
    );
  }
}

class _IconParticle {
  final String emoji;
  final double angle;
  _IconParticle({required this.emoji, required this.angle});
}

class _BackgroundSparkle {
  final double x, y, size, opacity, speed;
  const _BackgroundSparkle({required this.x, required this.y, required this.size, required this.opacity, required this.speed});
}