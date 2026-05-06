import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/main_navigation_controller.dart';
import '../core/theme/app_theme.dart';
import 'animated_nav_bar.dart';

class MainWrapperWithNoNavBar extends StatelessWidget {
  final Widget child;

  const MainWrapperWithNoNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainNavigationController>(
      init: MainNavigationController(),
      builder: (controller) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: SafeArea(
            top: false,
            child: Scaffold(
              extendBody: true, // Crucial for floating nav bar to show content behind it
              backgroundColor: AppTheme.appBackground,
              // i commented out the safe area which is created by previous developer
              body:
              //  SafeArea(
              //    bottom: false, // Let navigation bar handle the bottom padding or space
              // child:
              child,
              //  ),

            ),
          ),
        );
      },
    );
  }
}
