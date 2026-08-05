/// Centralized EB-module role permissions, derived exactly from the API spec (PDF).
///
/// Per the spec, create/update/delete share the same role set within each
///  Principal has full create/update/delete rights
/// alongside Correspondent and Administrator.
class EBPermissions {
  EBPermissions._();

  static String _norm(String? role) =>
      (role ?? '').toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');

  // ==== Premises ====
  // Create/update/delete per spec (226, 227, 228): correspondent, administrator, principal
  static const _premisesEdit = {'correspondent', 'administrator', 'principal'};
  // View per spec (225, 225A, 229): accountant, correspondent, administrator, principal, viceprincipal, teacher
  static const _premisesView = {
    'accountant', 'correspondent', 'administrator', 'principal', 'viceprincipal', 'teacher'
  };
  static bool canViewPremises(String? role) => _premisesView.contains(_norm(role));
  static bool canEditPremises(String? role) => _premisesEdit.contains(_norm(role));
  static bool canDeletePremises(String? role) => _premisesEdit.contains(_norm(role));

  // ==== EB Log ====
  // Create/update/delete per spec (232, 233, 234): correspondent, administrator, principal, accountant
  static const _ebLogEdit = {'correspondent', 'administrator', 'principal', 'accountant'};
  // View per spec (230, 231): correspondent, administrator, principal, viceprincipal, accountant
  static const _ebLogView = {
    'correspondent', 'administrator', 'principal', 'viceprincipal', 'accountant'
  };
  static bool canViewEBLogs(String? role) => _ebLogView.contains(_norm(role));
  static bool canEditEBLogs(String? role) => _ebLogEdit.contains(_norm(role));
  static bool canDeleteEBLogs(String? role) => _ebLogEdit.contains(_norm(role));

  // ==== Analytics / Dashboard ====
  // Per spec (235–238A): correspondent, administrator, principal, accountant
  static const _analyticsView = {'correspondent', 'administrator', 'principal', 'accountant'};
  static bool canViewAnalytics(String? role) => _analyticsView.contains(_norm(role));

  // ==== Tariff ====
  // Create/update/delete per spec (241, 242, 243): correspondent, administrator, principal, accountant
  static const _tariffEdit = {'correspondent', 'administrator', 'principal', 'accountant'};
  // View per spec (239, 240): correspondent, administrator, principal, viceprincipal, accountant
  static const _tariffView = {
    'correspondent', 'administrator', 'principal', 'viceprincipal', 'accountant'
  };
  static bool canViewTariffs(String? role) => _tariffView.contains(_norm(role));
  static bool canEditTariffs(String? role) => _tariffEdit.contains(_norm(role));
  static bool canDeleteTariffs(String? role) => _tariffEdit.contains(_norm(role));
}