class ApiPermissions {
  // Map each API to its allowed roles based on your specification
  static const Map<String, List<String>> apiRoles = {
    // User APIs
    'POST /api/user/create': ['correspondent', 'administrator', 'principal', 'viceprincipal', 'teacher', 'accountant', 'parent'],
    'POST /api/user/login': ['anyone'],
    'POST /api/user/logout': ['anyone'],
    'GET /api/user/isauthenticated': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'DELETE /api/user/delete': ['correspondent'],
    'PUT /api/user/update': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'GET /api/user/role': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'PUT /api/user/assignrole': ['correspondent', 'administrator'],
    
    // School APIs
    'POST /api/school/create': ['correspondent'],
    'GET /api/school/getall': ['correspondent'],
    'GET /api/school/getsingle': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'PUT /api/school/update': ['correspondent'],
    'PUT /api/school/updatelogo': ['correspondent'],
    'DELETE /api/school/delete': ['correspondent'],
    
    // Class APIs
    'GET /api/class/getall': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'POST /api/class/create': ['correspondent', 'administrator'],
    'PUT /api/class/update': ['correspondent', 'administrator'],
    'DELETE /api/class/delete': ['correspondent', 'administrator'],
    
    // Section APIs
    'GET /api/section/getall': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
    'POST /api/section/create': ['correspondent', 'administrator'],
    'PUT /api/section/update': ['correspondent', 'administrator'],
    'DELETE /api/section/delete': ['correspondent'], // ONLY correspondent
    
    // Teacher APIs
    'POST /api/teacher/assignments/manage': ['correspondent', 'administrator'],
    'GET /api/teacher/getall': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal', 'accountant'],
    
    // Fee Structure APIs
    'POST /api/feestructure/set': ['correspondent', 'administrator'],
    'GET /api/feestructure/getbyclass': ['correspondent', 'administrator', 'principal', 'accountant', 'teacher'],
    
    // Student APIs
    'POST /api/student/create': ['correspondent', 'administrator', 'accountant'],
    'PUT /api/student/update': ['correspondent', 'administrator', 'accountant'],
    'DELETE /api/student/delete': ['correspondent'], // ONLY correspondent
    'GET /api/student/get': ['correspondent', 'administrator', 'principal', 'accountant', 'teacher'],
    'GET /api/student/getall': ['correspondent', 'administrator', 'principal', 'accountant', 'teacher'],
    'PUT /api/student/assignstudent': ['correspondent', 'administrator'],
    'PUT /api/student/removestudent': ['correspondent', 'administrator'],
    
    // Student Record APIs
    'POST /api/studentrecord/applyconcession': ['correspondent', 'accountant', 'principal'],
    'POST /api/studentrecord/collectfee': ['correspondent', 'accountant'], // NOT principal
    'GET /api/studentrecord/getrecord': ['administrator', 'correspondent', 'principal', 'viceprincipal', 'accountant'],
    'DELETE /api/studentrecord/deleterecord': ['correspondent'],
    'PATCH /api/studentrecord/togglestatus': ['administrator', 'correspondent', 'accountant'],
    'PUT /api/studentrecord/updatevalue': ['correspondent', 'accountant', 'principal'], // Administrator NOT allowed
    'PUT /api/studentrecord/update/proof': ['correspondent', 'accountant', 'principal'],
    'PUT /api/studentrecord/revertreceipt': ['correspondent', 'accountant', 'principal'],
    'GET /api/studentrecord/getall': ['administrator', 'correspondent', 'principal', 'viceprincipal', 'accountant'],
    'PUT /api/studentrecord/assign': ['correspondent', 'administrator'],
    'PUT /api/studentrecord/remove': ['correspondent', 'administrator'],
    
    // Attendance APIs
    'GET /api/attendance/sheet': ['administrator', 'correspondent', 'principal', 'teacher'],
    'POST /api/attendance/mark': ['correspondent', 'teacher'], // NOT principal, administrator, viceprincipal
    'GET /api/attendance/getallclass': ['administrator', 'correspondent', 'principal', 'teacher'],
    'GET /api/attendance/student': ['administrator', 'correspondent', 'principal', 'viceprincipal', 'teacher', 'parent'],
    
    // Expense APIs
    'POST /api/expense/add': ['correspondent', 'accountant'],
    'GET /api/expense/getall': ['correspondent', 'accountant', 'principal'],
    'GET /api/expense/get': ['correspondent', 'accountant', 'principal'],
    'PUT /api/expense/update': ['correspondent'], // ONLY correspondent
    'PATCH /api/expense/updatestatus': ['correspondent'], // ONLY correspondent
    'DELETE /api/expense/delete': ['correspondent'], // ONLY correspondent
    'DELETE /api/expense/deleteproof': ['correspondent'], // ONLY correspondent
    
    // Announcement APIs
    'POST /api/announcement/create': ['correspondent', 'principal', 'administrator'],
    'GET /api/announcement/getall': ['correspondent', 'principal', 'viceprincipal', 'teacher', 'parent', 'administrator'],
    'GET /api/announcement/get': ['correspondent', 'administrator', 'viceprincipal', 'principal', 'teacher', 'parent'],
    'PUT /api/announcement/update': ['correspondent', 'principal', 'administrator'],
    'PUT /api/announcement/addattachment': ['correspondent', 'principal', 'administrator'],
    'DELETE /api/announcement/deleteattachment': ['correspondent', 'principal', 'administrator'],
    'DELETE /api/announcement/delete': ['correspondent', 'principal', 'administrator'],
    
    // Club APIs
    'GET /api/club/getall': ['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'],
    'GET /api/club/get': ['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'],
    'POST /api/club/create': ['correspondent', 'administrator'],
    'PUT /api/club/updatetext': ['correspondent', 'administrator'],
    'PUT /api/club/updatethumbnail': ['correspondent', 'administrator'],
    'PUT /api/club/addtoclub': ['correspondent', 'administrator'],
    'PUT /api/club/removefromclub': ['correspondent', 'administrator'],
    'DELETE /api/club/delete': ['correspondent', 'administrator'],
    
    // Club Video APIs
    'GET /api/club/video/getall': ['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'],
    'GET /api/club/video/get': ['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'],
    'POST /api/club/video/upload': ['correspondent', 'administrator'],
    'PUT /api/club/video/updatedetails': ['correspondent', 'administrator'],
    'PUT /api/club/video/updatefile': ['correspondent', 'administrator'],
    'DELETE /api/club/video/delete': ['correspondent', 'administrator'],
    
    // Finance Ledger APIs
    'GET /api/financeledger/getall': ['correspondent', 'accountant', 'principal'],
    'GET /api/financeledger/get': ['correspondent', 'accountant', 'principal'],
    'GET /api/financeledger/stats': ['correspondent', 'accountant', 'principal'],
    'GET /api/financeledger/timeline': ['correspondent', 'accountant', 'principal'],
    
    // Subscription APIs
    'PUT /api/subscription/update': ['correspondent'], // ONLY correspondent
    'GET /api/subscription/get': ['correspondent', 'principal'],
    
    // Delete Archive APIs
    'GET /api/deletearchive/getall': ['correspondent', 'accountant', 'principal', 'viceprincipal'],
    'GET /api/deletearchive/get': ['correspondent', 'accountant', 'principal', 'viceprincipal'],
    'DELETE /api/deletearchive/delete': ['correspondent'], // ONLY correspondent
    
    // Audit APIs
    'GET /api/audit/getall': ['administrator', 'correspondent', 'principal', 'viceprincipal'],
    'GET /api/audit/get': ['administrator', 'correspondent', 'principal', 'viceprincipal'],
    
    // Timetable APIs
    'POST /api/timetable/addday': ['administrator', 'correspondent'],
    'PUT /api/timetable/updateday': ['correspondent', 'administrator'],
    'DELETE /api/timetable/deleteday': ['correspondent', 'administrator'],
    'PUT /api/timetable/updateperiod': ['administrator', 'correspondent'],
    'DELETE /api/timetable/deleteperiod': ['administrator', 'correspondent'],
    'GET /api/timetable/getall': ['correspondent', 'administrator', 'principal', 'viceprincipal', 'teacher', 'parent', 'accountant'],
    'GET /api/timetable/teacherschedule': ['correspondent', 'administrator', 'principal', 'viceprincipal', 'teacher'],
    'PUT /api/timetable/assignteacher': ['correspondent', 'administrator', 'principal'],
    'DELETE /api/timetable/delete/:id': ['correspondent', 'administrator', 'principal'],
    
    // Homework APIs
    'POST /api/homework/create': ['correspondent', 'teacher'],
    'PUT /api/homework/updatetext': ['correspondent', 'teacher'],
    'PUT /api/homework/addattachments': ['correspondent', 'teacher'],
    'DELETE /api/homework/deleteattachment': ['correspondent', 'teacher'],
    'DELETE /api/homework/deletesubject': ['correspondent', 'teacher'],
    'GET /api/homework/getall': ['correspondent', 'administrator', 'principal', 'viceprincipal', 'teacher', 'parent', 'accountant'],
    'GET /api/homework/getsingle/:homeworkId': ['correspondent', 'administrator', 'principal', 'viceprincipal', 'teacher', 'parent', 'accountant'],
    'DELETE /api/homework/deleteentireday': ['correspondent', 'teacher'],
  };
  
  static bool hasApiAccess(String userRole, String apiKey) {
    final allowedRoles = apiRoles[apiKey] ?? [];
    return allowedRoles.contains(userRole.toLowerCase()) || allowedRoles.contains('anyone');
  }
  
  static bool hasRoleAccess(String userRole, List<String> allowedRoles) {
    return allowedRoles.contains(userRole.toLowerCase());
  }
  
  // Helper methods for common button checks
  static bool canCreateStudent(String userRole) => hasApiAccess(userRole, 'POST /api/student/create');
  static bool canUpdateStudent(String userRole) => hasApiAccess(userRole, 'PUT /api/student/update');
  static bool canDeleteStudent(String userRole) => hasApiAccess(userRole, 'DELETE /api/student/delete');
  static bool canCollectFee(String userRole) => hasApiAccess(userRole, 'POST /api/studentrecord/collectfee');
  static bool canMarkAttendance(String userRole) => hasApiAccess(userRole, 'POST /api/attendance/mark');
  static bool canCreateClass(String userRole) => hasApiAccess(userRole, 'POST /api/class/create');
  static bool canDeleteClass(String userRole) => hasApiAccess(userRole, 'DELETE /api/class/delete');
  static bool canCreateSection(String userRole) => hasApiAccess(userRole, 'POST /api/section/create');
  static bool canDeleteSection(String userRole) => hasApiAccess(userRole, 'DELETE /api/section/delete');
  static bool canUpdateExpense(String userRole) => hasApiAccess(userRole, 'PUT /api/expense/update');
  static bool canDeleteExpense(String userRole) => hasApiAccess(userRole, 'DELETE /api/expense/delete');
  static bool canUpdateConcessionValue(String userRole) => hasApiAccess(userRole, 'PUT /api/studentrecord/updatevalue');
  
  // Timetable helper methods
  static bool canManageTimetable(String userRole) => hasApiAccess(userRole, 'POST /api/timetable/addday');
  static bool canViewTimetable(String userRole) => hasApiAccess(userRole, 'GET /api/timetable/getall');
  
  // Homework helper methods
  static bool canCreateHomework(String userRole) => hasApiAccess(userRole, 'POST /api/homework/create');
  static bool canViewHomework(String userRole) => hasApiAccess(userRole, 'GET /api/homework/getall');
  
  // Announcement helper methods
  static bool canCreateAnnouncement(String userRole) => hasApiAccess(userRole, 'POST /api/announcement/create');
  static bool canViewAnnouncement(String userRole) => hasApiAccess(userRole, 'GET /api/announcement/getall');
  
  // School dropdown access
  static bool canSelectSchool(String userRole) => userRole.toLowerCase() == 'correspondent';
  static bool isSchoolReadOnly(String userRole) => !canSelectSchool(userRole);
  
  // Section access
  static bool hasSectionAccess(String userRole) {
    final role = userRole.toLowerCase();
    return ['correspondent', 'administrator', 'principal', 'viceprincipal', 'teacher', 'accountant'].contains(role);
  }
}

class RoleBasedAccess {
  static Map<String, dynamic> getModuleAccess(String userRole) {
    final role = userRole.toLowerCase();
    
    switch (role) {
      case 'correspondent':
        return {
          'visibleModules': [
            'dashboard', 'users', 'schools', 'classes', 'sections', 
            'teacherAssignments', 'students', 'studentRecords', 
            'feeStructure', 'feeCollection', 'attendance', 'expenses', 
            'announcements', 'clubs', 'clubVideos', 'financeLedger', 
            'auditLogs', 'deleteArchive', 'subscription', 'timetable', 'homework'
          ],
          'hiddenModules': [],
          'permissions': {
            'canCreate': true,
            'canUpdate': true,
            'canDelete': true,
            'canView': true,
            'canManageUsers': true,
            'canManageSchools': true,
            'canCollectFees': true,
            'canMarkAttendance': true,
            'canManageExpenses': true,
            'canViewFinancials': true,
          }
        };
        
      case 'administrator':
        return {
          'visibleModules': [
            'dashboard', 'users', 'classes', 'sections', 
            'teacherAssignments', 'students', 'studentRecords', 
            'feeStructure', 'attendance', 'announcements', 
            'clubs', 'clubVideos', 'auditLogs', 'timetable', 'homework'
          ],
          'hiddenModules': [
            'schools', 'expenses', 'financeLedger', 
            'subscription', 'deleteArchive', 'feeCollection'
          ],
          'permissions': {
            'canCreate': true,
            'canUpdate': true,
            'canDelete': false, // Limited delete access
            'canView': true,
            'canManageUsers': true,
            'canManageSchools': false,
            'canCollectFees': false,
            'canMarkAttendance': false,
            'canManageExpenses': false,
            'canViewFinancials': false,
            'canUpdateConcessionValue': false, // Key restriction
          }
        };
        
      case 'principal':
        return {
          'visibleModules': [
            'dashboard', 'students', 'studentRecords', 
            'feeStructure', 'attendance', 'expenses', 
            'announcements', 'clubs', 'clubVideos', 'financeLedger', 'timetable', 'homework'
          ],
          'hiddenModules': [
            'users', 'schools', 'classes', 'sections', 
            'teacherAssignments', 'feeCollection', 
            'subscription', 'deleteArchive', 'auditLogs'
          ],
          'permissions': {
            'canCreate': false,
            'canUpdate': false,
            'canDelete': false,
            'canView': true,
            'canManageUsers': false,
            'canManageSchools': false,
            'canCollectFees': false,
            'canMarkAttendance': false,
            'canManageExpenses': false,
            'canViewFinancials': true,
            'canUpdateConcessionValue': true,
            'canRevertReceipts': true,
          }
        };
        
      case 'viceprincipal':
        return {
          'visibleModules': [
            'dashboard', 'students', 'attendance', 
            'announcements', 'clubs', 'clubVideos', 'timetable', 'homework'
          ],
          'hiddenModules': [
            'users', 'schools', 'classes', 'sections', 
            'teacherAssignments', 'feeStructure', 'studentRecords', 
            'expenses', 'financeLedger', 'subscription', 
            'deleteArchive', 'auditLogs', 'feeCollection'
          ],
          'permissions': {
            'canCreate': false,
            'canUpdate': false,
            'canDelete': false,
            'canView': true,
            'canManageUsers': false,
            'canManageSchools': false,
            'canCollectFees': false,
            'canMarkAttendance': false,
            'canManageExpenses': false,
            'canViewFinancials': false,
          }
        };
        
      case 'teacher':
        return {
          'visibleModules': [
            'dashboard', 'myClasses', 'mySections', 
            'students', 'attendance', 'announcements', 
            'clubs', 'clubVideos', 'timetable', 'homework'
          ],
          'hiddenModules': [
            'users', 'schools', 'classes', 'sections', 
            'teacherAssignments', 'feeStructure', 'studentRecords', 
            'expenses', 'financeLedger', 'subscription', 
            'deleteArchive', 'auditLogs', 'feeCollection'
          ],
          'permissions': {
            'canCreate': false,
            'canUpdate': false,
            'canDelete': false,
            'canView': true,
            'canManageUsers': false,
            'canManageSchools': false,
            'canCollectFees': false,
            'canMarkAttendance': true,
            'canManageExpenses': false,
            'canViewFinancials': false,
          }
        };
        
      case 'accountant':
        return {
          'visibleModules': [
            'dashboard', 'students', 'studentRecords', 
            'feeStructure', 'feeCollection', 'expenses', 
            'financeLedger', 'clubs', 'clubVideos', 'homework'
          ],
          'hiddenModules': [
            'users', 'schools', 'classes', 'sections', 
            'teacherAssignments', 'attendance', 'announcements', 
            'subscription', 'deleteArchive', 'auditLogs'
          ],
          'permissions': {
            'canCreate': true,
            'canUpdate': true,
            'canDelete': false,
            'canView': true,
            'canManageUsers': false,
            'canManageSchools': false,
            'canCollectFees': true,
            'canMarkAttendance': false,
            'canManageExpenses': true,
            'canViewFinancials': true,
            'canUpdateConcessionValue': true,
          }
        };
        
      case 'parent':
        return {
          'visibleModules': [
            'dashboard', 'myChildren', 'attendance', 
            'announcements', 'clubs', 'clubVideos', 'timetable', 'homework'
          ],
          'hiddenModules': [
            'users', 'schools', 'classes', 'sections', 
            'teacherAssignments', 'students', 'studentRecords', 
            'feeStructure', 'feeCollection', 'expenses', 
            'financeLedger', 'subscription', 'deleteArchive', 'auditLogs'
          ],
          'permissions': {
            'canCreate': false,
            'canUpdate': false,
            'canDelete': false,
            'canView': true,
            'canManageUsers': false,
            'canManageSchools': false,
            'canCollectFees': false,
            'canMarkAttendance': false,
            'canManageExpenses': false,
            'canViewFinancials': false,
          }
        };
        
      default:
        return {
          'visibleModules': [],
          'hiddenModules': ['all'],
          'permissions': {}
        };
    }
  }
}