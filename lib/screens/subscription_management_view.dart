import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/subscription_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/services/subscription_service.dart';
import 'package:school_app/widgets/api_rbac_wrapper.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

// ── Design tokens (mirrors admin_sidebar.dart) ────────────────────────────────
const _kBg          = Color(0xFFFFFFFF);
const _kPageBg      = Color(0xFFF0F5FF);
const _kBorderColor = Color(0xFFDDE6F5);
const _kSelectedBg  = Color(0xFFEFF6FF);
const _kSelectedClr = Color(0xFF2563EB);
const _kIconDefault = Color(0xFF8A9FC0);
const _kTextDefault = Color(0xFF1A2A3A);
const _kLabelColor  = Color(0xFF90A4BE);
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionManagementView extends GetView<SubscriptionController> {
  const SubscriptionManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    // Resolve school from the sidebar's SchoolController
    final schoolController = Get.find<SchoolController>();
    final authController   = Get.find<AuthController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final school = schoolController.selectedSchool.value;
      if (school != null) {
        controller.loadSubscription(school.id);
      } else {
        final schoolId = authController.user.value?.schoolId;
        if (schoolId != null) controller.loadSubscription(schoolId);
      }
    });

    // Re-load whenever the sidebar school changes
    ever(schoolController.selectedSchool, (school) {
      if (school != null) controller.loadSubscription(school.id);
    });

    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(isTablet: isTablet, schoolController: schoolController),
            Expanded(
              child: _SubscriptionBody(
                controller: controller,
                isTablet: isTablet,
                schoolController: schoolController,
                authController: authController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page header ───────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final bool isTablet;
  final SchoolController schoolController;

  const _PageHeader({required this.isTablet, required this.schoolController});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: _kBorderColor.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kSelectedClr.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.subscriptions_rounded,
              color: _kSelectedClr,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Title + school name
          Expanded(
            child: Obx(() {
              final schoolName =
                  schoolController.selectedSchool.value?.name ?? '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Subscription Management',
                    style: TextStyle(
                      color: _kTextDefault,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (schoolName.isNotEmpty)
                    Text(
                      schoolName,
                      style: const TextStyle(
                        color: _kLabelColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    const Text(
                      'Manage plans and modules',
                      style: TextStyle(color: _kLabelColor, fontSize: 11),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _SubscriptionBody extends StatelessWidget {
  final SubscriptionController controller;
  final bool isTablet;
  final SchoolController schoolController;
  final AuthController authController;

  const _SubscriptionBody({
    required this.controller,
    required this.isTablet,
    required this.schoolController,
    required this.authController,
  });

  String? get _resolvedSchoolId =>
      schoolController.selectedSchool.value?.id ??
          authController.user.value?.schoolId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _kSelectedClr),
              SizedBox(height: 14),
              Text(
                'Loading subscription…',
                style: TextStyle(color: _kLabelColor, fontSize: 13),
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _CurrentPlanCard(controller: controller, isTablet: isTablet),
            const SizedBox(height: 16),
            _AvailablePlansSection(
              controller: controller,
              isTablet: isTablet,
              schoolId: _resolvedSchoolId,
            ),
          ],
        ),
      );
    });
  }
}

// ── Current plan card ─────────────────────────────────────────────────────────

class _CurrentPlanCard extends StatelessWidget {
  final SubscriptionController controller;
  final bool isTablet;

  const _CurrentPlanCard(
      {required this.controller, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: _kBorderColor.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: _kSelectedBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: _kBorderColor)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kSelectedClr.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: _kSelectedClr,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Current Subscription',
                  style: TextStyle(
                    color: _kTextDefault,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Status body
          Padding(
            padding: const EdgeInsets.all(16),
            child: _CurrentPlanBody(
                controller: controller, isTablet: isTablet),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanBody extends StatelessWidget {
  final SubscriptionController controller;
  final bool isTablet;

  const _CurrentPlanBody(
      {required this.controller, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status  = controller.getSubscriptionStatus();
      final modules = status['modules'] as Map<String, dynamic>;
      final plan    = status['plan'].toString().toUpperCase();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kSelectedClr.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _kSelectedClr.withOpacity(0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    size: 14, color: _kSelectedClr),
                const SizedBox(width: 6),
                Text(
                  plan,
                  style: const TextStyle(
                    color: _kSelectedClr,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Enabled Modules',
            style: TextStyle(
              color: _kLabelColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modules.entries.map((e) {
              final enabled = e.value as bool;
              return _ModuleChip(
                label: _formatModuleName(e.key),
                enabled: enabled,
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}

// ── Available plans section ───────────────────────────────────────────────────

class _AvailablePlansSection extends StatelessWidget {
  final SubscriptionController controller;
  final bool isTablet;
  final String? schoolId;

  const _AvailablePlansSection({
    required this.controller,
    required this.isTablet,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return ApiRbacWrapper(
      apiEndpoint: 'PUT /api/subscription/update',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 12),
            child: Text(
              'Available Plans',
              style: TextStyle(
                color: _kTextDefault,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _PlanCards(
              controller: controller,
              isTablet: isTablet,
              schoolId: schoolId),
          const SizedBox(height: 16),
          _CustomPlanCard(
              controller: controller,
              isTablet: isTablet,
              schoolId: schoolId),
        ],
      ),
      fallback: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSelectedBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kSelectedClr.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: _kSelectedClr, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Only correspondents can manage subscriptions.',
                style: TextStyle(
                  color: _kTextDefault,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan cards ────────────────────────────────────────────────────────────────

class _PlanCards extends StatelessWidget {
  final SubscriptionController controller;
  final bool isTablet;
  final String? schoolId;

  const _PlanCards({
    required this.controller,
    required this.isTablet,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    const plans = ['basic', 'standard', 'premium'];

    return Column(
      children: plans.map((plan) {
        final modules = SubscriptionService.packages[plan]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: _kBorderColor.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: _kSelectedBg,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(14)),
                  border: Border(
                      bottom: BorderSide(color: _kBorderColor)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _kSelectedClr.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded,
                          color: _kSelectedClr, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        plan.toUpperCase(),
                        style: const TextStyle(
                          color: _kTextDefault,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Obx(() {
                      final isCurrent =
                          controller.getCurrentPlan() == plan;
                      return GestureDetector(
                        onTap: isCurrent
                            ? null
                            : () => _updateToPlan(plan, schoolId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? _kSelectedClr.withOpacity(0.10)
                                : _kSelectedClr,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCurrent
                                  ? _kSelectedClr.withOpacity(0.3)
                                  : _kSelectedClr,
                            ),
                          ),
                          child: Text(
                            isCurrent ? 'Current' : 'Select',
                            style: TextStyle(
                              color: isCurrent
                                  ? _kSelectedClr
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Modules
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: modules.entries.map((e) => _ModuleChip(
                    label: _formatModuleName(e.key),
                    enabled: e.value,
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _updateToPlan(String planName, String? schoolId) async {
    if (schoolId == null) {
      Get.snackbar('Error', 'No school selected');
      return;
    }
    final success = await controller.updateSubscription(
        schoolId: schoolId, planName: planName);
    if (success) {
      Get.snackbar('Success', 'Subscription updated to $planName plan');
    }
  }
}

// ── Custom plan card ──────────────────────────────────────────────────────────

class _CustomPlanCard extends StatelessWidget {
  final SubscriptionController controller;
  final bool isTablet;
  final String? schoolId;

  const _CustomPlanCard({
    required this.controller,
    required this.isTablet,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    final modules = [
      'studentRecord',
      'attendance',
      'expense',
      'club',
      'announcement'
    ];
    final customModules = <String, bool>{}.obs;
    final currentModules = controller.getEnabledModules();
    for (final m in modules) {
      customModules[m] = currentModules[m] ?? false;
    }

    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: _kBorderColor.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _kSelectedBg,
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(14)),
              border:
              Border(bottom: BorderSide(color: _kBorderColor)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _kSelectedClr.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: _kSelectedClr, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'CUSTOM PLAN',
                  style: TextStyle(
                    color: _kTextDefault,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          // Module toggles
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              children: modules.map((module) {
                return Obx(() => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: customModules[module] == true
                        ? _kSelectedBg
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: customModules[module] == true
                          ? _kBorderColor
                          : const Color(0xFFEEEEEE),
                    ),
                  ),
                  child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    _formatModuleName(module),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: customModules[module] == true
                          ? _kSelectedClr
                          : _kTextDefault,
                    ),
                  ),
                  trailing: Transform.scale(
                    scale: 0.8, // <--- Adjust this value (e.g., 0.8 = 80% of original size)
                    child: Checkbox(
                      value: customModules[module] ?? false,
                      activeColor: _kSelectedClr,
                      checkColor: Colors.white,
                      onChanged: (v) => customModules[module] = v ?? false,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)), // Slightly smaller radius looks better scaled down
                      side: BorderSide(
                        color: customModules[module] == true
                            ? _kSelectedClr
                            : _kIconDefault,
                      ),
                    ),
                  ),
                  onTap: () {
                    // Allows clicking the whole row to toggle, just like CheckboxListTile did
                    customModules[module] = !(customModules[module] ?? false);
                  },
                ),
                ));
              }).toList(),
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              onTap: () => _applyCustom(customModules, schoolId),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: _kSelectedClr,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Apply Custom Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyCustom(RxMap<String, bool> modules, String? schoolId) async {
    if (schoolId == null) {
      Get.snackbar('Error', 'No school selected');
      return;
    }
    final success = await Get.find<SubscriptionController>().updateSubscription(
      schoolId: schoolId,
      planName: 'custom',
      customModules: Map<String, bool>.from(modules),
    );
    if (success) {
      Get.snackbar('Success', 'Custom subscription plan applied');
    }
  }
}

// ── Shared chip widget ────────────────────────────────────────────────────────

class _ModuleChip extends StatelessWidget {
  final String label;
  final bool enabled;

  const _ModuleChip({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: enabled
            ? _kSelectedClr.withOpacity(0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? _kSelectedClr.withOpacity(0.25)
              : const Color(0xFFDDDDDD),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 13,
            color: enabled ? _kSelectedClr : _kIconDefault,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: enabled ? _kSelectedClr : _kIconDefault,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatModuleName(String key) {
  return key
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
      .toUpperCase()
      .trim();
}