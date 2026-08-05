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
  static const String getStudentAttendance = '/api/attendance/student';

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
 static const String linkAdmissionFormToStudent     = '/api/school/admission-form/:id/link-student';      //api no: 181   { QueryParams  AdmissionFormId }


// Employee Profile apis
  static const String createEmployeeProfile = '/api/employee-profile/create';
  static const String getAllEmployeeDetails = '/api/employee-profile/getall';
  static const String getOneEmployeeProfile = '/api/employee-profile/get';                          //api no: 185   Params: userId
  static const String updateEmployeeProfile = '/api/employee-profile/update';                       //api no: 186   Params:   userId  Body: Enter all the employee profile schema structure fields that need to be updated.
  static const String deleteEmployeeProfile = '/api/employee-profile/delete';                       //api no: 187     Params: userId
  static const String addAdditionalDocuments = '/api/employee-profile/:userId/documents';                         //api no: 188   Params: userId Form Data: Upload multiple documents using files key.
  static const String deleteSpecificDocument = '/api/employee-profile/:userId/documents/:documentId';                                //api no: 189   Params: userId, documentId
  static const String createAndUpdate = '/api/employee-profile/:userId/upsert';                                 //api no: 190   Params: userId Form Data: Upload multiple documents  using documents key, and upload single salary file at a time using the salarySlipFile key.


// Quiz End points

  static const String createQuiz = '/api/club/quiz/create';                        // Request Body clubId,clubVideoId?,classId?,sectionId?,title,description?,questions[],academicYear?
  static const String updateQuiz = '/api/club/quiz/update';                        // Request Body clubId?,clubVideoId?,classId?,sectionId?,title?,description?,questions?,academicYear?, isActive?
  static const String deleteQuiz = '/api/club/quiz/delete';
  static const String getQuizzesByClub = '/api/club/quiz/getall';
  static const String generateQuizFromPdf  = '/api/club/quiz/create/ai';            // Request Body clubId , clubVideoId,classId,sectionId


  static const String SubmitQuiz = '/api/club/quiz/attempt/create';
  static const String getAllQuizAttempts  = '/api/club/quiz/attempt/getall';
  static const String getSingleAttempt = '/api/club/quiz/attempt/get';
  static const String deleteAttempt = '/api/club/quiz/attempt/delete';


  // ─── Transport: Driver Endpoints ───────────────────────────────────────────
  // POST /api/transport/driver/create
  //   multipart/form-data — schoolId (required), name, phone, assignedBusId,
  //   dateOfBirth, joinedDate, emergencyContact, address, documents (JSON array),
  //   photo, documents_0/documents_1/... (per-document attachment files)
  static const String createDriver           = '/api/transport/driver/create';
  // GET /api/transport/driver — query: schoolId, status, search (all optional)
  static const String getAllDrivers          = '/api/transport/driver';
  // GET /api/transport/driver/dropdown/:schoolId
  static const String getDriverDropdown      = '/api/transport/driver/dropdown';
  // GET /api/transport/driver/:id
  static const String getDriver              = '/api/transport/driver';
  // PUT /api/transport/driver/:id — multipart/form-data
  static const String updateDriver           = '/api/transport/driver';
  // DELETE /api/transport/driver/:id
  static const String deleteDriver           = '/api/transport/driver';
  // DELETE /api/transport/driver/:id/documents/:documentId/files/:fileId
  static const String deleteDriverDocumentFile = '/api/transport/driver';

  // ─── Transport: Bus Endpoints ──────────────────────────────────────────────
  // POST /api/transport/bus/create
  //   multipart/form-data — all Bus schema fields; statutoryDocuments as JSON
  //   array; files via statutoryDocuments_0, statutoryDocuments_1, ...
  static const String createBus              = '/api/transport/bus/create';
  // GET /api/transport/bus/ — query: schoolId, operationalStatus, search
  static const String getAllBuses            = '/api/transport/bus/';
  // GET /api/transport/bus/dropdown/:schoolId
  static const String getBusDropdown         = '/api/transport/bus/dropdown';
  // GET /api/transport/bus/:id
  static const String getBus                 = '/api/transport/bus';
  // PUT /api/transport/bus/:id — multipart/form-data, partial update
  static const String updateBus               = '/api/transport/bus';
  // DELETE /api/transport/bus/:id
  static const String deleteBus               = '/api/transport/bus';
  // DELETE /api/transport/bus/:id/documents/:documentId/files/:fileId
  static const String deleteBusDocumentFile   = '/api/transport/bus';

  // ─── Transport: Daily Trip Log Endpoints ───────────────────────────────────
  static const String createDailyTripLog     = '/api/transport/dailytriplog/create';
  // GET /api/transport/dailytriplog/ — query: schoolId, busId, academicYear, page, limit
  static const String getAllDailyTripLogs    = '/api/transport/dailytriplog/';
  // GET /api/transport/dailytriplog/:id
  static const String getDailyTripLog        = '/api/transport/dailytriplog';
  // PUT /api/transport/dailytriplog/:id
  static const String updateDailyTripLog     = '/api/transport/dailytriplog';
  // DELETE /api/transport/dailytriplog/:id
  static const String deleteDailyTripLog     = '/api/transport/dailytriplog';

  // ─── Transport: Fuel Log Endpoints ─────────────────────────────────────────
  static const String createFuelLog          = '/api/transport/fuellog/create';
  // GET /api/transport/fuellog/ — query: schoolId, busId, academicYear, search,
  //   fromDate, toDate, minAmount, maxAmount, page, limit
  static const String getAllFuelLogs         = '/api/transport/fuellog/';
  // GET /api/transport/fuellog/:id — schoolId passed as query param
  static const String getFuelLog             = '/api/transport/fuellog';
  // PUT /api/transport/fuellog/:id
  static const String updateFuelLog          = '/api/transport/fuellog';
  // DELETE /api/transport/fuellog/:id
  static const String deleteFuelLog          = '/api/transport/fuellog';

  // ─── Transport: Bus Route Endpoints ────────────────────────────────────────
  // POST /api/transport/busroute/ — stops: [{ stopName, landmark, order, latitude, longitude, googlePlaceId }]
  static const String createBusRoute         = '/api/transport/bus-route/';
  // POST /api/transport/busroute/:routeId/assignments
  //   assignments: [{ busId, driverId, shift, stopTimings: [{ stopName, time }] }]
  static const String addBusRouteAssignments = '/api/transport/bus-route';
  // PUT /api/transport/busroute/:routeId/assignments — needs assignmentId in body
  static const String updateBusRouteAssignment = '/api/transport/bus-route';
  // DELETE /api/transport/busroute/:routeId/assignments — needs assignmentId in body
  static const String deleteBusRouteAssignment = '/api/transport/bus-route';
  // GET /api/transport/busroute/ — query: schoolId, search, minFee, maxFee, page, limit
  static const String getAllBusRoutes        = '/api/transport/bus-route';
  // GET /api/transport/busroute/drop-down — query: schoolId
  static const String getBusRouteDropdown    = '/api/transport/bus-route/drop-down';
  // GET /api/transport/busroute/:routeId
  static const String getBusRoute            = '/api/transport/bus-route';
  // PUT /api/transport/busroute/:routeId
  static const String updateBusRoute         = '/api/transport/bus-route';
  // DELETE /api/transport/busroute/:routeId
  static const String deleteBusRoute         = '/api/transport/bus-route';

  static const String getDailyTripLogAnalytics = '/api/transport/dailytriplog/analytics';
  static const String getFuelLogAnalytics       = '/api/transport/fuellog/analytics';

  // ─── EB: Premises Endpoints ────────────────────────────────────────────────
  // GET /api/premises/get/:schoolId — fetch all premises for a school
  static const String getAllPremises   = '/api/premises/get';                    //api no: 225
  // POST /api/premises/create/:schoolId
  static const String createPremises   = '/api/premises/create';                 //api no: 226
  // PUT /api/premises/update/:schoolId/:premisesId
  static const String updatePremises   = '/api/premises/update';                 //api no: 227
  // DELETE /api/premises/delete/:schoolId/:premisesId
  static const String deletePremises   = '/api/premises/delete';                 //api no: 228
  // GET /api/premises/get/:schoolId/:premisesId — fetch a single premises
  static const String getPremises      = '/api/premises/get';                    //api no: 229

  // ─── EB: Log Endpoints ─────────────────────────────────────────────────────
  // GET /api/eb/logs/get-all/:schoolId
  //   query (optional): premisesId, fromDate, toDate, minReading, maxReading, search
  static const String getAllEBLogs     = '/api/eb/logs/get-all';                 //api no: 230
  // GET /api/eb/logs/get/:schoolId/:logId
  static const String getEBLog         = '/api/eb/logs/get';                     //api no: 231
  // POST /api/eb/logs/create/:schoolId — all fields except ebLogNo
  static const String createEBLog      = '/api/eb/logs/create';                  //api no: 232
  // PUT /api/eb/logs/update/:schoolId/:logId
  static const String updateEBLog      = '/api/eb/logs/update';                  //api no: 233
  // DELETE /api/eb/logs/delete/:schoolId/:logId
  static const String deleteEBLog      = '/api/eb/logs/delete';                  //api no: 234

  // Analytics base — actual routes are built as:
  //   GET  <base>/:schoolId/premises              — per-premises analytics cards   //api no: 235
  //   GET  <base>/:schoolId/dashboard              — overall EB dashboard summary   //api no: 236
  //   GET  <base>/:schoolId/linechart/consumption  — query: period, premisesId,
  //                                                  fromDate, toDate               //api no: 237
  //   GET  <base>/:schoolId/bill/kpi                — projected billing KPIs        //api no: 238
  static const String ebLogsAnalyticsBase = '/api/eb/logs/analytics';

  // ─── EB: Tariff Endpoints ──────────────────────────────────────────────────
  // GET /api/eb/tariff/get-all/:schoolId
  static const String getAllTariffs    = '/api/eb/tariff/get-all';               //api no: 239
  // GET /api/eb/tariff/get/:schoolId/:tariffId
  static const String getTariff        = '/api/eb/tariff/get';                   //api no: 240
  // POST /api/eb/tariff/create/:schoolId — slabs sent as array of slab objects
  static const String createTariff     = '/api/eb/tariff/create';                //api no: 241
  // PUT /api/eb/tariff/update/:schoolId/:tariffId — send complete slabs array if updating slabs
  static const String updateTariff     = '/api/eb/tariff/update';                //api no: 242
  // DELETE /api/eb/tariff/delete/:schoolId/:tariffId
  static const String deleteTariff     = '/api/eb/tariff/delete';                //api no: 243

  static const String updateProfileImg = '/api/user/update-profile-img'; // PUT; append '/:userId'
  static const String forgotPassword = '/api/user/forgot-password';


}