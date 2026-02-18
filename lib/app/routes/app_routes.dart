import 'package:get/get.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/splash_view.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/students/views/students_view.dart';
import '../modules/students/bindings/students_binding.dart';
import '../modules/attendance/views/attendance_view.dart';
import '../modules/attendance/controllers/attendance_controller.dart';
import '../bindings/attendance_binding.dart';
import '../modules/communications/views/simple_communications_view.dart';
import '../modules/communications/bindings/communications_binding.dart';

class AppRoutes {
  static const String TIMETABLE_MANAGEMENT = '/timetable-management';
  static const String HOMEWORK_MANAGEMENT = '/homework-management';
  static const String SPLASH = '/splash';
  static const String LOGIN = '/login';
  static const String CREATE_SCHOOL = '/create-school';
  static const String SCHOOL_MANAGEMENT = '/school-management';
  static const String DASHBOARD = '/accounting-dashboard';
  static const String ACCOUNTING_DASHBOARD = '/accounting-dashboard';
  static const String FEE_COLLECTION = '/fee-collection';
  static const String EXPENSES = '/expenses';
  static const String FEE_STRUCTURE = '/fee-structure';
  static const String REPORTS = '/reports';
  static const String STUDENT_MANAGEMENT = '/student-management';
  static const String ACADEMICS = '/academics';
  static const String COMMUNICATIONS = '/communications';
  static const String CLUBS_ACTIVITIES = '/clubs-activities';
  static const String CLUB_DETAIL = '/club-detail';
  static const String ATTENDANCE = '/attendance';
  static const String STUDENT_RECORDS = '/student-records';
  static const String SUBSCRIPTION_MANAGEMENT = '/subscription-management';
  static const String teacherClasses = '/my-classes';
  // Backward compatibility
  static const String timetableManagement = TIMETABLE_MANAGEMENT;
  static const String homeworkManagement = HOMEWORK_MANAGEMENT;
  static const String splash = SPLASH;
  static const String login = LOGIN;
  static const String createSchool = CREATE_SCHOOL;
  static const String schoolManagement = SCHOOL_MANAGEMENT;
  static const String dashboard = DASHBOARD;
  static const String accountingDashboard = ACCOUNTING_DASHBOARD;
  static const String feeCollection = FEE_COLLECTION;
  static const String expenses = EXPENSES;
  static const String feeStructure = FEE_STRUCTURE;
  static const String reports = REPORTS;
  static const String studentManagement = STUDENT_MANAGEMENT;
  static const String academics = ACADEMICS;
  static const String communications = COMMUNICATIONS;
  static const String clubsActivities = CLUBS_ACTIVITIES;
  static const String clubDetail = CLUB_DETAIL;
  static const String attendance = ATTENDANCE;
  static const String studentRecords = STUDENT_RECORDS;
  static const String subscriptionManagement = SUBSCRIPTION_MANAGEMENT;
  static const String transactiondetail = transactionDetail;
  static const String students = '/students';
  static const String announcements = '/announcements';
  static const String transactionDetail = '/transaction_detail';
  static const String receiptDetail = '/receipt_detail';

  static List<GetPage> routes = [
    GetPage(
      name: login,
      page: () =>  LoginView(),
    ),
    GetPage(
      name: dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: students,
      page: () =>  StudentsView(),
      binding: StudentsBinding(),
    ),
    GetPage(
      name: attendance,
      page: () => AttendanceView(),
      binding: OldAttendanceBinding(),
    ),
    GetPage(
      name: '${attendance}/student',
      page: () => AttendanceView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ParentAttendanceController>()) {
          Get.put(ParentAttendanceController());
        }
      }),
    ),
    GetPage(
      name: announcements,
      page: () => const SimpleCommunicationsView(),
      binding: CommunicationsBinding(),
    ),
  ];
}
