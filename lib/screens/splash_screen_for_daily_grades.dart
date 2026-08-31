import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../main.dart' show bootstrapFuture;

class DynamicSchoolSplashScreen extends StatefulWidget {
  const DynamicSchoolSplashScreen({super.key});

  @override
  State<DynamicSchoolSplashScreen> createState() =>
      _DynamicSchoolSplashScreenState();
}

class _DynamicSchoolSplashScreenState extends State<DynamicSchoolSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _spiralAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;

  late Future<void> _authFuture;
  @override
  void initState() {
    super.initState();
    _authFuture = _resolveAuth();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400), // slowed down from 2200
    );

    _spiralAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.72, curve: Curves.easeInOutCubic),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.85, curve: Curves.elasticOut),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _runSequence();
  }
  Future<void> _runSequence() async {
    await _controller.forward();
    // Hold final visual state briefly before routing
    await Future.delayed(const Duration(milliseconds: 800));
    await _checkAuthAndNavigate();
  }

  Future<void> _resolveAuth() async {
    await bootstrapFuture;
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
    _controller.dispose();
    super.dispose();
  }

  // Emoji stand-ins for the illustrated stationery in the reference image —
  // colorful "3D sticker" style without needing custom asset art.
  static const List<_OrbitItem> _items = [
    _OrbitItem('📓', angle: 0.0, big: false),
    _OrbitItem('✏️', angle: math.pi / 4, big: false),
    _OrbitItem('🌍', angle: math.pi / 2, big: false),
    _OrbitItem('🍎', angle: 3 * math.pi / 4, big: false),
    _OrbitItem('📈', angle: math.pi, big: true), // the big red trending arrow
    _OrbitItem('🧪', angle: 5 * math.pi / 4, big: false),
    _OrbitItem('📐', angle: 3 * math.pi / 2, big: false),
    _OrbitItem('📎', angle: 7 * math.pi / 4, big: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Soft radial glow, top area (matches the pale blue wash
            // in the top-right of the reference) ──
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.6, -0.7),
                    radius: 1.1,
                    colors: [
                      const Color(0xFFE9EEFB).withOpacity(0.9),
                      const Color(0xFFF6F8FC).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // ── Decorative background clutter (very low opacity so it
            // never competes with the animation) ──
            const Positioned(top: 28, left: 24, child: _DotGrid()),
            Positioned(
              top: 10,
              right: 10,
              child: Opacity(
                opacity: 0.10,
                child: CustomPaint(
                  size: const Size(140, 140),
                  painter: _ArcsPainter(),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 12,
              child: Opacity(
                opacity: 0.08,
                child: Icon(Icons.menu_book_rounded,
                    size: 90, color: const Color(0xFF334155)),
              ),
            ),
            Positioned(
              bottom: 30,
              right: 8,
              child: Opacity(
                opacity: 0.10,
                child: Row(
                  children: List.generate(
                    4,
                        (i) => Container(
                      width: 14,
                      height: 60 + (i.isEven ? 10 : 0),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Main animation ──
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final spiralProgress = _spiralAnimation.value;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Orbiting items + their motion trails
                    ..._items.map((item) {
                      final baseAngle = item.angle;
                      final currentAngle =
                          baseAngle + (spiralProgress * 3 * math.pi);
                      final currentRadius =
                          (1.0 - spiralProgress) * (item.big ? 205.0 : 175.0);

                      final itemScale =
                      math.max(0.0, 1.0 - (spiralProgress * 1.1));
                      final itemOpacity = math.max(0.0, 1.0 - spiralProgress);

                      final x = currentRadius * math.cos(currentAngle);
                      final y = currentRadius * math.sin(currentAngle);

                      // Trail points tangent to the circular path (perpendicular
                      // to the radius vector), trailing behind the direction
                      // of travel.
                      final trailAngle = currentAngle + math.pi / 2;

                      return Stack(
                        children: [
                          // Motion trail — a soft fading streak behind the item
                          Transform.translate(
                            offset: Offset(x, y),
                            child: Transform.rotate(
                              angle: trailAngle,
                              child: Opacity(
                                opacity: itemOpacity * 0.55,
                                child: Container(
                                  width: item.big ? 46 : 30,
                                  height: item.big ? 5 : 3.5,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFF94A3B8)
                                            .withOpacity(0.5),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // The item itself
                          Transform.translate(
                            offset: Offset(x, y),
                            child: Transform.scale(
                              scale: itemScale,
                              child: Opacity(
                                opacity: itemOpacity,
                                child: item.big
                                    ? Text(item.emoji,
                                    style: const TextStyle(fontSize: 46))
                                    : Container(
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(item.emoji,
                                      style:
                                      const TextStyle(fontSize: 28)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    // ── Central logo + wordmark ──
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Container(
                            width: 104,
                            height: 104,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1ADC2626),
                                  blurRadius: 26,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            // Uses your real app icon (the red "D" mark)
                            // instead of a placeholder Material icon so
                            // the logo matches the reference exactly.
                            child: Image.asset('assets/icons/app_icon.png'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: _textFadeAnimation.value,
                          child: Column(
                            children: const [
                              Text(
                                'Daily Grades',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Track. Learn. Succeed.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}

class _OrbitItem {
  final String emoji;
  final double angle;
  final bool big; // the standout red trending-arrow item, drawn larger/bare
  const _OrbitItem(this.emoji, {required this.angle, required this.big});
}

/// Faint dot grid accent, echoing the dotted texture in the corners of
/// the reference image.
class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (r) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (c) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF334155),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

/// Faint concentric arc accent, echoing the thin circular strokes in the
/// top-right of the reference image.
class _ArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width, 0);
    for (final r in [40.0, 70.0, 100.0]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        math.pi, // start
        math.pi / 2, // sweep
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}