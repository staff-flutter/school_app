import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/accounting_controller.dart';
import 'package:school_app/controllers/finance_ledger_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';
import 'package:school_app/routes/app_routes.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/role_modules.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/screens/notifications_view.dart';

class AccountingDashboardView extends StatefulWidget {
  const AccountingDashboardView({super.key});

  @override
  State<AccountingDashboardView> createState() => _AccountingDashboardViewState();
}

class _AccountingDashboardViewState extends State<AccountingDashboardView> {
  final AuthController _authController = Get.find<AuthController>();
  final FinanceLedgerController _financeController = Get.find<FinanceLedgerController>();

  @override
  void initState() {
    super.initState();
    // Defer API call until after build is complete to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinanceStats();
    });
  }

  void _loadFinanceStats() {
    final userRole = _authController.user.value?.role.toLowerCase() ?? '';
    if (userRole == 'correspondent' || userRole == 'accountant') {
      final schoolId = _authController.user.value?.schoolId;
      if (schoolId != null) {
        _financeController.getFinanceStats(schoolId: schoolId, range: 'today');
      }
    }
  }

  void _showFullScreenProfileImage() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (_authController.user.value?.userName ?? 'U').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 120,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 40,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenSchoolLogo(String logoUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        Get.back();
                        Get.snackbar(
                          'Error',
                          'Failed to load logo',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolLogo() {
    try {
      final school = _authController.userSchool.value;
      if (school != null && school['logo'] != null && school['logo']['url'] != null) {
        return GestureDetector(
          onTap: () => _showFullScreenSchoolLogo(school['logo']['url']),
          child: Image.network(
            school['logo']['url'],
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.school,
                color: Colors.white,
                size: 32,
              );
            },
          ),
        );
      }
    } catch (e) {
      
    }

    return const Icon(
      Icons.school,
      color: AppTheme.primaryText,
      size: 32,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.dividerColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              title: Row(
                children: [
                  _buildSchoolLogo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(() {
                          final school = _authController.userSchool.value;
                          final schoolName = school?['name'] ?? 'School';
                          return Text(
                            schoolName,
                            style: const TextStyle(
                              color: AppTheme.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }),
                        Text(
                          'Welcome, ${_authController.user.value?.userName ?? 'User'}',
                          style: const TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.appBackground,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification Icon - only for correspondent
                      if (_authController.user.value?.role.toLowerCase() != 'accountant')
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            onPressed: () {
                              Get.to(() => const NotificationsView());
                            },
                            icon: Stack(
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  color: AppTheme.primaryText,
                                  size: 24,
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 8,
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Profile Menu

                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      body: ResponsiveWrapper(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Show finance stats for correspondent and accountant
            _buildFinanceStatsSection(),

            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getModuleSectionTitle(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildModulesGrid(context),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildFinanceStatsSection() {
    final userRole = _authController.user.value?.role.toLowerCase() ?? '';
    if (userRole != 'correspondent' && userRole != 'accountant') {
      return const SizedBox();
    }

    return Obx(() {
      final stats = _financeController.stats.value;
      final isLoading = _financeController.isLoading.value;

      if (isLoading || stats == null) {
        return ResponsiveCard(
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }

        return ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Financial Overview (Today)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Display cards in responsive rows
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;

                  if (availableWidth >= 800) {
                    // Large screens: 4 cards in a row
                    return Row(
                      children: [
                        Expanded(child: _buildStatCard('Total Income', stats['totalIncome'] ?? 0,
                            Colors.green, Icons.trending_up)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Total Expense', stats['totalExpense'] ?? 0,
                            Colors.red, Icons.trending_down)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Net Balance', stats['netBalance'] ?? 0,
                            Colors.blue, Icons.account_balance)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Transaction Count', stats['transactionCount'] ?? 0,
                            Colors.indigo, Icons.countertops)),
                      ],
                    );
                  } else if (availableWidth >= 600) {
                    // Medium screens: 2 rows of 2 cards each
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Total Income', stats['totalIncome'] ?? 0,
                                Colors.green, Icons.trending_up)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('Total Expense', stats['totalExpense'] ?? 0,
                                Colors.red, Icons.trending_down)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Net Balance', stats['netBalance'] ?? 0,
                                Colors.blue, Icons.account_balance)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('Transaction Count', stats['transactionCount'] ?? 0,
                                Colors.indigo, Icons.countertops)),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Small screens: Vertical stack
                    return Column(
                      children: [
                        _buildStatCard('Total Income', stats['totalIncome'] ?? 0,
                            Colors.green, Icons.trending_up),
                        const SizedBox(height: 12),
                        _buildStatCard('Total Expense', stats['totalExpense'] ?? 0,
                            Colors.red, Icons.trending_down),
                        const SizedBox(height: 12),
                        _buildStatCard('Net Balance', stats['netBalance'] ?? 0,
                            Colors.blue, Icons.account_balance),
                        const SizedBox(height: 12),
                        _buildStatCard('Transaction Count', stats['transactionCount'] ?? 0,
                            Colors.indigo, Icons.countertops),
                      ],
                    );
                  }
                },
              )

            ],
          ),
        );
      });
  }

  Widget _buildStatCard(String title, dynamic value, Color color, IconData icon){
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;

    final formattedValue =
    value is num ? '₹${value.toStringAsFixed(0)}' : '₹0';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final padding = width * 0.08;
        final iconSize = width * 0.12;
        final titleSize = width * 0.085;
        final valueSize = width * 0.15;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(padding * 0.5),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: padding * 0.6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: isLandscape ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.titleOnWhite,
                        ),
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formattedValue,
                    style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getModuleSectionTitle() {
    final userRole = _authController.user.value?.role.toLowerCase() ?? '';
    switch (userRole) {

      case 'principal':
      case 'viceprincipal':
      case 'administrator':
        return 'Academic Modules';
      case 'teacher':
        return 'Teaching Modules';
      case 'parent':
        return 'Available Services';
      default:
        return 'Available Modules';
    }
  }

  Widget _buildModulesGrid(BuildContext context) {
    final userRole = _authController.user.value?.role.toLowerCase() ?? '';

    final allModules = <AccountingModule>[];

    if (ApiPermissions.hasApiAccess(userRole, 'POST /api/user/create'))
      allModules.add(AccountingModule(userRole == 'teacher' ? 'Attendance' : 'Users', Icons.people, AppTheme.primaryGradient, '${AppRoutes.SCHOOL_MANAGEMENT}?initialTab=users'));
    if (RoleModules.hasModule(userRole, 'teachers'))
      allModules.add(AccountingModule('Teachers', Icons.folder, AppTheme.errorGradient, '${AppRoutes.SCHOOL_MANAGEMENT}?initialTab=teachers'));
    if (RoleModules.hasModule(userRole, 'transactions'))
      allModules.add(AccountingModule('Transactions', Icons.how_to_reg, AppTheme.warningGradient, '/finance_transactions'));
    if (RoleModules.hasModule(userRole, 'feeCollection'))
      allModules.add(AccountingModule('Fee Collection', Icons.payment, AppTheme.successGradient, AppRoutes.FEE_COLLECTION));
    if (RoleModules.hasModule(userRole, 'expenses'))
      allModules.add(AccountingModule('Expenses', Icons.receipt_long, AppTheme.errorGradient, AppRoutes.EXPENSES));
    if (RoleModules.hasModule(userRole, 'feeStructure'))
      allModules.add(AccountingModule('Fee Structure', Icons.settings, LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange.shade300]), '${AppRoutes.SCHOOL_MANAGEMENT}?initialTab=fees'));
    if (RoleModules.hasModule(userRole, 'reports'))
      allModules.add(AccountingModule('Reports', Icons.analytics, AppTheme.warningGradient, '/system-management'));
    // Only show Communications module if user can create announcements
    if (RoleModules.hasModule(userRole, 'announcements') && ApiPermissions.canCreateAnnouncement(userRole))
      allModules.add(AccountingModule('Communications', Icons.announcement, AppTheme.TealGradient, AppRoutes.COMMUNICATIONS));
    if (RoleModules.hasModule(userRole, 'clubs'))
      allModules.add(AccountingModule('Clubs', Icons.sports, LinearGradient(colors: [Colors.lightBlue, Colors.lightBlue.shade300]), AppRoutes.CLUBS_ACTIVITIES));
    if (RoleModules.hasModule(userRole, 'studentRecords'))
      allModules.add(AccountingModule('Student Records', Icons.folder,  AppTheme.successGradient, AppRoutes.STUDENT_RECORDS));

    if (allModules.isEmpty) {
      return const Center(child: Text('No modules available for your role'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: allModules.length,
          itemBuilder: (context, index) => _buildModuleCard(context, allModules[index]),
        );
      },
    );
  }

  Widget _buildModuleCard(BuildContext context, AccountingModule module) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            module.gradient.colors.first.withOpacity(0.08),
            module.gradient.colors.last.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: module.gradient.colors.first.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed(module.route);
          },
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: module.gradient.colors.first.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(module.icon, color: module.gradient.colors.first, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  module.title,
                  style: const TextStyle(
                    color: AppTheme.titleOnWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AccountingModule {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final String route;

  AccountingModule(this.title, this.icon, this.gradient, this.route);
}

