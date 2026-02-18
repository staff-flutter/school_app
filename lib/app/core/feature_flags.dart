class FeatureFlags {
  static const Map<String, List<String>> _featureAccess = {
    'allowDeleteButtons': ['correspondent'],
    'allowEditSchool': ['correspondent'],
    'allowFeeCollection': ['correspondent', 'accountant'],
    'allowAttendanceMarking': ['teacher', 'correspondent'],
    'allowRoleAssignment': ['correspondent'],
    'allowExpenseApproval': ['correspondent'],
    'allowAuditView': ['correspondent', 'administrator', 'principal', 'viceprincipal'],
  };

  static bool hasFeature(String role, String feature) {
    return _featureAccess[feature]?.contains(role.toLowerCase()) ?? false;
  }

  static bool canDelete(String role) => hasFeature(role, 'allowDeleteButtons');
  static bool canEditSchool(String role) => hasFeature(role, 'allowEditSchool');
  static bool canCollectFees(String role) => hasFeature(role, 'allowFeeCollection');
  static bool canMarkAttendance(String role) => hasFeature(role, 'allowAttendanceMarking');
  static bool canAssignRoles(String role) => hasFeature(role, 'allowRoleAssignment');
  static bool canApproveExpenses(String role) => hasFeature(role, 'allowExpenseApproval');
  static bool canViewAudit(String role) => hasFeature(role, 'allowAuditView');
}