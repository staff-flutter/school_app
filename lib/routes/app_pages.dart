import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/finance_ledger_controller.dart';
import 'package:school_app/screens/finance_dashboard_view.dart';
import 'package:school_app/controllers/parent_attendance_controller.dart';
import 'package:school_app/screens/attendance_view.dart';
import 'package:school_app/screens/teacher_classes_view.dart';
import 'package:school_app/screens/transaction_detail_view.dart';
import 'package:school_app/screens/receipt_detail_view.dart';
import 'package:school_app/screens/notifications_view.dart';
import 'package:school_app/screens/details_of_student_view.dart';
import 'package:school_app/routes/app_routes.dart';
import 'package:school_app/bindings/auth_binding.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/screens/login_view.dart';
import 'package:school_app/screens/splash_view.dart';
import 'package:school_app/screens/create_school_view.dart';
import 'package:school_app/screens/school_management_view.dart';
import 'package:school_app/controllers/student_management_controller.dart';
import 'package:school_app/bindings/dashboard_binding.dart';
import 'package:school_app/bindings/accounting_binding.dart';
import 'package:school_app/screens/accounting_dashboard_view.dart';
import 'package:school_app/screens/fee_collection_tabbed_view.dart';
import 'package:school_app/screens/expenses_view.dart';
import 'package:school_app/screens/fee_structure_view.dart';
import 'package:school_app/screens/reports_view.dart';
import 'package:school_app/bindings/student_binding.dart';

import 'package:school_app/bindings/academics_binding.dart';
import 'package:school_app/screens/academics_view.dart';
import 'package:school_app/bindings/communications_binding.dart';
import 'package:school_app/screens/communications_view.dart';
import 'package:school_app/bindings/clubs_binding.dart';
import 'package:school_app/screens/clubs_activities_view.dart';
import 'package:school_app/screens/club_detail_view.dart';
import 'package:school_app/screens/profile_view.dart';
import 'package:school_app/screens/privacy_policy_view.dart';
import 'package:school_app/screens/delete_account_view.dart';
import 'package:school_app/screens/parent_attendance_view.dart';
import 'package:school_app/bindings/old_attendance_binding.dart';
import 'package:school_app/bindings/parent_attendance_binding.dart' as module_attendance_binding;
import 'package:school_app/screens/student_records_view.dart';
import 'package:school_app/bindings/student_record_binding.dart';
import 'package:school_app/screens/subscription_management_view.dart';
import 'package:school_app/bindings/subscription_binding.dart';
import 'package:school_app/screens/my_children_view.dart';
import 'package:school_app/controllers/my_children_controller.dart';
import 'package:school_app/screens/system_management_view.dart';
import 'package:school_app/controllers/system_management_controller.dart';
import 'package:school_app/screens/timetable_management_view.dart';
import 'package:school_app/screens/homework_management_view.dart';
import 'package:school_app/widgets/main_wrapper.dart';
import 'package:school_app/middleware/role_guard.dart';

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
      page: () => MainWrapper(child: AttendanceView()),
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
