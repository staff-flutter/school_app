class ModuleVisibility {
  static const Map<String, List<String>> roleModules = {
    'correspondent': [
      'dashboard',
      'users',
      'schools',
      'schoolManagement',
      'classes',
      'sections',
      'teacherAssignments',
      'students',
      'studentRecords',
      'feeStructure',
      'feeCollection',
      'attendance',
      'expenses',
      'announcements',
      'clubs',
      'clubVideos',
      'financeLedger',
      'auditLogs',
      'deleteArchive',
      'subscription',
    ],
    'administrator': [
      'dashboard',
      'users',
      'schoolManagement',
      'classes',
      'sections',
      'teacherAssignments',
      'students',
      'studentRecords',
      'feeStructure',
      'attendance',
      'announcements',
      'clubs',
      'clubVideos',
      'auditLogs',
    ],
    'principal': [
      'dashboard',
      'students',
      'studentRecords',
      'feeStructure',
      'attendance',
      'expenses',
      'announcements',
      'clubs',
      'clubVideos',
      'financeLedger',
    ],
    'viceprincipal': [
      'dashboard',
      'students',
      'attendance',
      'announcements',
      'clubs',
      'clubVideos',
    ],
    'teacher': [
      'dashboard',
      'myClasses',
      'mySections',
      'students',
      'attendance',
      'announcements',
      'clubs',
      'clubVideos',
    ],
    'accountant': [
      'dashboard',
      'students',
      'studentRecords',
      'feeStructure',
      'feeCollection',
      'expenses',
      'financeLedger',
      'clubs',
      'clubVideos',
    ],
    'parent': [
      'dashboard',
      'myChildren',
      'attendance',
      'announcements',
      'clubs',
      'clubVideos',
    ],
  };

  static const Map<String, Map<String, String>> modulePermissions = {
    'studentRecords': {
      'administrator': 'readOnlyExceptAssign',
      'principal': 'viewAndRevert',
      'accountant': 'fullFinance',
    },
    'feeStructure': {
      'principal': 'readOnly',
    },
    'attendance': {
      'principal': 'reportsOnly',
      'viceprincipal': 'reportsOnly',
      'teacher': 'markAndView',
      'parent': 'ownChildrenOnly',
    },
    'expenses': {
      'principal': 'viewOnly',
    },
    'financeLedger': {
      'principal': 'readOnly',
    },
    'announcements': {
      'viceprincipal': 'readOnly',
      'teacher': 'readOnly',
      'parent': 'readOnly',
    },
    'students': {
      'principal': 'readOnly',
      'viceprincipal': 'readOnly',
      'teacher': 'classScopedReadOnly',
      'accountant': 'financeView',
    },
  };

  static const Map<String, List<String>> featureFlags = {
    'allowDeleteButtons': ['correspondent'],
    'allowEditSchool': ['correspondent'],
    'allowFeeCollection': ['correspondent', 'accountant'],
    'allowAttendanceMarking': ['teacher', 'correspondent'],
    'allowRoleAssignment': ['correspondent'],
    'allowExpenseApproval': ['correspondent'],
    'allowAuditView': ['correspondent', 'administrator', 'principal', 'viceprincipal'],
  };

  static bool isModuleVisible(String role, String module) {
    final modules = roleModules[role.toLowerCase()];
    return modules?.contains(module) ?? false;
  }

  static String? getModulePermission(String role, String module) {
    return modulePermissions[module]?[role.toLowerCase()];
  }

  static bool hasFeatureFlag(String role, String feature) {
    final roles = featureFlags[feature];
    return roles?.contains(role.toLowerCase()) ?? false;
  }

  static List<String> getVisibleModules(String role) {
    return roleModules[role.toLowerCase()] ?? [];
  }

  static List<String> getHiddenModules(String role) {
    final visible = getVisibleModules(role);
    final allModules = roleModules['correspondent'] ?? [];
    return allModules.where((module) => !visible.contains(module)).toList();
  }
}