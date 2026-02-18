import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';

class SplashView extends GetView<AuthController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Start authentication check when splash screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.navBarSelectedGradient,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // School logo with gradient background
              _AnimatedSchoolIcon(),
              SizedBox(height: 32),
              // App title
              Text(
                'School Management System',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Finance & Accounting Portal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              // Loading indicator
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Checking authentication...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkAuthAndNavigate() async {
    try {

      // Check if we have stored authentication data
      final token = controller.storage.read('token');
      final userData = controller.storage.read('user');

      if (token != null && userData != null) {

        // Restore user and school data from storage
        controller.user.value = User.fromJson(userData);
        final schoolData = controller.storage.read('userSchool');
        if (schoolData != null) {
          controller.userSchool.value = Map<String, dynamic>.from(schoolData);
        }

        final userRole = controller.user.value?.role?.toLowerCase();

        // Roles that are NOT allowed to call isAuthenticated API
        const restrictedRoles = ['accountant', 'parent'];

        if (restrictedRoles.contains(userRole)) {

          // For restricted roles, trust stored credentials and navigate directly
          controller.navigateBasedOnRole();
          return;
        }

        // Verify authentication with server for allowed roles
        final authResult = await controller.isAuthenticated();

        if (authResult['ok'] == true) {
          
          // User is authenticated, navigate to dashboard
          controller.navigateBasedOnRole();
          return;
        } else {
          
        }
      } else {
        
      }

      // No valid session, go to login
      
      Get.offAllNamed('/login');
    } catch (e) {
      
      // Error checking auth, go to login
      Get.offAllNamed('/login');
    }
  }
}

class _AnimatedSchoolIcon extends StatefulWidget {
  const _AnimatedSchoolIcon();

  @override
  State<_AnimatedSchoolIcon> createState() => _AnimatedSchoolIconState();
}

class _AnimatedSchoolIconState extends State<_AnimatedSchoolIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.navBarSelectedGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.navBarSelectedDeep.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.school,
              size: 48,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
