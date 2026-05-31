import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';

class MainWrapperWithNoNavBar extends StatelessWidget {
  final Widget child;

  const MainWrapperWithNoNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: SafeArea(
        top: false,
        child: Scaffold(
          extendBody: true,
          backgroundColor: AppTheme.appBackground,
          body: child,
        ),
      ),
    );
  }
}