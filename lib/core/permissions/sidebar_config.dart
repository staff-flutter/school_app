import 'package:flutter/material.dart';
import 'package:school_app/core/permissions/module_visibility.dart';

class SidebarConfig {
  static const Map<String, Map<String, dynamic>> moduleConfig = {
    'dashboard': {
      'title': 'Dashboard',
      'icon': Icons.dashboard,
      'route': '/dashboard',
    },
    'users': {
      'title': 'Users',
      'icon': Icons.people,
      'route': '/users',
    },
    'schools': {
      'title': 'Schools',
      'icon': Icons.school,
      'route': '/schools',
    },
    'schoolManagement': {
      'title': 'School Management',
      'icon': Icons.business,
      'route': '/school-management',
    },
    'classes': {
      'title': 'Classes',
      'icon': Icons.class_,
      'route': '/classes',
    },
    'sections': {
      'title': 'Sections',
      'icon': Icons.group,
      'route': '/sections',
    },
    'teacherAssignments': {
      'title': 'Teacher Assignments',
      'icon': Icons.assignment_ind,
      'route': '/teacher-assignments',
    },
    'students': {
      'title': 'Students',
      'icon': Icons.person,
      'route': '/students',
    },
    'studentRecords': {
      'title': 'Student Records',
      'icon': Icons.folder_shared,
      'route': '/student-records',
    },
    'feeStructure': {
      'title': 'Fee Structure',
      'icon': Icons.account_balance_wallet,
      'route': '/fee-structure',
    },
    'feeCollection': {
      'title': 'Fee Collection',
      'icon': Icons.payment,
      'route': '/fee-collection',
    },
    'attendance': {
      'title': 'Attendance',
      'icon': Icons.how_to_reg,
      'route': '/attendance',
    },
    'expenses': {
      'title': 'Expenses',
      'icon': Icons.receipt_long,
      'route': '/expenses',
    },
    'announcements': {
      'title': 'Announcements',
      'icon': Icons.campaign,
      'route': '/announcements',
    },
    'clubs': {
      'title': 'Clubs',
      'icon': Icons.groups,
      'route': '/clubs',
    },
    'clubVideos': {
      'title': 'Club Videos',
      'icon': Icons.video_library,
      'route': '/club-videos',
    },
    'financeLedger': {
      'title': 'Finance Ledger',
      'icon': Icons.account_balance,
      'route': '/finance-ledger',
    },
    'auditLogs': {
      'title': 'Audit Logs',
      'icon': Icons.history,
      'route': '/audit-logs',
    },
    'deleteArchive': {
      'title': 'Delete Archive',
      'icon': Icons.delete_forever,
      'route': '/delete-archive',
    },
    'subscription': {
      'title': 'Subscription',
      'icon': Icons.subscriptions,
      'route': '/subscription',
    },
    'myClasses': {
      'title': 'My Classes',
      'icon': Icons.class_,
      'route': '/my-classes',
    },
    'mySections': {
      'title': 'My Sections',
      'icon': Icons.group,
      'route': '/my-sections',
    },
    'myChildren': {
      'title': 'My Children',
      'icon': Icons.child_care,
      'route': '/my-children',
    },
  };

  static List<Map<String, dynamic>> getSidebarItems(String role) {
    final visibleModules = ModuleVisibility.getVisibleModules(role);
    return visibleModules
        .where((module) => moduleConfig.containsKey(module))
        .map((module) => {
              'module': module,
              'title': moduleConfig[module]!['title'],
              'icon': moduleConfig[module]!['icon'],
              'route': moduleConfig[module]!['route'],
              'permission': ModuleVisibility.getModulePermission(role, module),
            })
        .toList();
  }

  static bool canAccessRoute(String role, String route) {
    final module = moduleConfig.entries
        .firstWhere(
          (entry) => entry.value['route'] == route,
          orElse: () => const MapEntry('', {}),
        )
        .key;
    
    return module.isNotEmpty && ModuleVisibility.isModuleVisible(role, module);
  }
}