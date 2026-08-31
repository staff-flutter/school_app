import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/bindings/SchoolBinding.dart';
import 'package:school_app/bindings/attendance_binding.dart';
import 'package:school_app/bindings/bill_admission_binding.dart';
import 'package:school_app/bindings/eb_binding.dart';
import 'package:school_app/bindings/marks_upload_binding.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/student_controller.dart';
import 'package:school_app/screens/EB%20Log%20Module.dart';
import 'package:school_app/screens/fee_set_up_view.dart';
import 'package:school_app/screens/fuel_log_detail_page.dart';
import 'package:school_app/screens/tariff_module.dart';
import '../bindings/feestructure_binding.dart';
import '../bindings/transport_binding.dart';
import '../controllers/clubs_controller.dart';
import '../controllers/finance_ledger_controller.dart';
import '../screens/Bill_Book.dart';
import '../screens/accounting_dashboard_with_api_integration.dart';
import '../screens/admin_attendance.dart';
import '../screens/admission_book.dart';
import '../screens/admission_form_detail_view.dart';
import '../screens/admission_forms.dart';
import '../screens/attendance_dashboard.dart';
import '../screens/admission_form.dart';
import '../screens/bus_create_page.dart';
import '../screens/bus_module.dart';
import '../screens/bus_profile_page.dart';
import '../screens/bus_route_detail_page.dart';
import '../screens/bus_route_form_page.dart';
import '../screens/bus_route_list_page.dart';
import '../screens/clubs_&_activities_creating.dart' hide CampusManagementView;
import '../screens/create_employee_profile_page.dart';
import '../screens/create_student_profile_page.dart';
import '../screens/daily_trip_log_create_page.dart';
import '../screens/daily_trip_log_profile_page.dart';
import '../screens/daily_trip_module.dart';
import '../screens/dashboard_for_Transportion_analytics.dart';
import '../screens/driver_create_page.dart';
import '../screens/driver_module.dart';
import '../screens/driver_profile_page.dart';
import '../screens/eb_dashboard.dart';
import '../screens/employee_list_page.dart';
import '../screens/enhanced_profile_view.dart';
import '../screens/finance_dashboard_view.dart';
import '../screens/fuel_log_list_page.dart';
import '../screens/home_page.dart';
import '../controllers/attendance_controller.dart';
import '../screens/attendance_view.dart';
import '../screens/login_page_for_daily_grades.dart';
import '../screens/login_view.dart';
import '../screens/onboarding screen1.dart';
import '../screens/parent_management_page.dart';
import '../screens/premises_module.dart';
import '../screens/schedule_of_teacher.dart';
import '../screens/set_fee_configuration_page.dart';
import '../screens/simple_communications_view.dart';
import '../screens/Assignments_page.dart';
import '../screens/clubs&activities_page.dart';
import '../screens/campus_management_page.dart';
import '../screens/campus_management_view.dart';
import '../screens/fee_details_page.dart';
import '../screens/marks_list_page.dart';
import '../screens/parent_profile_page.dart';
import '../screens/profile_selection_page.dart';
import '../screens/splash_screen_for_daily_grades.dart' hide SplashScreen;
import '../screens/splash_screen1.dart';
import '../screens/student_complete_details_page.dart';
import '../screens/student_form_dialog.dart';
import '../screens/student_form_page.dart';
import '../screens/student_management_module_view.dart';
import '../screens/student_profile_page.dart';
import '../screens/student_profile_verification_page_for_admin_side.dart';
// ── NEW ──────────────────────────────────────────────────────────────────────
import '../screens/student_profile_management_page.dart';
// ─────────────────────────────────────────────────────────────────────────────
import '../screens/teacher_classes_view.dart';
import '../screens/techer_attendance_view.dart';
import '../screens/time_table_page.dart';
import '../screens/transaction_detail_view.dart';
import '../screens/receipt_detail_view.dart';
import '../screens/notifications_view.dart';
import '../screens/details_of_student_view.dart';
import '../screens/upload_student_marks.dart';
import '../screens/view_students_marks.dart';
import 'app_routes.dart';
import '../bindings/auth_binding.dart';
import '../controllers/auth_controller.dart';
import '../screens/login_view.dart';
import '../screens/splash_view.dart';
import '../screens/create_school_view.dart';
import '../screens/school_management_view.dart';
import '../controllers/student_management_controller.dart';
import '../bindings/dashboard_binding.dart';
import '../bindings/accounting_binding.dart';
import '../screens/accounting_dashboard_view.dart';
import '../screens/fee_collection_tabbed_view.dart';
import '../screens/expenses_view.dart';
import '../screens/fee_structure_view.dart';
import '../screens/reports_view.dart';
import '../bindings/student_binding.dart';
import '../bindings/academics_binding.dart';
import '../screens/academics_view.dart';
import '../bindings/communications_binding.dart';
import '../screens/communications_view.dart';
import '../bindings/clubs_binding.dart';
import '../screens/clubs_activities_view.dart';
import '../screens/club_detail_view.dart';
import '../screens/correspondent_profile_view.dart';
import '../screens/privacy_policy_view.dart';
import '../screens/delete_account_view.dart';
import '../screens/student_records_view.dart';
import '../bindings/student_record_binding.dart';
import '../screens/subscription_management_view.dart';
import '../bindings/subscription_binding.dart';
import '../screens/my_children_view.dart';
import '../controllers/my_children_controller.dart';
import '../screens/system_management_view.dart';
import '../controllers/system_management_controller.dart';
import '../screens/timetable_management_view.dart';
import '../screens/homework_management_view.dart';
import '../widgets/main_wrapper.dart';
import '../widgets/role_aware_wrapper.dart';
import '../middleware/role_guard.dart';
import '../controllers/parent_attendance_controller.dart';

class AppPages {

  static final routes = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const DynamicSchoolSplashScreen(),
     // binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.ONBOARDING,
      page: () => OnboardingScreen(),

    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const DailyGradesLoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: '/homepage',
      page: () => RoleAwareWrapper(child: HomePage()),
    ),
    GetPage(
      name: AppRoutes.CREATE_SCHOOL,
      page: () => CreateSchoolView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.SCHOOL_MANAGEMENT,
      page: () => RoleAwareWrapper(child: SchoolManagementView()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SchoolController());
      }),
    ),
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => RoleAwareWrapper(child: AccountingDashboardView1()),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.STUDENT_DETAILS,
      page: () => RoleAwareWrapper(child: StudentDetailView()),
        binding:BindingsBuilder(() {
          BillAdmissionBinding().dependencies();
          MarksUploadBinding().dependencies();
          StudentRecordBinding().dependencies();
          SchoolBinding().dependencies();
          }),
    ),
    GetPage(
      name: AppRoutes.DRIVER_MODULE,
      page: () => RoleAwareWrapper(child: DriverDirectoryScreen(
        onCreateDriver: () async {
          final shouldRefresh = await Get.to(() => const DriverCreateScreen());
          if (shouldRefresh == true) {
            // your directory already refreshes via RefreshIndicator/re-fetch on return
          }
        },
        onEditDriver: (driver) async {
          final shouldRefresh = await Get.to(() => DriverCreateScreen(driver: driver));
          // shouldRefresh == true means the directory list should reload too
        },
        onViewDriver: (driver) {
          Get.to(() => DriverProfileScreen(
            driverId: driver['_id'].toString(),
            onEdit: (currentDriver) async {
              // Get.to returns the popped value (true on successful update)
              return await Get.to(() => DriverCreateScreen(driver: currentDriver));
            },
          ));
        },
      )),
      binding: TransportBinding(),
    ),
    GetPage(
      name: AppRoutes.BUS_MODULE,
      page: () => RoleAwareWrapper(child: BusDirectoryScreen(
        onRegisterBus: () async {
          final shouldRefresh = await Get.to(() => const BusCreateScreen());
        },
        onEditBus: (bus) async {
          return await Get.to(() => BusCreateScreen(bus: bus));
        },
        onViewBus: (bus) {
          Get.to(() => BusProfileScreen(
            busId: bus['_id'].toString(),
            onEdit: (currentBus) async {
              return await Get.to(() => BusCreateScreen(bus: currentBus));
            },
          ));
        },
      )),
      binding: TransportBinding(),
    ),
    GetPage(
      name: AppRoutes.DAILY_TRIP_LOG_MODULE,
      page: () => RoleAwareWrapper(child: DailyTripLogDirectoryScreen(
        onLogTrip: () async {
          await Get.to(() => const DailyTripLogCreateScreen());
        },
        onEditTripLog: (log) async {
          return await Get.to(() => DailyTripLogCreateScreen(tripLog: log));
        },
        onViewTripLog: (log) {
          Get.to(() => DailyTripLogProfileScreen(
            tripLogId: log['_id'].toString(),
            onEdit: (currentLog) async {
              return await Get.to(() => DailyTripLogCreateScreen(tripLog: currentLog));
            },
          ));
        },
      )),
      binding: TransportBinding(),
    ),
    GetPage(
      name: AppRoutes.BUS_ROUTE_MODULE,
      page: () => RoleAwareWrapper(
        child: BusRouteListScreen(
          schoolId: Get.find<AuthController>().schoolId.toString(),
        ),
      ),
      binding: TransportBinding(),
    ),
    GetPage(
      name: AppRoutes.FUEL_LOG_MODULE,
      page: () => RoleAwareWrapper(
        child: FuelLogListScreen(
          schoolId: Get.find<AuthController>().schoolId.toString(),
        ),
      ),
      binding: TransportBinding(),
    ),
    GetPage(
      name: AppRoutes.TRANSPORTATION_ANALYTICS_DASHBOARD,
      page: () => RoleAwareWrapper(
        child: TransportationAnalyticsScreen(),
      ),
      binding: TransportBinding(),
    ),
    GetPage(
      name: AppRoutes.PREMISES_MODULE,
      page: () => RoleAwareWrapper(
        child: PremisesListScreen(),
      ),
      binding: EbBinding(),
    ),
    GetPage(
      name: AppRoutes.EB_LOG_MODULE,
      page: () => RoleAwareWrapper(
        child: EBLogListScreen(),
      ),
      binding: EbBinding(),
    ),
    GetPage(
      name: AppRoutes.TARIFF_MODULE,
      page: () => RoleAwareWrapper(
        child: TariffListScreen(),
      ),
      binding: EbBinding(),
    ),
    GetPage(
      name: AppRoutes.EB_DASHBOARD,
      page: () => RoleAwareWrapper(
        child: EBDashboardScreen(),
      ),
      binding: EbBinding(),
    ),
    GetPage(
      name: '/teacher-classes',
      page: () => RoleAwareWrapper(child: const TeacherClassesView()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => StudentManagementController());
        Get.lazyPut(() => SchoolController());
      }),
    ),
    GetPage(
      name: AppRoutes.SCHEDULE_OF_TEACHER,
      page: () => RoleAwareWrapper(child: const TeacherMySchedule()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => StudentManagementController());
        Get.lazyPut(() => SchoolController());
      }),
    ),
    GetPage(
      name: AppRoutes.CREATE_EMPLOYEE_PROFILE,
      page: () => RoleAwareWrapper(child: CreateEmployeeProfilePage(userId: '',)),

    ),
    GetPage(
      name: AppRoutes.EMPLOYEE_LIST,
      page: () => RoleAwareWrapper(child: StaffManagementPage()),
      binding: SchoolBinding(),
    ),
    GetPage(
      name: AppRoutes.PARENT_LIST,
      page: () => RoleAwareWrapper(child: ParentManagementPage ()),
      binding: BindingsBuilder((){
       Get.lazyPut(() => StudentManagementController());
       Get.lazyPut(() => SchoolController());
      }),
    ),
    GetPage(
      name: AppRoutes.ACCOUNTING_DASHBOARD,
      page: () => RoleAwareWrapper(child: AccountingDashboardView1()),
      binding: AccountingBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMISSION_FORM,
      page: () => RoleAwareWrapper(child: const AdmissionBillBookView()),
      binding: BindingsBuilder(() {
       BillAdmissionBinding().dependencies();
       SchoolBinding().dependencies();
       }),
    ),
    GetPage(
      name: AppRoutes.BILL_BOOK,
      page: () => RoleAwareWrapper(child: const BillBookManagementScreen()),
      binding: BindingsBuilder(() {
        BillAdmissionBinding().dependencies();
        SchoolBinding().dependencies();
      }),
    ),
    GetPage(
      name: AppRoutes.ADMISSION_FORMS_VIEW,
      page: () => RoleAwareWrapper(child: AdmissionFormListView()),
      binding: BindingsBuilder(() {
      BillAdmissionBinding().dependencies();
      SchoolBinding().dependencies();
     })
    ),
    GetPage(
      name: AppRoutes.ADMISSION_FORM_DETAIL_VIEW,
      page: () => RoleAwareWrapper(child: AdmissionFormDetailView(admissionFormId: '',)),
      binding: BillAdmissionBinding(),
    ),
    GetPage(
      name: AppRoutes.ATTENDANCE_DASHBOARD,
      page: () => RoleAwareWrapper(child: AttendanceHistoryDashboardPage()),
      binding: BindingsBuilder(() {
        AttendanceBinding().dependencies();
        SchoolBinding().dependencies();
  }),
    ),
    GetPage(
      name: AppRoutes.ADMISSION_BOOK,
      page: () => RoleAwareWrapper(child: AdmissionBookSetupView()),
       binding: BindingsBuilder(() {
        BillAdmissionBinding().dependencies();
        SchoolBinding().dependencies();
       })
    ),
    GetPage(
      name: AppRoutes.FEE_COLLECTION,
      page: () => RoleAwareWrapper(child: FeeCollectionTabbedView()),
      binding:  BindingsBuilder(() {
      AccountingBinding().dependencies();
        SchoolBinding().dependencies();
      }),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.EXPENSES,
      page: () => RoleAwareWrapper(child: ExpensesView()),
      binding: BindingsBuilder(() {
        AccountingBinding().dependencies();
        SchoolBinding().dependencies();
      }),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.FEE_CONFIGURATION,
      page: () => RoleAwareWrapper(child: SetFeeConfigurationPage()),
      binding: BindingsBuilder(() {
        FeestructureBinding().dependencies();
        SchoolBinding().dependencies();

      }),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.FEE_STRUCTURE,
      page: () => RoleAwareWrapper(child: FeeStructureView()),
      binding: BindingsBuilder(() {
       AccountingBinding().dependencies();
       SchoolBinding().dependencies();
      }),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.FEE_SETUP,
      page: () => RoleAwareWrapper(child: FeeSetupView()),
      binding: BindingsBuilder(() {
        AccountingBinding().dependencies();
        SchoolBinding().dependencies();

      }),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.REPORTS,
      page: () => RoleAwareWrapper(child: ReportsView()),
      binding: AccountingBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.STUDENT_MANAGEMENT,
      page: () => RoleAwareWrapper(child: StudentManagementView()),
      binding:BindingsBuilder(() {
        StudentBinding().dependencies();
        SchoolBinding().dependencies();
      }),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: '/students',
      page: () => RoleAwareWrapper(child: StudentManagementView()),
      binding: StudentBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.MARKS_UPLOAD,
      page: () => RoleAwareWrapper(child: StudentMarksUploadPage()),
      binding: MarksUploadBinding(),
    ),
    GetPage(
      name: AppRoutes.ACADEMICS,
      page: () => RoleAwareWrapper(child: AcademicsView()),
      binding: AcademicsBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.COMMUNICATIONS,
      page: () => RoleAwareWrapper(child: CommunicationsView()),
      binding: CommunicationsBinding(),
    ),
    GetPage(
      name: AppRoutes.CLUBS_ACTIVITIES,
      page: () {
        String role = '';
        try {
          role = Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
        } catch (_) {}
        const managementRoles = {
          'correspondent', 'accountant', 'principal', 'viceprincipal', 'administrator'
        };
        if (managementRoles.contains(role)) {
          return RoleAwareWrapper(child: const CampusManagementView());
        }
        return RoleAwareWrapper(child: const ClubAndActivitiesPage());
      },
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ClubsController());
        if (!Get.isRegistered<MyChildrenController>()) {
          Get.lazyPut(() => MyChildrenController());
        }
      }),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.CAMPUS_MANAGEMENT_PAGE,
      page: () => RoleAwareWrapper(child: const ClubAndActivitiesPage()),
      binding: BindingsBuilder(() {
        final role = Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
        const staffRoles = {
          'correspondent', 'administrator', 'principal',
          'viceprincipal', 'teacher', 'accountant',
        };
        if (!staffRoles.contains(role)) {
          if (!Get.isRegistered<MyChildrenController>()) {
            Get.lazyPut(() => MyChildrenController());
          }
        }
      }),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.CLUB_DETAIL,
      page: () => RoleAwareWrapper(child: const ClubDetailView()),
      binding: ClubsBinding(),
    ),
    GetPage(
      name: '/profile',
      page: () {
        try {
          final auth = Get.find<AuthController>();
          final role = auth.user.value?.role?.toLowerCase() ?? '';
          if (['correspondent','accountant','principal','administrator','teacher','viceprincipal']
              .contains(role)) {
            return RoleAwareWrapper(child: const CorrespondentProfileView());
          }
        } catch (_) {}
        return RoleAwareWrapper(child: ParentProfile());
      },
      binding: AuthBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: '/privacy-policy',
      page: () => const PrivacyPolicyView(),
    ),
    GetPage(
      name: '/delete-account',
      page: () => const DeleteAccountView(),
    ),
    GetPage(
      name: AppRoutes.ATTENDANCE,
      page: () => RoleAwareWrapper(child: SchoolManagementView()),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.teacherClasses,
      page: () => const TeacherClassesView(),
    ),
    GetPage(
      name: '${AppRoutes.ATTENDANCE}/student',
      page: () => RoleAwareWrapper(child: const AttendanceView()),
      binding: BindingsBuilder(() {
        if (Get.isRegistered<ParentAttendanceController>()) {
          Get.delete<ParentAttendanceController>();
        }
        Get.put(ParentAttendanceController());
      }),
    ),
    GetPage(
      name: '${AppRoutes.TEACHER_ATTENDANCE}',
      page: () => RoleAwareWrapper(child: const AdminAttendanceView()),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<SchoolController>()) {
          Get.put(SchoolController());
        }
        if (!Get.isRegistered<ParentAttendanceController>()) {
          Get.put(ParentAttendanceController());
        }
      }),
    ),
    GetPage(
      name: AppRoutes.STUDENT_RECORDS,
      page: () => RoleAwareWrapper(child: const StudentRecordsView()),
      binding: BindingsBuilder(() {
        StudentRecordBinding().dependencies();
        SchoolBinding().dependencies();
      }),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.STUDENT_PROFILE_VERIFICATION,
      page: () => RoleAwareWrapper(child: const ProfileVerificationPage()),
    ),
    GetPage(
      name: AppRoutes.STUDENT_MARKS_LIST,
      page: () => RoleAwareWrapper(child: const StudentMarksViewPage()),
      binding: StudentRecordBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.STUDENT_PROFILE_CREATION,
      page: () => RoleAwareWrapper(child: const CreateStudentProfilePage()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController());
        Get.lazyPut(() => StudentController());
        Get.lazyPut(() => SchoolController());
      }),
    ),

    // ── Student Profile Management (view / edit / delete) ──────────────────
    GetPage(
      name: AppRoutes.STUDENT_PROFILE_MANAGEMENT,
      page: () => RoleAwareWrapper(
          child: const StudentProfileManagementPage()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController());
        Get.lazyPut(() => SchoolController());
        if (!Get.isRegistered<StudentController>()) {
          Get.lazyPut(() => StudentController());
        }
      }),
      middlewares: [RoleGuard()],
    ),
    // ─────────────────────────────────────────────────────────────────────────

    GetPage(
      name: '/system-management',
      page: () => RoleAwareWrapper(child: SystemManagementView()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SystemManagementController());
        Get.lazyPut(() => SchoolController());
      }),
    ),
    GetPage(
      name: '/finance_transactions',
      page: () => RoleAwareWrapper(child: FinanceDashboardView()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FinanceLedgerController());
        Get.lazyPut(() => SchoolController());
      }),
    ),
    GetPage(
      name: '/transaction_detail',
      page: () => TransactionDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FinanceLedgerController());
      }),
    ),
    GetPage(
      name: '/my-children',
      page: () => ProfileSelection(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MyChildrenController());
      }),
    ),
    GetPage(
      name: AppRoutes.SUBSCRIPTION_MANAGEMENT,
      page: () => RoleAwareWrapper(child: const SubscriptionManagementView()),
      binding: SubscriptionBinding(),
    ),
    GetPage(
      name: '/student-details',
      page: () => const DetailsOfStudentView(),
      binding: BindingsBuilder(() {}),
    ),
    GetPage(
      name: '/notifications',
      page: () => RoleAwareWrapper(child: const NotificationsView()),
    ),
    GetPage(
      name: AppRoutes.TIMETABLE_MANAGEMENT1,
      page: () {
        try {
          final auth = Get.find<AuthController>();
          final role = auth.user.value?.role?.toLowerCase() ?? '';
          if (['correspondent','accountant','principal','administrator','teacher','viceprincipal']
              .contains(role)) {
            return RoleAwareWrapper(child: TimetableManagementView());
          }
        } catch (_) {}
        return RoleAwareWrapper(child: TimeTablePage());
      },
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.TIMETABLE_MANAGEMENT,
      page: () => RoleAwareWrapper(child: TimeTablePage()),
      middlewares: [RoleGuard()],
      binding: SchoolBinding(),
    ),
    GetPage(
      name: AppRoutes.HOMEWORK_MANAGEMENT,
      page: () {
        try {
          final auth = Get.find<AuthController>();
          final role = auth.user.value?.role?.toLowerCase() ?? '';
          if (['correspondent','accountant','principal','administrator','teacher','viceprincipal']
              .contains(role)) {
            return RoleAwareWrapper(child: HomeworkManagementView());
          }
        } catch (_) {}
        return RoleAwareWrapper(child: AssignmentUI());
      },
      binding: SchoolBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: '/receipt_detail',
      page: () {
        final args = Get.arguments;
        if (args == null) {
          Get.back();
          Get.snackbar('Error', 'Receipt data not found',
              backgroundColor: Colors.red, colorText: Colors.white);
          return const SizedBox();
        }
        if (args is! Map<String, dynamic>) {
          Get.back();
          Get.snackbar('Error', 'Invalid receipt data format',
              backgroundColor: Colors.red, colorText: Colors.white);
          return const SizedBox();
        }
        return ReceiptDetailView(receiptData: args);
      },
      binding: StudentRecordBinding(),
    ),
  ];
}