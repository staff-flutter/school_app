import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/main_navigation_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/animated_nav_bar.dart';

class MainWrapper extends StatelessWidget {
  final Widget child;
  
  const MainWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainNavigationController>(
      init: MainNavigationController(),
      builder: (controller) {
        return Scaffold(
          extendBody: true, // Crucial for floating nav bar to show content behind it
          backgroundColor: AppTheme.appBackground,
          body: SafeArea(
            bottom: false, // Let navigation bar handle the bottom padding or space
            child: child,
          ),
          bottomNavigationBar: const AnimatedNavBar(),
        );
      },
    );
  }
}
  IconData _getIconData(String label) {
    switch (label.toLowerCase()) {
      case 'dashboard':
        return Icons.dashboard;
      case 'users':
        return Icons.people;
      case 'students':
        return Icons.school;
      case 'fee collection':
        return Icons.payment;
      case 'teacher assignments':
        return Icons.assignment_ind;
      case 'fee structure':
        return Icons.account_balance_wallet;
      case 'attendance':
        return Icons.how_to_reg;
      case 'clubs':
        return Icons.groups;
      case 'my children':
        return Icons.child_care;
      case 'announcements':
      case 'communications':
        return Icons.campaign;
      case 'records':
        return Icons.folder;
      case 'profile':
        return Icons.person;
      case 'expenses':
        return Icons.receipt_long;
      case 'reports':
        return Icons.analytics;
      case 'academics':
        return Icons.school;
      case 'schools':
      case 'school':
        return Icons.business;
      case 'fees':
        return Icons.payment;
      case 'my classes':
        return Icons.class_;
      case 'subscription':
        return Icons.subscriptions;
      case 'homework':
        return Icons.assignment;
      case 'timetable':
        return Icons.schedule;
      default:
        return Icons.dashboard;
    }
  }
