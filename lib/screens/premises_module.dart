import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/eb_controller.dart';
import 'package:school_app/screens/premises_form_page.dart';

import '../controllers/school_controller.dart';
import '../core/permissions/eb_permissions.dart';

/// Mobile "Premises Directory" screen restyled with clean white and blue theme.
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
  Worker? _authWorker;
  Worker? _schoolWorker;
  String _lastLoadedSchoolId = '';

  // Theme Constants
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlueBg = Color(0xFFEFF6FF);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color lightGreenBg = Color(0xFFD1FAE5);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoad());

    _authWorker = ever(_authController.user, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoad());
    });

    if (_school != null) {
      _schoolWorker = ever(_school!.selectedSchool, (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoad());
      });
    }
  }
  @override
  void dispose() {
    _authWorker?.dispose();
    _schoolWorker?.dispose();
    _searchController.dispose();
    super.dispose();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Premises', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
        content: Text(
          'Remove "${premises['premisesName'] ?? ''}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(fontSize: 13, color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
              'Premises Directory',
              style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Manage school premises and electricity connections',
              style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (EBPermissions.canEditPremises(role))
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _openForm(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Register',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
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
              // Search & Filter Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 13, color: textDark),
                      decoration: InputDecoration(
                        hintText: 'Search name or consumer no...',
                        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20, color: textMuted),
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: primaryBlue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusFilterPill(
                    value: _statusFilter,
                    onChanged: (v) => setState(() => _statusFilter = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Premises Cards List
              Expanded(
                child: Obx(() {
                  if (ebController.isLoading.value && ebController.premisesList.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: primaryBlue));
                  }
                  final items = _filteredPremises;
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No premises found',
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: primaryBlue,
                    onRefresh: () => ebController.getAllPremises(schoolId),
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _PremisesCard(
                        premises: items[index],
                        canEdit: EBPermissions.canEditPremises(role),
                        canDelete: EBPermissions.canDeletePremises(role),
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

  void _tryLoad() {
    final id = schoolId;
    if (id.isEmpty || id == _lastLoadedSchoolId) return;
    _lastLoadedSchoolId = id;
    ebController.premisesList.clear();
    ebController.getAllPremises(id);
  }
}

class _StatusFilterPill extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusFilterPill({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _PremisesListScreenState.cardBg,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _PremisesListScreenState.textMuted),
          style: const TextStyle(color: _PremisesListScreenState.textDark, fontWeight: FontWeight.w600, fontSize: 13),
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
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _PremisesCard({
    required this.premises,
    required this.canEdit,
    required this.canDelete,
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
        color: _PremisesListScreenState.cardBg,
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
              color: _PremisesListScreenState.lightBlueBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apartment, color: _PremisesListScreenState.primaryBlue, size: 20),
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
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _PremisesListScreenState.textDark),
                      ),
                    ),
                    if (canEdit)
                      IconButton(
                        onPressed: onView,
                        icon: const Icon(Icons.edit_outlined, size: 18, color: _PremisesListScreenState.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (canEdit && canDelete) const SizedBox(width: 10),
                    if (canDelete)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
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
                      style: const TextStyle(color: _PremisesListScreenState.textMuted, fontSize: 12),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '${consumerNumber.isEmpty ? 'N/A' : consumerNumber} · Loc: ${meterLocation.isEmpty ? 'Not specified' : meterLocation}',
                    style: const TextStyle(color: _PremisesListScreenState.textMuted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? _PremisesListScreenState.lightGreenBg : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isActive ? _PremisesListScreenState.primaryGreen : _PremisesListScreenState.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sanctionedLoad == null ? 'Load: N/A' : 'Load: $sanctionedLoad kW',
                      style: const TextStyle(color: _PremisesListScreenState.textDark, fontSize: 11, fontWeight: FontWeight.w600),
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