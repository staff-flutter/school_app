import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/screens/accounting_dashboard_view.dart';
import 'package:school_app/screens/attendance_view.dart';
import 'package:school_app/screens/clubs_activities_view.dart';
import 'package:school_app/screens/login_view.dart';
import 'package:school_app/screens/student_management_view.dart';
import 'package:school_app/screens/parent_attendance_view.dart';

import 'package:school_app/screens/profile_view.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/accounting-dashboard';
  static const String clubs = '/clubs-activities';
  static const String students = '/student-management';
  static const String attendance = '/attendance';
  static const String fees = '/fee-collection';
  static const String profile = '/profile';
  static const String communications = '/communications';
  static const String expenses = '/expenses';
  static const String schools = '/school-management';

  static List<GetPage> routes = [
    GetPage(name: login, page: () => LoginView()),
    GetPage(name: dashboard, page: () => AccountingDashboardView()),
    GetPage(name: clubs, page: () => const ClubsActivitiesView()),
    GetPage(name: students, page: () =>StudentManagementView()),
    GetPage(name: attendance, page: () => AttendanceView()),
    // GetPage(name: fees, page: () => const FeeCollectionView()),
    GetPage(name: profile, page: () => ProfileView()),
    GetPage(name: communications, page: () => const Scaffold(body: Center(child: Text('Communications')))),
    GetPage(name: expenses, page: () => const Scaffold(body: Center(child: Text('Expenses')))),
    GetPage(name: schools, page: () => const Scaffold(body: Center(child: Text('Schools')))),
  ];
}