import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/eb_controller.dart';
import 'package:school_app/screens/premises_form_page.dart';

import '../controllers/school_controller.dart';

/// Mobile "Premises Directory" screen — mirrors the Fleet Directory (bus list)
/// styling: black "Register" pill button, rounded search bar, white rounded
/// cards with a light-blue icon avatar, status chip, and view/delete actions.
class PremisesListScreen extends StatefulWidget {
  const PremisesListScreen({super.key});

  @override
  State<PremisesListScreen> createState() => _PremisesListScreenState();
}

class _PremisesListScreenState extends State<PremisesListScreen> {
  final EBController ebController = Get.find();
  final TextEditingController _searchController = TextEditingController();
  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;
  final AuthController _authController = Get.find<AuthController>();
  String _statusFilter = 'All'; // All | Active | Inactive

  static const _cardRadius = 16.0;
  static const _lightBlue = Color(0xFFDCEBFC);
  static const _iconBlue = Color(0xFF3B82F6);
  static const _activeGreenBg = Color(0xFFDCFCE7);
  static const _activeGreenText = Color(0xFF16A34A);
  static const _inactiveGreyBg = Color(0xFFF1F1F1);
  static const _inactiveGreyText = Color(0xFF6B7280);

  // Getter to dynamic calculate role
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
    ebController.getAllPremises(schoolId);
  }

  List<Map<String, dynamic>> get _filteredPremises {
    final query = _searchController.text.trim().toLowerCase();
    return ebController.premisesList.where((p) {
      final matchesSearch = query.isEmpty ||
          (p['premisesName'] ?? '').toString().toLowerCase().contains(query) ||
          (p['consumerNumber'] ?? '').toString().toLowerCase().contains(query);
      final isActive = p['isActive'] == true;
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && isActive) ||
          (_statusFilter == 'Inactive' && !isActive);
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _openForm({Map<String, dynamic>? premises}) async {
    final result = await Get.to(() => PremisesFormScreen(
      schoolId: schoolId,
      existingPremises: premises,
    ));
    if (result == true) {
      ebController.getAllPremises(schoolId);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> premises) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Premises', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${premises['premisesName'] ?? ''}"? This cannot be undone.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final id = (premises['_id'] ?? premises['id']).toString();
      final ok = await ebController.deletePremises(schoolId, id);
      if (ok) ebController.getAllPremises(schoolId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Premises Directory',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Register Premises',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search name or consumer no...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Status filter pill
              Row(
                children: [
                  _StatusFilterPill(
                    value: _statusFilter,
                    onChanged: (v) => setState(() => _statusFilter = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // List
              Expanded(
                child: Obx(() {
                  if (ebController.isLoading.value && ebController.premisesList.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = _filteredPremises;
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No premises found',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ebController.getAllPremises(schoolId),
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _PremisesCard(
                        premises: items[index],
                        cardRadius: _cardRadius,
                        lightBlue: _lightBlue,
                        iconBlue: _iconBlue,
                        activeBg: _activeGreenBg,
                        activeText: _activeGreenText,
                        inactiveBg: _inactiveGreyBg,
                        inactiveText: _inactiveGreyText,
                        onView: () => _openForm(premises: items[index]),
                        onDelete: () => _confirmDelete(items[index]),
                      ),
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

class _StatusFilterPill extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _StatusFilterPill({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('Status')),
            DropdownMenuItem(value: 'Active', child: Text('Active')),
            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _PremisesCard extends StatelessWidget {
  final Map<String, dynamic> premises;
  final double cardRadius;
  final Color lightBlue;
  final Color iconBlue;
  final Color activeBg;
  final Color activeText;
  final Color inactiveBg;
  final Color inactiveText;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _PremisesCard({
    required this.premises,
    required this.cardRadius,
    required this.lightBlue,
    required this.iconBlue,
    required this.activeBg,
    required this.activeText,
    required this.inactiveBg,
    required this.inactiveText,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = (premises['premisesName'] ?? '').toString();
    final address = (premises['premisesAddress'] ?? '').toString();
    final consumerNumber = (premises['consumerNumber'] ?? '').toString();
    final meterLocation = (premises['meterLocation'] ?? '').toString();
    final sanctionedLoad = premises['sanctionedLoad'];
    final isActive = premises['isActive'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.apartment, color: iconBlue, size: 20),
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
                        name.isEmpty ? 'Untitled Premises' : name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: onView,
                      icon: const Icon(Icons.edit, size: 18, color: Colors.black54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      address,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '${consumerNumber.isEmpty ? 'N/A' : consumerNumber} · Loc: ${meterLocation.isEmpty ? 'Not specified' : meterLocation}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? activeBg : inactiveBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'active' : 'inactive',
                        style: TextStyle(
                          color: isActive ? activeText : inactiveText,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sanctionedLoad == null ? 'Load: N/A' : 'Load: $sanctionedLoad kW',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}