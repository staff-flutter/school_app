import 'package:get/get.dart';
import '../../../core/module_visibility.dart';
import '../../../core/feature_flags.dart';

class DashboardController extends GetxController {
  final String role;
  final selectedModule = 'dashboard'.obs;
  final isLoading = false.obs;

  DashboardController([this.role = 'correspondent']);

  String get userRole => role.toLowerCase();
  String get userName => 'Current User';
  String get schoolId => 'school_1';

  List<String> get visibleModules => ModuleVisibility.getVisibleModules(userRole);

  bool hasModule(String module) => ModuleVisibility.hasModule(userRole, module);
  String getModulePermission(String module) => ModuleVisibility.getModulePermission(userRole, module);
  bool hasFeature(String feature) => FeatureFlags.hasFeature(userRole, feature);

  void selectModule(String module) {
    if (hasModule(module)) {
      selectedModule.value = module;
    }
  }

  List<NavigationItem> getNavigationItems() {
    final items = <NavigationItem>[];

    if (hasModule('dashboard')) {
      items.add(NavigationItem('dashboard', 'Dashboard', 'dashboard'));
    }

    if (hasModule('users')) {
      items.add(NavigationItem('users', 'Users', 'people'));
    }

    if (hasModule('schools')) {
      items.add(NavigationItem('schools', 'Schools', 'school'));
    }

    if (hasModule('classes')) {
      items.add(NavigationItem('classes', 'Classes', 'class'));
    }

    if (hasModule('sections')) {
      items.add(NavigationItem('sections', 'Sections', 'group'));
    }

    if (hasModule('teacherAssignments')) {
      items.add(NavigationItem('teacherAssignments', 'Teacher Assignments', 'assignment_ind'));
    }

    if (hasModule('students')) {
      items.add(NavigationItem('students', 'Students', 'person'));
    }

    if (hasModule('myChildren')) {
      items.add(NavigationItem('myChildren', 'My Children', 'child_care'));
    }

    if (hasModule('myClasses')) {
      items.add(NavigationItem('myClasses', 'My Classes', 'class'));
    }

    if (hasModule('mySections')) {
      items.add(NavigationItem('mySections', 'My Sections', 'group'));
    }

    if (hasModule('studentRecords')) {
      items.add(NavigationItem('studentRecords', 'Student Records', 'folder'));
    }

    if (hasModule('feeStructure')) {
      items.add(NavigationItem('feeStructure', 'Fee Structure', 'account_balance'));
    }

    if (hasModule('feeCollection')) {
      items.add(NavigationItem('feeCollection', 'Fee Collection', 'payment'));
    }

    if (hasModule('attendance')) {
      items.add(NavigationItem('attendance', 'Attendance', 'how_to_reg'));
    }

    if (hasModule('expenses')) {
      items.add(NavigationItem('expenses', 'Expenses', 'receipt'));
    }

    if (hasModule('announcements')) {
      items.add(NavigationItem('announcements', 'Announcements', 'announcement'));
    }

    if (hasModule('clubs')) {
      items.add(NavigationItem('clubs', 'Clubs', 'groups'));
    }

    if (hasModule('clubVideos')) {
      items.add(NavigationItem('clubVideos', 'Club Videos', 'video_library'));
    }

    if (hasModule('financeLedger')) {
      items.add(NavigationItem('financeLedger', 'Finance Ledger', 'account_balance_wallet'));
    }

    if (hasModule('auditLogs')) {
      items.add(NavigationItem('auditLogs', 'Audit Logs', 'history'));
    }

    if (hasModule('deleteArchive')) {
      items.add(NavigationItem('deleteArchive', 'Delete Archive', 'delete_forever'));
    }

    if (hasModule('subscription')) {
      items.add(NavigationItem('subscription', 'Subscription', 'card_membership'));
    }

    return items;
  }
}

class NavigationItem {
  final String id;
  final String title;
  final String icon;

  NavigationItem(this.id, this.title, this.icon);

  String get route {
    switch (id) {
      case 'dashboard': return '/dashboard';
      case 'users': return '/users';
      case 'schools': return '/schools';
      case 'classes': return '/classes';
      case 'sections': return '/sections';
      case 'teacherAssignments': return '/teacher-assignments';
      case 'students': return '/students';
      case 'myChildren': return '/my-children';
      case 'myClasses': return '/my-classes';
      case 'mySections': return '/my-sections';
      case 'studentRecords': return '/student-records';
      case 'feeStructure': return '/fee-structure';
      case 'feeCollection': return '/fee-collection';
      case 'attendance': return '/attendance';
      case 'expenses': return '/expenses';
      case 'announcements': return '/announcements';
      case 'clubs': return '/clubs';
      case 'clubVideos': return '/club-videos';
      case 'financeLedger': return '/finance-ledger';
      case 'auditLogs': return '/audit-logs';
      case 'deleteArchive': return '/delete-archive';
      case 'subscription': return '/subscription';
      default: return '/dashboard';
    }
  }
}