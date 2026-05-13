import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/finance_ledger_controller.dart';
import '../screens/finance_dashboard_view.dart';
import '../screens/home_page.dart';
import '../controllers/attendance_controller.dart';
import '../screens/attendance_view.dart';
import '../screens/login_view.dart';
// import '../screens/announcements_page.dart'; // TODO: file not provided
import '../screens/simple_communications_view.dart';
import '../screens/Assignments_page.dart';
// import '../screens/Attendence_page.dart'; // TODO: file not provided
import '../screens/clubs&activities_page.dart';
import '../screens/campus_management_view.dart'; // ✅ New clubs page for management roles
import '../screens/fee_details_page.dart';
import '../screens/marks_list_page.dart';
import '../screens/parent_profile_page.dart';
import '../screens/profile_selection_page.dart';
import '../screens/splash_screen.dart';
import '../screens/student_form_dialog.dart';
import '../screens/student_form_page.dart';
import '../screens/student_profile_page.dart';
import '../screens/teacher_classes_view.dart';
import '../screens/time_table_page.dart';
import '../screens/transaction_detail_view.dart';
import '../screens/receipt_detail_view.dart';
import '../screens/notifications_view.dart';
import '../screens/details_of_student_view.dart';
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
import '../controllers/clubs_controller.dart'; // needed for BindingsBuilder inline
import '../screens/clubs_activities_view.dart';
import '../screens/club_detail_view.dart';
import '../screens/correspondent_profile_view.dart';
import '../screens/privacy_policy_view.dart';
import '../screens/delete_account_view.dart';
// Removed duplicate: import '../screens/attendance_view.dart';
// import '../bindings/old_attendance_binding.dart'; // Not used directly in routes
// import '../bindings/old_attendance_binding.dart' as module_attendance_binding; // Unused - route uses BindingsBuilder inline
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
      page: () => const SplashScreen(),
      binding: AuthBinding(),
    ),
GetPage(
  name: AppRoutes.LOGIN,
  page: () => const LoginView(),
  binding: AuthBinding(),
),
    GetPage(
      name: '/homepage',
      page: () =>  RoleAwareWrapper(child: HomePage()),

    ),
    GetPage(
      name: AppRoutes.CREATE_SCHOOL,
      page: () => CreateSchoolView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.SCHOOL_MANAGEMENT,
      page: () => RoleAwareWrapper(child: SchoolManagementView()),
    ),
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => RoleAwareWrapper(child: AccountingDashboardView()),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: '/teacher-classes',
      page: () => RoleAwareWrapper(child: const TeacherClassesView()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => StudentManagementController());
      }),
    ),
    GetPage(
      name: AppRoutes.ACCOUNTING_DASHBOARD,
      page: () => RoleAwareWrapper(child: AccountingDashboardView()),
      binding: AccountingBinding(),
    ),
    GetPage(
      name: AppRoutes.FEE_COLLECTION,
      page: () => RoleAwareWrapper(child: FeeCollectionTabbedView()),
      binding: AccountingBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.EXPENSES,
      page: () => RoleAwareWrapper(child: ExpensesView()),
      binding: AccountingBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.FEE_STRUCTURE,
      page: () => RoleAwareWrapper(child: FeeStructureView()),
      binding: AccountingBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.REPORTS,
      page: () => RoleAwareWrapper(child: ReportsView(),),
      binding: AccountingBinding(),
      middlewares: [RoleGuard()],
    ),
    // GetPage(
    //   name: AppRoutes.STUDENT_MANAGEMENT,
    //   page: () => RoleAwareWrapper(child: StudentManagementView()),
    //   binding: StudentBinding(),
    //   middlewares: [RoleGuard()],
    // ),
    // GetPage(
    //   name: '/students',
    //   page: () => RoleAwareWrapper(child: StudentManagementView()),
    //   binding: StudentBinding(),
    //   middlewares: [RoleGuard()],
    // ),
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
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.CLUBS_ACTIVITIES,
      page: () {
        // Correspondent/accountant see the new management view.
        // All other roles (parent, teacher, etc.) keep the old page.
        String role = '';
        try {
          role = Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
        } catch (_) {}
        const managementRoles = {'correspondent', 'accountant', 'principal', 'viceprincipal', 'administrator'};
        if (managementRoles.contains(role)) {
          return RoleAwareWrapper(child: const CampusManagementView());
        }
        return RoleAwareWrapper(child: const ClubAndActivitiesPage());
      },
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ClubsController());
        // Register MyChildrenController safely so ClubAndActivitiesPage
        // doesn't crash for non-parent roles that don't have it.
        if (!Get.isRegistered<MyChildrenController>()) {
          Get.lazyPut(() => MyChildrenController());
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
        // Correspondent and accountant get the dashboard-themed profile
        try {
          final auth = Get.find<AuthController>();
          final role = auth.user.value?.role?.toLowerCase() ?? '';
          if (role == 'correspondent' || role == 'accountant') {
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
        // Always create a fresh instance for specific student view to avoid state persistence
        if (Get.isRegistered<ParentAttendanceController>()) {
          Get.delete<ParentAttendanceController>();
        }
        Get.put(ParentAttendanceController());
        
      }),
    ),
    GetPage(
      name: AppRoutes.STUDENT_RECORDS,
      page: () => RoleAwareWrapper(child: const StudentRecordsView()),
      binding: StudentRecordBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: '/system-management',
      page: () => RoleAwareWrapper(child: SystemManagementView()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SystemManagementController());
      }),
    ),
    GetPage(
      name: '/finance_transactions',
      page: () => RoleAwareWrapper(child: FinanceDashboardView()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FinanceLedgerController());
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
      page: () =>  ProfileSelection(),
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
      binding: BindingsBuilder(() {
        // No binding needed for this view
      }),
    ),
    GetPage(
      name: '/notifications',
      page: () => RoleAwareWrapper(child: const NotificationsView()),
    ),
    GetPage(
      name: AppRoutes.TIMETABLE_MANAGEMENT,
      page: () => RoleAwareWrapper(child: TimeTablePage()),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.HOMEWORK_MANAGEMENT,
      page: () => RoleAwareWrapper(child: AssignmentUI()),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: '/receipt_detail',
      page: () {
        final args = Get.arguments;
        if (args == null) {
          // Handle null arguments gracefully
          Get.back(); // Go back to previous screen
          Get.snackbar('Error', 'Receipt data not found', backgroundColor: Colors.red, colorText: Colors.white);
          return const SizedBox(); // Return empty widget
        }
        if (args is! Map<String, dynamic>) {
          Get.back();
          Get.snackbar('Error', 'Invalid receipt data format', backgroundColor: Colors.red, colorText: Colors.white);
          return const SizedBox();
        }
        return ReceiptDetailView(receiptData: args);
      },
      binding: StudentRecordBinding(),
    ),
  ];
}