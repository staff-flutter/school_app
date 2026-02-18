import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/services/subscription_service.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/data/services/api_service.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/modules/accounting/controllers/accounting_controller.dart';
import 'app/modules/dashboard/controllers/dashboard_controller.dart';
import 'app/controllers/theme_controller.dart';
import 'app/controllers/school_controller.dart';
import 'app/controllers/main_navigation_controller.dart';
import 'app/controllers/subscription_controller.dart';
import 'app/controllers/club_controller.dart';
import 'app/controllers/finance_ledger_controller.dart';
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await GetStorage.init();
//
//   // Initialize core services
//   Get.put(ApiService(), permanent: true);
//   Get.put(AuthController(), permanent: true);
//   Get.put(AccountingController(), permanent: true);
//
//   runApp(SchoolApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  
  // Initialize core services and controllers
  Get.put(ApiService(), permanent: true);
  Get.put(SubscriptionService(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(AccountingController(), permanent: true);
  Get.put(DashboardController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  Get.put(SchoolController(), permanent: true);
  Get.put(MainNavigationController(), permanent: true);
  Get.put(SubscriptionController(), permanent: true);
  Get.put(ClubController(), permanent: true);
  Get.put(FinanceLedgerController(), permanent: true);
  
  runApp(SchoolApp());
}

class SchoolApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'School Management',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.SPLASH, // Start with splash screen for auth check
      getPages: [
        ...AppPages.routes,
        GetPage(
          name: '/demo',
          page: () => DemoRoleSelectionScreen(),
        ),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}

// Demo role selection for development - access via /demo route
class DemoRoleSelectionScreen extends StatelessWidget {
  final List<Map<String, String>> roles = [
    {'role': 'correspondent', 'name': 'Correspondent', 'desc': 'Full system access'},
    {'role': 'administrator', 'name': 'Administrator', 'desc': 'System admin without finance'},
    {'role': 'principal', 'name': 'Principal', 'desc': 'Academic oversight'},
    {'role': 'viceprincipal', 'name': 'Vice Principal', 'desc': 'Support role'},
    {'role': 'teacher', 'name': 'Teacher', 'desc': 'Class-scoped access'},
    {'role': 'accountant', 'name': 'Accountant', 'desc': 'Finance-only access'},
    {'role': 'parent', 'name': 'Parent', 'desc': 'Child-scoped read-only'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 600),
                margin: EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, size: 48, color: AppTheme.primaryBlue),
                        SizedBox(height: 16),
                        Text(
                          'School Management System',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Select Role to Login (Demo)',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ...roles.map((role) => Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 8),
                          child: ElevatedButton(
                            onPressed: () => Get.toNamed(AppRoutes.LOGIN),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  role['name']!,

                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  role['desc']!,
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}