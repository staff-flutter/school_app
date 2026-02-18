class Permission {
  static const String FEES_COLLECT = 'FEES:COLLECT';
  static const String FEES_CANCEL_RECEIPT = 'FEES:CANCEL_RECEIPT';
  static const String FEES_VIEW_REPORTS = 'FEES:VIEW_REPORTS';
  static const String FEES_VIEW_OWN_PAYMENTS = 'FEES:VIEW_OWN_PAYMENTS';
  
  static const String EXPENSE_ADD = 'EXPENSE:ADD';
  static const String EXPENSE_VERIFY = 'EXPENSE:VERIFY';
  static const String EXPENSE_DELETE = 'EXPENSE:DELETE';
  static const String EXPENSE_VIEW = 'EXPENSE:VIEW';
  
  static const String CONCESSION_APPLY_WITH_PROOF = 'CONCESSION:APPLY_WITH_PROOF';
  static const String CONCESSION_APPLY_OVERRIDE = 'CONCESSION:APPLY_OVERRIDE';
  
  static const String REPORTS_VIEW_FINANCIAL = 'REPORTS:VIEW_FINANCIAL';
  
  static const String STUDENTS_VIEW = 'STUDENTS:VIEW';
  static const String STUDENTS_CREATE_EDIT = 'STUDENTS:CREATE_EDIT';
  
  static const String ATTENDANCE_MARK = 'ATTENDANCE:MARK';
  static const String ATTENDANCE_VIEW = 'ATTENDANCE:VIEW';
  
  static const String CLASSES_CONFIGURE = 'CLASSES:CONFIGURE';
  
  static const String NOTICES_CREATE = 'NOTICES:CREATE';
  static const String NOTICES_VIEW = 'NOTICES:VIEW';
  
  static const String CLUBS_CREATE = 'CLUBS:CREATE';
  static const String CLUBS_EDIT = 'CLUBS:EDIT';
  static const String CLUBS_DELETE = 'CLUBS:DELETE';
  static const String CLUBS_VIEW = 'CLUBS:VIEW';
  static const String CLUBS_UPLOAD_VIDEO = 'CLUBS:UPLOAD_VIDEO';
}

class RolePermissions {
  static const Map<String, List<String>> _rolePermissions = {
    'correspondent': [
      // Full access - Super Admin
      Permission.FEES_COLLECT,
      Permission.FEES_CANCEL_RECEIPT,
      Permission.FEES_VIEW_REPORTS,
      Permission.EXPENSE_ADD,
      Permission.EXPENSE_VERIFY,
      Permission.EXPENSE_DELETE,
      Permission.EXPENSE_VIEW,
      Permission.CONCESSION_APPLY_WITH_PROOF,
      Permission.CONCESSION_APPLY_OVERRIDE,
      Permission.REPORTS_VIEW_FINANCIAL,
      Permission.STUDENTS_VIEW,
      Permission.STUDENTS_CREATE_EDIT,
      Permission.ATTENDANCE_MARK,
      Permission.ATTENDANCE_VIEW,
      Permission.CLASSES_CONFIGURE,
      Permission.NOTICES_CREATE,
      Permission.NOTICES_VIEW,
      Permission.CLUBS_CREATE,
      Permission.CLUBS_EDIT,
      Permission.CLUBS_DELETE,
      Permission.CLUBS_VIEW,
      Permission.CLUBS_UPLOAD_VIDEO,
    ],
    
    'principal': [
      // Academic + financial oversight (read-only)
      Permission.FEES_VIEW_REPORTS,
      Permission.EXPENSE_VIEW,
      Permission.REPORTS_VIEW_FINANCIAL,
      Permission.STUDENTS_VIEW,
      Permission.ATTENDANCE_VIEW,
      Permission.NOTICES_CREATE,
      Permission.NOTICES_VIEW,
      Permission.CLUBS_VIEW,
    ],
    
    'viceprincipal': [
      // Academic operations + limited financial visibility
      Permission.STUDENTS_VIEW,
      Permission.ATTENDANCE_MARK,
      Permission.ATTENDANCE_VIEW,
      Permission.NOTICES_VIEW,
      Permission.CLUBS_VIEW,
    ],
    
    'administrator': [
      // System & academic admin
      Permission.STUDENTS_VIEW,
      Permission.STUDENTS_CREATE_EDIT,
      Permission.CLASSES_CONFIGURE,
      Permission.FEES_VIEW_REPORTS,
      Permission.REPORTS_VIEW_FINANCIAL,
      Permission.NOTICES_CREATE,
      Permission.NOTICES_VIEW,
      Permission.CLUBS_CREATE,
      Permission.CLUBS_EDIT,
      Permission.CLUBS_DELETE,
      Permission.CLUBS_VIEW,
      Permission.CLUBS_UPLOAD_VIDEO,
      Permission.ATTENDANCE_VIEW,
    ],
    
    'accountant': [
      // Finance execution
      Permission.FEES_COLLECT,
      Permission.EXPENSE_ADD,
      Permission.EXPENSE_VIEW,
      Permission.CONCESSION_APPLY_WITH_PROOF,
      Permission.NOTICES_VIEW,
      Permission.CLUBS_VIEW,
    ],
    
    'teacher': [
      // Academic execution
      Permission.ATTENDANCE_MARK,
      Permission.ATTENDANCE_VIEW,
      Permission.STUDENTS_VIEW,
      Permission.NOTICES_VIEW,
      Permission.CLUBS_VIEW,
    ],
    
    'student': [
      // Read-only
      Permission.FEES_VIEW_OWN_PAYMENTS,
      Permission.NOTICES_VIEW,
      Permission.CLUBS_VIEW,
    ],
    
    'parent': [
      // Read-only
      Permission.FEES_VIEW_OWN_PAYMENTS,
      Permission.NOTICES_VIEW,
      Permission.CLUBS_VIEW,
    ],
  };

  static bool hasPermission(String role, String permission) {
    final permissions = _rolePermissions[role.toLowerCase()] ?? [];
    return permissions.contains(permission);
  }

  static List<String> getPermissions(String role) {
    return _rolePermissions[role.toLowerCase()] ?? [];
  }

  static bool requiresOTP(String role) {
    // Only correspondent doesn't require OTP according to requirements
    return role.toLowerCase() != 'correspondent';
  }
}