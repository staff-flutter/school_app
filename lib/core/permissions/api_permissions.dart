class ApiPermissions {
  static const Map<String, List<String>> _apiRoleAccess = {
    // User APIs
    'POST_/api/user/create': ['correspondent'],
    'POST_/api/user/login': ['anyone'],
    'POST_/api/user/logout': ['anyone'],
    'GET_/api/user/isauthenticated': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'DELETE_/api/user/delete/:id': ['correspondent'],
    'PUT_/api/user/update/:id': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'GET_/api/user/:role/:schoolId': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'PUT_/api/user/assignrole/:userId': ['correspondent', 'administrator'],

    // School APIs
    'POST_/api/school/create': ['correspondent'],
    'GET_/api/school/getall': ['correspondent'],
    'GET_/api/school/getsingle/:id': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'PUT_/api/school/update/:id': ['correspondent'],
    'PUT_/api/school/updatelogo/:id': ['correspondent'],
    'DELETE_/api/school/delete/:id': ['correspondent'],

    // Class APIs
    'GET_/api/class/getall/:schoolId': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'POST_/api/class/create/:schoolId': ['correspondent', 'administrator'],
    'PUT_/api/class/update/:id': ['correspondent', 'administrator'],
    'DELETE_/api/class/delete/:id': ['correspondent', 'administrator'],

    // Section APIs
    'GET_/api/section/getall': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'POST_/api/section/create': ['correspondent', 'administrator'],
    'PUT_/api/section/update/:id': ['correspondent', 'administrator'],
    'DELETE_/api/section/delete/:id': ['correspondent'],

    // Teacher Assignment APIs
    'POST_/api/teacher/assignments/manage': ['correspondent', 'administrator'],
    'GET_/api/teacher/getall/class/section': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal', 'accountant'],

    // Fee Structure APIs
    'POST_/api/feestructure/set': ['correspondent', 'administrator'],
    'GET_/api/feestructure/getbyclass': ['correspondent', 'administrator', 'principal', 'accountant', 'teacher'],

    // Student APIs
    'POST_/api/student/create': ['correspondent', 'administrator', 'accountant'],
    'PUT_/api/student/update/:id': ['correspondent', 'administrator', 'accountant'],
    'DELETE_/api/student/delete/:id': ['correspondent'],
    'GET_/api/student/get/:id': ['correspondent', 'administrator', 'principal', 'accountant', 'teacher'],
    'GET_/api/student/getall': ['correspondent', 'administrator', 'principal', 'accountant', 'teacher'],
    'PUT_/api/student/assignstudent': ['correspondent', 'administrator'],
    'PUT_/api/student/removestudent': ['correspondent', 'administrator'],

    // Student Record APIs
    'POST_/api/studentrecord/applyconcession': ['correspondent', 'accountant', 'principal'],
    'POST_/api/studentrecord/collectfee': ['correspondent', 'accountant'],
    'GET_/api/studentrecord/getrecord/:schoolId/:studentId': ['administrator', 'correspondent', 'principal', 'viceprincipal', 'accountant'],
    'DELETE_/api/studentrecord/deleterecord/:id': ['correspondent'],
    'PATCH_/api/studentrecord/togglestatus/:id': ['administrator', 'correspondent', 'accountant'],
    'PUT_/api/studentrecord/updatevalue': ['correspondent', 'accountant', 'principal'],
    'PUT_/api/studentrecord/update/proof': ['correspondent', 'accountant', 'principal'],
    'PUT_/api/studentrecord/revertreceipt': ['correspondent', 'accountant', 'principal'],
    'GET_/api/studentrecord/getall': ['administrator', 'correspondent', 'principal', 'viceprincipal', 'accountant'],
    'PUT_/api/studentrecord/assign': ['correspondent', 'administrator'],
    'PUT_/api/studentrecord/remove': ['correspondent', 'administrator'],

    // Attendance APIs
    'GET_/api/attendance/sheet': ['administrator', 'correspondent', 'principal', 'teacher'],
    'POST_/api/attendance/mark': ['correspondent', 'teacher'],
    'GET_/api/attendance/getallclass': ['administrator', 'correspondent', 'principal', 'teacher'],
    'GET_/api/attendance/student/:studentId': ['administrator', 'correspondent', 'principal', 'viceprincipal', 'teacher', 'parent'],

    // Expense APIs
    'POST_/api/expense/add': ['correspondent', 'accountant'],
    'GET_/api/expense/getall': ['correspondent', 'accountant', 'principal'],
    'GET_/api/expense/get/:id': ['correspondent', 'accountant', 'principal'],
    'PUT_/api/expense/update/:id': ['correspondent'],
    'PATCH_/api/expense/updatestatus/:id': ['correspondent'],
    'DELETE_/api/expense/delete/:id': ['correspondent'],
    'DELETE_/api/expense/deleteproof': ['correspondent'],

    // Announcement APIs
    'POST_/api/announcement/create': ['correspondent', 'principal', 'administrator'],
    'GET_/api/announcement/getall': ['correspondent', 'principal', 'viceprincipal', 'teacher', 'parent', 'administrator'],
    'GET_/api/announcement/get/:id': ['correspondent', 'administrator', 'viceprincipal', 'principal', 'teacher', 'parent'],
    'PUT_/api/announcement/update/:id': ['correspondent', 'principal', 'administrator'],
    'PUT_/api/announcement/addattachment/:id': ['correspondent', 'principal', 'administrator'],
    'DELETE_/api/announcement/deleteattachment/:id/:fileId': ['correspondent', 'principal', 'administrator'],
    'DELETE_/api/announcement/delete/:id': ['correspondent', 'principal', 'administrator'],

    // Club APIs
    'GET_/api/club/getall': ['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'],
    'GET_/api/club/get/:id': ['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'],
    'POST_/api/club/create': ['correspondent', 'administrator'],
    'PUT_/api/club/updatetext/:id': ['correspondent', 'administrator'],
    'PUT_/api/club/updatethumbnail/:id': ['correspondent', 'administrator'],
    'DELETE_/api/club/delete/:id': ['correspondent', 'administrator'],
    'POST_/api/club/addStudentToClub': ['correspondent', 'administrator'],
    'POST_/api/club/removeStudentFromClub': ['correspondent', 'administrator'],
    'POST_/api/club/toggleStudentsInClub': ['correspondent', 'administrator'],
    'GET_/api/club/video/getall': ['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'],
    'GET_/api/club/video/get/:id': ['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'],
    'POST_/api/club/video/upload': ['correspondent', 'administrator'],
    'PUT_/api/club/video/updatedetails/:id': ['correspondent', 'administrator'],
    'PUT_/api/club/video/updatefile/:id': ['correspondent', 'administrator'],
    'DELETE_/api/club/video/delete/:id': ['correspondent', 'administrator'],

    // Finance Ledger APIs
    'GET_/api/financeledger/getall': ['correspondent', 'accountant', 'principal'],
    'GET_/api/financeledger/get/:id': ['correspondent', 'accountant', 'principal'],
    'GET_/api/financeledger/stats': ['correspondent', 'accountant', 'principal'],
    'GET_/api/financeledger/timeline': ['correspondent', 'accountant', 'principal'],

    // Subscription APIs
    'PUT_/api/subscription/update': ['correspondent'],
    'GET_/api/subscription/get': ['correspondent', 'principal'],

    // Delete Archive APIs
    'GET_/api/deletearchive/getall': ['correspondent', 'accountant', 'principal', 'viceprincipal'],
    'GET_/api/deletearchive/get/:id': ['correspondent', 'accountant', 'principal', 'viceprincipal'],
    'DELETE_/api/deletearchive/delete/:id': ['correspondent'],

    // Audit APIs
    'GET_/api/audit/getall': ['administrator', 'correspondent', 'principal', 'viceprincipal'],
    'GET_/api/audit/get/:id': ['administrator', 'correspondent', 'principal', 'viceprincipal'],
  };

  static bool hasApiAccess(String method, String endpoint, String userRole) {
    final key = '${method}_${endpoint}';
    final allowedRoles = _apiRoleAccess[key] ?? [];

    // Handle 'anyone' role (public access)
    if (allowedRoles.contains('anyone')) {
      return true;
    }

    return allowedRoles.contains(userRole.toLowerCase());
  }

  static List<String> getAllowedApisForRole(String userRole) {
    final allowedApis = <String>[];

    _apiRoleAccess.forEach((api, roles) {
      if (roles.contains('anyone') || roles.contains(userRole.toLowerCase())) {
        allowedApis.add(api);
      }
    });

    return allowedApis;
  }

  // Helper methods for common UI actions
  static bool canCreate(String entity, String userRole) {
    switch (entity) {
      case 'user':
        return hasApiAccess('POST', '/api/user/create', userRole);
      case 'school':
        return hasApiAccess('POST', '/api/school/create', userRole);
      case 'class':
        return hasApiAccess('POST', '/api/class/create/:schoolId', userRole);
      case 'section':
        return hasApiAccess('POST', '/api/section/create', userRole);
      case 'student':
        return hasApiAccess('POST', '/api/student/create', userRole);
      case 'expense':
        return hasApiAccess('POST', '/api/expense/add', userRole);
      case 'announcement':
        return hasApiAccess('POST', '/api/announcement/create', userRole);
      case 'club':
        return hasApiAccess('POST', '/api/club/create', userRole);
      default:
        return false;
    }
  }

  static bool canUpdate(String entity, String userRole) {
    switch (entity) {
      case 'user':
        return hasApiAccess('PUT', '/api/user/update/:id', userRole);
      case 'school':
        return hasApiAccess('PUT', '/api/school/update/:id', userRole);
      case 'schoolLogo':
        return hasApiAccess('PUT', '/api/school/updatelogo/:id', userRole);
      case 'class':
        return hasApiAccess('PUT', '/api/class/update/:id', userRole);
      case 'section':
        return hasApiAccess('PUT', '/api/section/update/:id', userRole);
      case 'student':
        return hasApiAccess('PUT', '/api/student/update/:id', userRole);
      case 'expense':
        return hasApiAccess('PUT', '/api/expense/update/:id', userRole);
      case 'announcement':
        return hasApiAccess('PUT', '/api/announcement/update/:id', userRole);
      case 'club':
        return hasApiAccess('PUT', '/api/club/updatetext/:id', userRole);
      case 'subscription':
        return hasApiAccess('PUT', '/api/subscription/update', userRole);
      default:
        return false;
    }
  }

  static bool canDelete(String entity, String userRole) {
    switch (entity) {
      case 'user':
        return hasApiAccess('DELETE', '/api/user/delete/:id', userRole);
      case 'school':
        return hasApiAccess('DELETE', '/api/school/delete/:id', userRole);
      case 'class':
        return hasApiAccess('DELETE', '/api/class/delete/:id', userRole);
      case 'section':
        return hasApiAccess('DELETE', '/api/section/delete/:id', userRole);
      case 'student':
        return hasApiAccess('DELETE', '/api/student/delete/:id', userRole);
      case 'expense':
        return hasApiAccess('DELETE', '/api/expense/delete/:id', userRole);
      case 'announcement':
        return hasApiAccess('DELETE', '/api/announcement/delete/:id', userRole);
      case 'club':
        return hasApiAccess('DELETE', '/api/club/delete/:id', userRole);
      case 'archive':
        return hasApiAccess('DELETE', '/api/deletearchive/delete/:id', userRole);
      default:
        return false;
    }
  }

  static bool canView(String entity, String userRole) {
    switch (entity) {
      case 'user':
        return hasApiAccess('GET', '/api/user/:role/:schoolId', userRole);
      case 'school':
        return hasApiAccess('GET', '/api/school/getsingle/:id', userRole);
      case 'schools':
        return hasApiAccess('GET', '/api/school/getall', userRole);
      case 'class':
        return hasApiAccess('GET', '/api/class/getall/:schoolId', userRole);
      case 'section':
        return hasApiAccess('GET', '/api/section/getall', userRole);
      case 'student':
        return hasApiAccess('GET', '/api/student/get/:id', userRole);
      case 'students':
        return hasApiAccess('GET', '/api/student/getall', userRole);
      case 'expense':
        return hasApiAccess('GET', '/api/expense/get/:id', userRole);
      case 'expenses':
        return hasApiAccess('GET', '/api/expense/getall', userRole);
      case 'announcement':
        return hasApiAccess('GET', '/api/announcement/get/:id', userRole);
      case 'announcements':
        return hasApiAccess('GET', '/api/announcement/getall', userRole);
      case 'club':
        return hasApiAccess('GET', '/api/club/get/:id', userRole);
      case 'clubs':
        return hasApiAccess('GET', '/api/club/getall', userRole);
      case 'clubVideos':
        return hasApiAccess('GET', '/api/club/video/getall', userRole);
      case 'financeLedger':
        return hasApiAccess('GET', '/api/financeledger/getall', userRole);
      case 'auditLogs':
        return hasApiAccess('GET', '/api/audit/getall', userRole);
      case 'deleteArchive':
        return hasApiAccess('GET', '/api/deletearchive/getall', userRole);
      case 'subscription':
        return hasApiAccess('GET', '/api/subscription/get', userRole);
      case 'feeStructure':
        return hasApiAccess('GET', '/api/feestructure/getbyclass', userRole);
      default:
        return false;
    }
  }

  static bool canMarkAttendance(String userRole) {
    return hasApiAccess('POST', '/api/attendance/mark', userRole);
  }

  static bool canCollectFees(String userRole) {
    return hasApiAccess('POST', '/api/studentrecord/collectfee', userRole);
  }

  static bool canViewAttendance(String userRole) {
    return hasApiAccess('GET', '/api/attendance/sheet', userRole);
  }

  static bool canManageTeacherAssignments(String userRole) {
    return hasApiAccess('POST', '/api/teacher/assignments/manage', userRole);
  }

  static bool canSetFeeStructure(String userRole) {
    return hasApiAccess('POST', '/api/feestructure/set', userRole);
  }
}

