import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/eb_controller.dart';
import 'package:school_app/screens/tariff_form_page.dart';

import '../controllers/auth_controller.dart';
import '../controllers/school_controller.dart';
import '../core/permissions/eb_permissions.dart';

/// Mobile "Tariff Configuration" screen restyled with clean white and blue theme system.
class TariffListScreen extends StatefulWidget {
  const TariffListScreen({super.key});

  @override
  State<TariffListScreen> createState() => _TariffListScreenState();
}

class _TariffListScreenState extends State<TariffListScreen> {
  final EBController ebController = Get.find();
  final TextEditingController _searchController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();

  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;

  // Theme Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlueBg = Color(0xFFEFF6FF);
  static const Color amberYellow = Color(0xFFD97706);
  static const Color lightAmberBg = Color(0xFFFEF3C7);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  String get role => _authController.user.value?.role?.toLowerCase() ?? '';

  String get schoolId {
    if (role == 'correspondent') {
      return _school?.selectedSchool.value?.id ?? '';
    } else {
      return _authController.user.value?.schoolId ?? '';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (schoolId.isNotEmpty) {
      ebController.getAllTariffs(schoolId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(String tariffId, String tariffName) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Tariff Plan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
        ),
        content: Text(
          'Are you sure you want to delete "$tariffName"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontSize: 13, color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Get.back();
              final success = await ebController.deleteTariff(schoolId, tariffId);
              if (success) _loadData();
            },
            child: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openTariffForm([Map<String, dynamic>? existingTariff]) async {
    final result = await Get.to(() => TariffFormScreen(
      schoolId: schoolId,
      existingTariff: existingTariff,
    ));
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tariff Configuration',
              style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Define electricity pricing slabs and fixed charges',
              style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (EBPermissions.canEditTariffs(role))
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _openTariffForm(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Tariff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: textDark),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search tariff name...',
                  hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20, color: textMuted),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryBlue)),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Obx(() {
                  if (ebController.isLoading.value && ebController.tariffs.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: primaryBlue));
                  }

                  final query = _searchController.text.trim().toLowerCase();
                  final filteredTariffs = ebController.tariffs.where((t) {
                    final name = (t['tariffName'] ?? '').toString().toLowerCase();
                    return query.isEmpty || name.contains(query);
                  }).toList();

                  if (filteredTariffs.isEmpty) {
                    return const Center(
                      child: Text('No tariffs configured', style: TextStyle(color: textMuted, fontSize: 13)),
                    );
                  }

                  return RefreshIndicator(
                    color: primaryBlue,
                    onRefresh: () async => _loadData(),
                    child: ListView.separated(
                      itemCount: filteredTariffs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tariff = filteredTariffs[index];
                        final String id = (tariff['_id'] ?? tariff['id'] ?? '').toString();
                        final String name = tariff['tariffName'] ?? 'Unnamed Plan';
                        final num fixedCharge = tariff['fixedChargePerKw'] ?? 0;
                        final List slabs = tariff['slabs'] is List ? tariff['slabs'] : [];

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: lightAmberBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.bolt, color: amberYellow, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                                          ),
                                        ),
                                        if (EBPermissions.canEditTariffs(role))
                                          IconButton(
                                            onPressed: () => _openTariffForm(tariff),
                                            icon: const Icon(Icons.edit_outlined, size: 18, color: textMuted),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        if (EBPermissions.canEditTariffs(role) && EBPermissions.canDeleteTariffs(role))
                                          const SizedBox(width: 10),
                                        if (EBPermissions.canDeleteTariffs(role))
                                          IconButton(
                                            onPressed: () => _confirmDelete(id, name),
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Fixed: ₹${fixedCharge.toStringAsFixed(2)} / kW',
                                        style: const TextStyle(color: textMuted, fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: lightBlueBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${slabs.length} ${slabs.length == 1 ? 'Slab' : 'Slabs'}',
                                        style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}