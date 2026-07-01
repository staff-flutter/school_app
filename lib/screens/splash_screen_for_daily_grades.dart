import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../controllers/auth_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/user_model.dart';
import 'login_page_for_daily_grades.dart';
import 'onboarding_screen_for_daily_grades.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  State<SplashScreen1> createState() => _SplashScreenState();

}

class _SplashScreenState extends State<SplashScreen1> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late Future<void> _authFuture;


  @override

  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _authFuture = _resolveAuth();
    Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      _checkAuthAndNavigate();
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      // );
    });

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
    await _authFuture; // Wait for state resolution to finish safely

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    // First-ever launch → always show onboarding, skip auth check entirely
    if (isFirstTime) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

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
      // Not authenticated → go straight to login (onboarding already shown/skipped above)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DailyGradesLoginScreen()),
      );
    } catch (e) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DailyGradesLoginScreen()),
      );
    }
  }
  @override

  void dispose() {

    _controller.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18071B3D),
                        blurRadius: 30,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/icons/app_icon.png'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Daily Grades',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track. Learn. Succeed.',
                  style: TextStyle(color: AppColors.muted, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}

