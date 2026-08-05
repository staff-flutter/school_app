import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/eb_controller.dart';
import 'package:school_app/screens/tariff_form_page.dart';

import '../controllers/auth_controller.dart';
import '../controllers/school_controller.dart';
import '../core/permissions/eb_permissions.dart';

class TariffListScreen extends StatefulWidget {

  const TariffListScreen({
    super.key,
  });

  @override
  State<TariffListScreen> createState() => _TariffListScreenState();
}

class _TariffListScreenState extends State<TariffListScreen> {
  final EBController ebController = Get.find();
  final TextEditingController _searchController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;
  String get role => _authController.user.value?.role?.toLowerCase() ?? '';

  // Correctly resolution of schoolId based on user role
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
        title: const Text('Delete Tariff Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$tariffName"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Get.back();
              final success = await ebController.deleteTariff(schoolId, tariffId);
              if (success) _loadData();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tariff Configuration',
              style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Define electricity pricing slabs and fixed charges',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header Actions Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search tariff name...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openTariffForm(),
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('Create Tariff', style: TextStyle(fontSize: 13, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF323B4A),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tariff List Section
          Expanded(
            child: Obx(() {
              if (ebController.isLoading.value && ebController.tariffs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final query = _searchController.text.trim().toLowerCase();
              final filteredTariffs = ebController.tariffs.where((t) {
                final name = (t['tariffName'] ?? '').toString().toLowerCase();
                return query.isEmpty || name.contains(query);
              }).toList();

              if (filteredTariffs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No tariffs configured', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadData(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTariffs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tariff = filteredTariffs[index];
                    final String id = (tariff['_id'] ?? tariff['id'] ?? '').toString();
                    final String name = tariff['tariffName'] ?? 'Unnamed Plan';
                    final num fixedCharge = tariff['fixedChargePerKw'] ?? 0;
                    final List slabs = tariff['slabs'] is List ? tariff['slabs'] : [];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.bolt, color: Colors.amber, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${fixedCharge.toStringAsFixed(2)} / kW',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              '${slabs.length} Slabs',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (EBPermissions.canEditTariffs(role))
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                              onPressed: () => _openTariffForm(tariff),
                            ),
                          if (EBPermissions.canDeleteTariffs(role))
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              onPressed: () => _confirmDelete(id, name),
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
    );
  }
}