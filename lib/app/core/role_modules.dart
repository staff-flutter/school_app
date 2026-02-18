class RoleModules {
  static const Map<String, List<String>> _roleModules = {
    'correspondent': [
      'dashboard', 'users', 'schools', 'schoolManagement', 'classes', 'sections', 'teacherAssignments',
      'students', 'studentRecords', 'feeStructure', 'feeCollection', 'attendance',
      'expenses', 'announcements', 'clubs', 'clubVideos', 'financeLedger',
      'auditLogs', 'deleteArchive', 'subscription','userManagement','reports','transactions'
      'teachers'
    ],
    'administrator': [
      'dashboard', 'users', 'schoolManagement', 'classes', 'sections', 'teacherAssignments',
      'students', 'studentRecords', 'feeStructure', 'attendance',
      'announcements', 'clubs', 'clubVideos', 'auditLogs','userManagement','teachers'
    ],
    'principal': [
      'dashboard', 'students', 'studentRecords', 'feeStructure', 'attendance','transactions','teachers'
      'expenses', 'announcements', 'clubs', 'clubVideos', 'financeLedger','userManagement','reports'
    ],
    'viceprincipal': [
      'reports','dashboard', 'students', 'attendance', 'announcements', 'clubs', 'clubVideos','userManagement'
    ],
    'teacher': [
      'dashboard', 'myClasses', 'mySections', 'students', 'attendance',
      'announcements', 'clubs', 'clubVideos','userManagement'
    ],
    'accountant': [
      'dashboard', 'students', 'studentRecords', 'feeStructure', 'feeCollection',
      'expenses', 'financeLedger', 'clubs', 'clubVideos','reports','transactions'
    ],
    'parent': [
      'dashboard', 'myChildren', 'attendance', 'announcements', 'clubs', 'clubVideos'
    ],
  };

  static List<String> getVisibleModules(String role) {
    return _roleModules[role.toLowerCase()] ?? [];
  }

  static bool hasModule(String role, String module) {
    return getVisibleModules(role).contains(module);
  }

  // Feature flags for specific actions
  static bool allowDeleteButtons(String role) {
    return role.toLowerCase() == 'correspondent';
  }

  static bool allowEditSchool(String role) {
    return role.toLowerCase() == 'correspondent';
  }

  static bool allowFeeCollection(String role) {
    final r = role.toLowerCase();
    return r == 'correspondent' || r == 'accountant';
  }

  static bool allowAttendanceMarking(String role) {
    final r = role.toLowerCase();
    return r == 'teacher' || r == 'correspondent';
  }

  static bool allowRoleAssignment(String role) {
    return role.toLowerCase() == 'correspondent';
  }

  static bool allowExpenseApproval(String role) {
    return role.toLowerCase() == 'correspondent';
  }

  static bool allowAuditView(String role) {
    final r = role.toLowerCase();
    return ['correspondent', 'administrator', 'principal', 'viceprincipal'].contains(r);
  }

  // Module access permissions with read/write levels
  static String getModulePermission(String role, String module) {
    final r = role.toLowerCase();
    
    switch (module) {
      case 'students':
        if (r == 'teacher') return 'classScopedReadOnly';
        if (r == 'accountant') return 'financeView';
        if (['principal', 'viceprincipal'].contains(r)) return 'readOnly';
        return 'full';
      
      case 'studentRecords':
        if (r == 'administrator') return 'readOnlyExceptAssign';
        if (r == 'principal') return 'viewAndRevert';
        if (r == 'accountant') return 'fullFinance';
        return 'full';
      
      case 'feeStructure':
        if (r == 'principal') return 'readOnly';
        return 'full';
      
      case 'attendance':
        if (r == 'teacher') return 'markAndView';
        if (['principal', 'viceprincipal'].contains(r)) return 'reportsOnly';
        if (r == 'parent') return 'ownChildrenOnly';
        return 'full';
      
      case 'expenses':
        if (r == 'principal') return 'viewOnly';
        return 'full';
      
      case 'announcements':
        if (['viceprincipal', 'teacher', 'parent'].contains(r)) return 'readOnly';
        return 'full';
      
      case 'financeLedger':
        if (r == 'principal') return 'readOnly';
        return 'full';
      
      default:
        return 'full';
    }
  }

  // Screen access control
  static bool canAccessScreen(String role, String screenName) {
    final roleModules = getVisibleModules(role);
    
    switch (screenName.toLowerCase()) {
      case 'profileview':
      case 'enhancedprofileview':
        return true; // All roles can access profile
      case 'studentsview':
      case 'studentmanagementview':
        return roleModules.contains('schoolManagement');
      case 'academicsview':
        return roleModules.contains('classes') || roleModules.contains('sections');
      case 'feecollectionview':
        return roleModules.contains('feeCollection');
      case 'expensesview':
        return roleModules.contains('expenses');
      case 'attendanceview':
        return roleModules.contains('attendance');
      case 'communicationsview':
        return roleModules.contains('announcements');
      case 'clubsactivitiesview':
        return roleModules.contains('clubs');
      case 'reportsview':
        return roleModules.contains('financeLedger');
      case 'studentrecordsview':
      case 'student-records':
        return roleModules.contains('studentRecords');
      case 'subscriptionmanagementview':
        return roleModules.contains('subscription');
      case 'schoolmanagementview':
        return roleModules.contains('schoolManagement');

      default:
        return true;
    }
  }
}