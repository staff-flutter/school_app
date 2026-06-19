class ApiConstants {
  static const String baseUrl = 'https://dailygrades.com';

  // Auth Endpoints
  static const String login            = '/api/user/login';
  static const String logout           = '/api/user/logout';
  static const String isAuthenticated  = '/api/user/isauthenticated';
  static const String createUser       = '/api/user/v1/create';                   // api no : 145
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

  static const String postStudentProfileUpdateRequest = '/api/student/request-update';
  static const String getStudentProfilePendingRequest = '/api/student/pending-requests';
  static const String getAllPendingStudentProfileUpdateRequest = '/api/student/all-pending';
  static const String putApproveOrRejectStudentProfileUpdateRequest ='/api/student/review-request ';

  // Student File Operations (v1)
  // POST   /api/student/v1/upload-files/:studentId   — field name: "files"
  // DELETE /api/student/v1/delete-document/:studentId/:documentId
  static const String uploadStudentFiles    = '/api/student/v1/upload-files';                //api no: 147
  static const String deleteStudentDocument = '/api/student/v1/delete-document';             //api no: 148

  // Dashboard Endpoints
  static const String accountingDashboard = '/api/accounting/dashboard';

  // Fee Structure Endpoints
  static const String setFeeStructure = '/api/feestructure/v1/set';                          //api no: 149
  static const String getFeeStructure = '/api/feestructure/v1/getbyclass';                   //api no: 150
  static const String createOrUpdateFeeConfigurationOfSchool ='/api/fee-config/set';                 //api no: 151
  static const String getCurrentFeeConfigurationOfSchool     ='/api/fee-config/get';          //api no: 152


  // Student Record Endpoints
  static const String applyConcession      = '/api/studentrecord/v1/applyconcession';         //api no: 153
  static const String collectFee           = '/api/studentrecord/v1/collectfee';              // api no: 155
  static const String getStudentRecord     = '/api/studentrecord/v1/getrecord';               // api no: 142
  static const String deleteStudentRecord  = '/api/studentrecord/v1/remove';                  // api no: 158
  static const String toggleStudentStatus  = '/api/studentrecord/v1/togglestatus';           //  api no: 144
  static const String updateConcessionValue = '/api/studentrecord/v1/updatevalue';           //api no: 154
  static const String updateConcessionProof = '/api/studentrecord/update/proof';
  static const String getDues              = '/api/accounting/fees/dues';
  static const String revertReceipt        = '/api/studentrecord/v1/revertreceipt';          //api no : 156
  static const String getTransactionHistory = '/api/accounting/fees/history';
  static const String getStudentRecords    = '/api/studentrecord/getall';
  static const String getStudentsByClass   = '/api/student/getbyclass';
  static const String putAssignStudentToClassAndSectionForAcademicYear = '/api/studentrecord/v1/assign';   //api no: 157
  static const String FetchAllFeeTransactionsOrReceipts = '/api/fee/receipt/getall';                       //api no: 159
  static const String getSingleFeeTransactionReceipt  = '/api/fee/receipt/get';                        //api no: 160
  static const String updateChequeOrBankTransfer  = '/api/fee/receipt/v1/update-status';               //api no: 161

  // Student Record Endpoints (v1)
  // GET /api/studentrecord/v1/getrecord/:schoolId/:studentId
  //   — single student record; also returns profile image + uploaded documents
  // GET /api/studentrecord/v1/getall
  //   — paginated list of student records with filters (schoolId, page, limit,
  //     search, academicYear, classId, sectionId, isActive, isBusApplicable,
  //     isFullyPaid)
  static const String getStudentRecordV1     = '/api/studentrecord/v1/getrecord';
  static const String getAllStudentRecordsV1 = '/api/studentrecord/v1/getall';                          // api no: 143

  // Finance Ledger / Reports Endpoints
  static const String financeLedgerStats    = '/api/financeledger/stats';
  static const String financeLedgerTimeline = '/api/financeledger/v1/timeline';                          // api no: 137
  static const String financeLedgerGetAll   = '/api/financeledger/getall';
  static const String financeLedgerGetById  = '/api/financeledger/get';
  static const String getExpenseReport      = '/api/expense/v1/report ';                                 // api no: 136
  static const String getCollectedFeesStatistics = '/api/financeledger/v1/collected';                    // api no: 138
  static const String getRecentFeePaymentActivities = '/api/financeledger/v1/student/recent-activity';   // api no: 139
  static const String getAllStudentsFeeDues     = '/api/financeledger/v1/class/fee-dues';                // api no: 139A
  static const String getAllStudentsWithoutPagination = '/api/student/v1/withoutpagination/getall';      // api no: 140
  static const String patchApproveStudentConcessionRequest = '/api/studentrecord/v1/verify-concession';  // api no: 141
  static const String getTotalDueAmountOfStudent = '/api/financeledger/outstanding';                     // api no: 146




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


  // Bill Book Endpoints

  static const String  createNewBillBook = '/api/school-config/bill-book';                              //api no: 162
  static const String  getAllBillBooks = '/api/school-config/bill-book';                                //api no: 163    { QueryParams  schoolId }
  static const String  updateBillBook = '/api/school-config/bill-book';                                 //api no: 164    { QueryParams  BillBookId }
  static const String  manuallyUpdateBillNumber  = '/api/school-config/bill-book/:id/sequence';         //api no: 165    { QueryParams  BillBookId }
  static const String  deleteInactiveBillBook    = '/api/school-config/bill-book';                      //api no: 166    { QueryParams  BillBookId }


 // Admission Book Endpoints

 static const String createNewBookAdmissionForSchool = '/api/school-config/admission-book';              //api no: 167
 static const String getAllAdmissionBooks = '/api/school-config/admission-book';                         //api no: 168   { QueryParams  schoolId }
 static const String updateAdmissionBook = '/api/school-config/admission-book';                          //api no: 169   { QueryParams  AdmissionBookId }
 static const String manuallyUpdateAdmissionFormNumber ='/api/school-config/admission-book/:id/sequence';//api no: 170   { QueryParams  AdmissionBookId }
 static const String deleteInactiveAdmissionBook ='/api/school-config/admission-book';                   //api no: 171   { QueryParams  AdmissionBookId }


 // Admission Form Endpoints

 static const String generateNewAdmissionFormLink = '/api/school/admission-form/generate-link';          //api no: 172
 static const String submitAdmissionForm = '/api/school/admission-form/admissions/submit';               //api no: 173   { QueryParams  AdmissionFormId }
 static const String getAdmissionForm = '/api/school/admission-form/dropdown';                           //api no: 174   { QueryParams  AdmissionFormId ,academicYear ,search(optional) }
 static const String getSingleAdmissionForm = '/api/school/admission-form/form';                         //api no: 175   { QueryParams  AdmissionFormId(optional) ,studentId(optional)}
 static const String getAllAdmissionForms = '/api/school/admission-form';                                //api no: 176   { QueryParams  SchoolId , academicYear(optional) ,status (optional) , search (optional),startDate(optional), endDate(optional),page(optional),limit(optional)}
 static const String deleteAdmissionForm = '/api/school/admission-form';                                 //api no: 177   { QueryParams  AdmissionFormId }
 static const String updateAdmissionFormStatus = '/api/school/admission-form/status';                    //api no: 179   { QueryParams  AdmissionFormId }  there is no 178 in pdf
 static const String updateAdmissionFormAfterSubmission = '/api/school/admission-form/details';          //api no: 180   { QueryParams  AdmissionFormId(optional) ,StudentId(optional) either studentId or AdmissionFormId should provide}
 static const String linkAdmissionFormToStudent     = '/api/school/admission-form/:id/linkstudent';      //api no: 181   { QueryParams  AdmissionFormId }

}