class ApiConstants {
  static const String baseUrl = 'https://dailygrades.com';

  // Auth Endpoints
  static const String login            = '/api/user/login';
  static const String logout           = '/api/user/logout';
  static const String isAuthenticated  = '/api/user/isauthenticated';
  static const String createUser       = '/api/user/create';
  static const String deleteUser       = '/api/user/delete';
  static const String updateUser       = '/api/user/update';
  static const String getUsersByRole   = '/api/user';
  static const String assignRole       = '/api/user/assignrole';

  // School Endpoints
  static const String createSchool     = '/api/school/create';
  static const String getAllSchools    = '/api/school/getall';
  static const String getSingleSchool  = '/api/school/getsingle';
  static const String updateSchool     = '/api/school/update';
  static const String updateSchoolLogo = '/api/school/updatelogo';
  static const String deleteSchool     = '/api/school/delete';

  // Class Endpoints
  static const String getAllClasses = '/api/class/getall';
  static const String createClass  = '/api/class/create';
  static const String updateClass  = '/api/class/update';
  static const String deleteClass  = '/api/class/delete';

  // Section Endpoints
  static const String getAllSections = '/api/section/getall';
  static const String createSection  = '/api/section/create';
  static const String updateSection  = '/api/section/update';
  static const String deleteSection  = '/api/section/delete';

  // Teacher Assignment Endpoints
  static const String manageTeacherAssignments = '/api/teacher/assignments/manage';

  // Attendance Endpoints
  static const String getAttendanceSheet  = '/api/attendance/sheet';
  static const String markAttendance      = '/api/attendance/mark';
  static const String getClassAttendance  = '/api/attendance/getallclass';

  // Student Endpoints
  static const String getAllStudents = '/api/student/getall';
  static const String createStudent  = '/api/student/create';
  static const String updateStudent  = '/api/student/update';
  static const String deleteStudent  = '/api/student/delete';
  static const String getStudent     = '/api/student/get';

  // Student File Operations (v1)
  // POST   /api/student/v1/upload-files/:studentId   — field name: "files"
  // DELETE /api/student/v1/delete-document/:studentId/:documentId
  static const String uploadStudentFiles    = '/api/student/v1/upload-files';
  static const String deleteStudentDocument = '/api/student/v1/delete-document';

  // Dashboard Endpoints
  static const String accountingDashboard = '/api/accounting/dashboard';

  // Fee Structure Endpoints
  static const String setFeeStructure = '/api/feestructure/set';
  static const String getFeeStructure = '/api/feestructure/getbyclass';

  // Student Record Endpoints
  static const String applyConcession      = '/api/studentrecord/applyconcession';
  static const String collectFee           = '/api/studentrecord/collectfee';
  static const String getStudentRecord     = '/api/studentrecord/getrecord';
  static const String deleteStudentRecord  = '/api/studentrecord/deleterecord';
  static const String toggleStudentStatus  = '/api/studentrecord/togglestatus';
  static const String updateConcessionValue = '/api/studentrecord/updatevalue';
  static const String updateConcessionProof = '/api/studentrecord/update/proof';
  static const String getDues              = '/api/accounting/fees/dues';
  static const String revertReceipt        = '/api/studentrecord/revertreceipt';
  static const String getTransactionHistory = '/api/accounting/fees/history';
  static const String getStudentRecords    = '/api/studentrecord/getall';
  static const String getStudentsByClass   = '/api/student/getbyclass';

  // Student Record Endpoints (v1)
  // GET /api/studentrecord/v1/getrecord/:schoolId/:studentId
  //   — single student record; also returns profile image + uploaded documents
  // GET /api/studentrecord/v1/getall
  //   — paginated list of student records with filters (schoolId, page, limit,
  //     search, academicYear, classId, sectionId, isActive, isBusApplicable,
  //     isFullyPaid)
  static const String getStudentRecordV1     = '/api/studentrecord/v1/getrecord';
  static const String getAllStudentRecordsV1 = '/api/studentrecord/v1/getall';

  // Finance Ledger / Reports Endpoints
  static const String financeLedgerStats    = '/api/financeledger/stats';
  static const String financeLedgerTimeline = '/api/financeledger/timeline';
  static const String financeLedgerGetAll   = '/api/financeledger/getall';
  static const String financeLedgerGetById  = '/api/financeledger/get';

  // Expense Endpoints
  static const String addExpense             = '/api/expense/add';
  static const String getAllExpenses         = '/api/expense/getall';
  static const String getSingleExpenseById   = '/api/expense/get';
  static const String updateExpense          = '/api/expense/update';
  static const String updateExpenseStatus    = '/api/expense/updatestatus';
  static const String deleteExpense          = '/api/expense/delete';
  static const String deleteExpenseProof     = '/api/expense/deleteproof';

  // Announcement Endpoints
  static const String createAnnouncement          = '/api/announcement/create';
  static const String getAllAnnouncements         = '/api/announcement/getall';
  static const String getAnnouncement             = '/api/announcement/get';
  static const String updateAnnouncement          = '/api/announcement/update';
  static const String addAnnouncementAttachment   = '/api/announcement/addattachment';
  static const String deleteAnnouncementAttachment = '/api/announcement/deleteattachment';
  static const String deleteAnnouncement          = '/api/announcement/delete';

  // Club Endpoints
  static const String getAllClubs          = '/api/club/getall';
  static const String getClub             = '/api/club/get';
  static const String createClub          = '/api/club/create';
  static const String updateClubText      = '/api/club/updatetext';
  static const String updateClubThumbnail = '/api/club/updatethumbnail';
  static const String deleteClub          = '/api/club/delete';
  static const String getAllClubVideos    = '/api/club/video/getall';
  static const String getClubVideo        = '/api/club/video/get';
  static const String uploadClubVideo     = '/api/club/video/upload';
  static const String updateClubVideoDetails = '/api/club/video/updatedetails';
  static const String updateClubVideoFile = '/api/club/video/updatefile';
  static const String deleteClubVideo     = '/api/club/video/delete';

  // Club Management Endpoints
  static const String toggleClubStudent      = '/api/club/toggleclub/student';
  static const String addToClub             = '/api/club/addtoclub';
  static const String removeFromClub        = '/api/club/removefromclub';
  static const String getStudentClubs       = '/api/student/clubs';
  static const String addStudentToClub      = '/api/club/addtoclub';
  static const String removeStudentFromClub = '/api/club/removefromclub';
  static const String toggleStudentsInClub  = '/api/club/toggleclub/student';

  // Subscription Endpoints
  static const String updateSubscription = '/api/subscription/update';
  static const String getSubscription    = '/api/subscription/get';

  // Mark Report v1
  static const String createMarkReportV1       = '/api/markreport/v1/create';
  static const String getAllMarkReportsV1       = '/api/markreport/v1/get-all';
  static const String updateMarkReportV1       = '/api/markreport/v1/update';
  static const String deleteMarkReportV1       = '/api/markreport/v1/delete';
  static const String getSingleMarkReportV1    = '/api/markreport/v1/get';
  static const String getMarkReportByStudentV1 = '/api/markreport/v1/get/student';

  // Mark Report Config
  static const String createMarkReportConfig     = '/api/markreport/config/create';
  static const String getMarkReportConfigByClass = '/api/markreport/config/by-class';
  static const String updateMarkReportConfig     = '/api/markreport/config/update';
}