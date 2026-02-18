import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_navigation_controller.dart';
import '../core/theme/app_theme.dart';

class MainWrapper extends StatelessWidget {
  final Widget child;
  
  const MainWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainNavigationController>(
      init: MainNavigationController(),
      builder: (controller) {
        return Scaffold(
          body: SafeArea(child: child),
          bottomNavigationBar: Obx(() {
            final items = controller.navigationItems;
            if (items.isEmpty) return const SizedBox.shrink();
            
            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: controller.selectedIndex.value.clamp(0, items.length - 1),
              onTap: (index) {
                try {
                  controller.selectedIndex.value = index;
                  controller.onItemTapped(index);
                } catch (e) {
                  
                }
              },
              selectedItemColor: AppTheme.primaryBlue,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              elevation: 8,
              items: items.map((item) => BottomNavigationBarItem(
                icon: Icon(_getIconData(item.label)),
                label: item.label,
              )).toList(),
            );
          }),
        );
      },
    );
  }

  IconData _getIconData(String label) {
    switch (label.toLowerCase()) {
      case 'dashboard':
        return Icons.dashboard;
      case 'users':
        return Icons.people;
      case 'students':
        return Icons.school;
      case 'clubs':
        return Icons.groups;
      case 'announcements':
      case 'communications':
        return Icons.campaign;
      case 'attendance':
        return Icons.how_to_reg;
      case 'expenses':
        return Icons.receipt_long;
      case 'schools':
      case 'school':
        return Icons.business;
      case 'my children':
        return Icons.child_care;
      case 'my classes':
        return Icons.class_;
      case 'profile':
        return Icons.person;
      case 'homework':
        return Icons.assignment;
      case 'timetable':
        return Icons.schedule;
      case 'subscription':
        return Icons.subscriptions;
      default:
        return Icons.dashboard;
    }
  }
}