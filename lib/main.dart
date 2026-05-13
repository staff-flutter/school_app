import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'core/theme/app_theme.dart';
import 'services/subscription_service.dart';
import 'services/user_session.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/accounting_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/school_controller.dart';
import 'controllers/main_navigation_controller.dart';
import 'controllers/subscription_controller.dart';
import 'controllers/club_controller.dart';
import 'controllers/finance_ledger_controller.dart';
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
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
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


  final session = Get.put(UserSession(), permanent: true);
  await session.loadSession();


  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {

    runApp(
        DevicePreview(
          enabled: false,
          builder: (context) => SchoolApp(),
        ),);
  });}

class SchoolApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    return GetMaterialApp(
     // this below three lines are to check with all screen sizes
     // useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        // ✅ Wrap DevicePreview builder AND force status bar
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ));
        return DevicePreview.appBuilder(context, child);
      },
      title: 'School Management',
      //theme: AppTheme.lightTheme,
      theme: ThemeData(
        useMaterial3: true,
        // This creates a full blue color scheme based on your primary blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff4A90E2),
          primary: const Color(0xff4A90E2),
        ),
        // Specifically targets progress indicators if they don't follow the seed
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xff4A90E2),
        ),
      ),
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