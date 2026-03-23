class ModuleVisibility {
  static const Map<String, List<String>> _roleModules = {
    'correspondent': [
      'dashboard',
      'users',
      'schools',
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

  static const Map<String, Map<String, String>> _modulePermissions = {
    'students': {
      'principal': 'readOnly',
      'viceprincipal': 'readOnly',
      'teacher': 'classScopedReadOnly',
      'accountant': 'financeView',
    },
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
    'announcements': {
      'viceprincipal': 'readOnly',
      'teacher': 'readOnly',
      'parent': 'readOnly',
    },
    'financeLedger': {
      'principal': 'readOnly',
    },
  };

  static bool hasModule(String role, String module) {
    return _roleModules[role.toLowerCase()]?.contains(module) ?? false;
  }

  static String getModulePermission(String role, String module) {
    return _modulePermissions[module]?[role.toLowerCase()] ?? 'full';
  }

  static List<String> getVisibleModules(String role) {
    return _roleModules[role.toLowerCase()] ?? [];
  }
}