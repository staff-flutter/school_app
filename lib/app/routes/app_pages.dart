import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/app/controllers/finance_ledger_controller.dart';
import 'package:school_app/app/views/finance_dashboard_view.dart';
import '../modules/attendance/controllers/attendance_controller.dart';
import '../modules/attendance/views/attendance_view.dart';
import '../views/teacher_classes_view.dart';
import '../views/transaction_detail_view.dart';
import '../modules/accounting/views/receipt_detail_view.dart';
import '../modules/accounting/views/notifications_view.dart';
import '../views/details_of_student_view.dart';
import 'app_routes.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/splash_view.dart';
import '../modules/auth/views/create_school_view.dart';
import '../views/school_management_view.dart';
import '../controllers/student_management_controller.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/accounting/bindings/accounting_binding.dart';
import '../modules/accounting/views/accounting_dashboard_view.dart';
import '../modules/accounting/views/fee_collection_tabbed_view.dart';
import '../modules/accounting/views/expenses_view.dart';
import '../modules/accounting/views/fee_structure_view.dart';
import '../modules/accounting/views/reports_view.dart';
import '../modules/students/bindings/student_binding.dart';

import '../modules/academics/bindings/academics_binding.dart';
import '../modules/academics/views/academics_view.dart';
import '../modules/communications/bindings/communications_binding.dart';
import '../modules/communications/views/communications_view.dart';
import '../modules/clubs/bindings/clubs_binding.dart';
import '../modules/clubs/views/clubs_activities_view.dart';
import '../modules/clubs/views/club_detail_view.dart';
import '../views/profile_view.dart';
import '../views/privacy_policy_view.dart';
import '../views/delete_account_view.dart';
import '../views/attendance_view.dart';
import '../bindings/attendance_binding.dart';
import '../modules/attendance/bindings/attendance_binding.dart' as module_attendance_binding;
import '../views/student_records_view.dart';
import '../bindings/student_record_binding.dart';
import '../views/subscription_management_view.dart';
import '../bindings/subscription_binding.dart';
import '../views/my_children_view.dart';
import '../controllers/my_children_controller.dart';
import '../views/system_management_view.dart';
import '../controllers/system_management_controller.dart';
import '../views/timetable_management_view.dart';
import '../views/homework_management_view.dart';
import '../widgets/main_wrapper.dart';
import '../middleware/role_guard.dart';

class AppPages {

  static final routes = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashView(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.CREATE_SCHOOL,
      page: () => CreateSchoolView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.SCHOOL_MANAGEMENT,
      page: () => MainWrapper(child: SchoolManagementView()),
    ),
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => MainWrapper(child: AccountingDashboardView()),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: '/teacher-classes',
      page: () => MainWrapper(child: const TeacherClassesView()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => StudentManagementController());
      }),
    ),
    GetPage(
      name: AppRoutes.ACCOUNTING_DASHBOARD,
      page: () => MainWrapper(child: AccountingDashboardView()),
      binding: AccountingBinding(),
    ),
    GetPage(
      name: AppRoutes.FEE_COLLECTION,
      page: () => MainWrapper(child: FeeCollectionTabbedView()),
      binding: AccountingBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.EXPENSES,
      page: () => MainWrapper(child: ExpensesView()),
      binding: AccountingBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.FEE_STRUCTURE,
      page: () => MainWrapper(child: FeeStructureView()),
      binding: AccountingBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.REPORTS,
      page: () => MainWrapper(child: ReportsView(),),
      binding: AccountingBinding(),
      middlewares: [RoleGuard()],
    ),
    // GetPage(
    //   name: AppRoutes.STUDENT_MANAGEMENT,
    //   page: () => MainWrapper(child: StudentManagementView()),
    //   binding: StudentBinding(),
    //   middlewares: [RoleGuard()],
    // ),
    // GetPage(
    //   name: '/students',
    //   page: () => MainWrapper(child: StudentManagementView()),
    //   binding: StudentBinding(),
    //   middlewares: [RoleGuard()],
    // ),
    GetPage(
      name: AppRoutes.ACADEMICS,
      page: () => MainWrapper(child: AcademicsView()),
      binding: AcademicsBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.COMMUNICATIONS,
      page: () => MainWrapper(child: CommunicationsView()),
      binding: CommunicationsBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.CLUBS_ACTIVITIES,
      page: () => MainWrapper(child: const ClubsActivitiesView()),
      binding: ClubsBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.CLUB_DETAIL,
      page: () => MainWrapper(child: const ClubDetailView()),
      binding: ClubsBinding(),
    ),
    GetPage(
      name: '/profile',
      page: () => MainWrapper(child: ProfileView()),
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
      page: () => MainWrapper(child: SchoolManagementView()),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.teacherClasses,
      page: () => const TeacherClassesView(),
    ),

    GetPage(
      name: '${AppRoutes.ATTENDANCE}/student',
      page: () => MainWrapper(child: const AttendanceView()),
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
      page: () => MainWrapper(child: const StudentRecordsView()),
      binding: StudentRecordBinding(),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: '/system-management',
      page: () => MainWrapper(child: SystemManagementView()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SystemManagementController());
      }),
    ),
    GetPage(
      name: '/finance_transactions',
      page: () => MainWrapper(child: FinanceDashboardView()),
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
      page: () => MainWrapper(child: const MyChildrenView()),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MyChildrenController());
      }),
    ),
    GetPage(
      name: AppRoutes.SUBSCRIPTION_MANAGEMENT,
      page: () => MainWrapper(child: const SubscriptionManagementView()),
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
      page: () => MainWrapper(child: const NotificationsView()),
    ),
    GetPage(
      name: AppRoutes.TIMETABLE_MANAGEMENT,
      page: () => MainWrapper(child: TimetableManagementView()),
      middlewares: [RoleGuard()],
    ),
    GetPage(
      name: AppRoutes.HOMEWORK_MANAGEMENT,
      page: () => MainWrapper(child: HomeworkManagementView()),
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
