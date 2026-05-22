import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/fee_structure_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/models/school_models.dart';

// ─── Light-blue theme tokens ──────────────────────────────────────────────────
const _kBg         = Color(0xFFF0F5FF);
const _kBlue       = Color(0xFF2563EB);
const _kBlueDark   = Color(0xFF1E40AF);
const _kBlueMid    = Color(0xFF3B82F6);
const _kBlueDarker = Color(0xFF1A2A3A);
const _kBlueMuted  = Color(0xFF90A4BE);
const _kBlueBorder = Color(0xFFDDE6F5);
const _kWhite      = Colors.white;

// ─── AllFeeStructuresTab ──────────────────────────────────────────────────────
class AllFeeStructuresTab extends StatelessWidget {
  AllFeeStructuresTab({super.key});

  @override
  Widget build(BuildContext context) {
    final feeController    = Get.put(FeeStructureController());
    final schoolController = Get.find<SchoolController>();

    // Load data once this tab is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schoolId = schoolController.selectedSchool.value?.id;
      if (schoolId != null) {
        feeController.getAllFeeStructures(schoolId);
        schoolController.getAllClasses(schoolId);
      }
    });

    return Container(
      color: _kBg,
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kBlue, _kBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _kBlue.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: _kWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.payment_rounded,
                    color: _kWhite, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('All Fee Structures',
                  style: TextStyle(
                      color: _kWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              // Refresh button
              GestureDetector(
                onTap: () {
                  final schoolId =
                      schoolController.selectedSchool.value?.id;
                  if (schoolId != null) {
                    feeController.getAllFeeStructures(schoolId);
                    schoolController.getAllClasses(schoolId);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: _kWhite.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.refresh_rounded,
                      color: _kWhite, size: 16),
                ),
              ),
            ]),
          ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (feeController.isLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: _kBlue));
              }

              final grouped = _groupByClass(
                feeController.allFeeStructures,
                schoolController.classes,
              );

              if (grouped.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: _kBlue.withOpacity(0.08),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.payment_rounded,
                              size: 40, color: _kBlueMuted),
                        ),
                        const SizedBox(height: 14),
                        const Text('No fee structures found',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kBlueDarker)),
                        const SizedBox(height: 6),
                        const Text(
                            'Fee structures will appear here once set.',
                            style: TextStyle(
                                fontSize: 12, color: _kBlueMuted),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                itemCount: grouped.length,
                itemBuilder: (ctx, i) =>
                    _ClassFeeCard(classData: grouped[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> _groupByClass(
    List<Map<String, dynamic>> feeStructures,
    List<SchoolClass> classes,
  ) {
    final Map<String, Map<String, dynamic>> map = {};

    // Seed with every class (even those with no fee set)
    for (final cls in classes) {
      map[cls.id] = {
        'classId': cls.id,
        'className': cls.name,
        'structures': <Map<String, dynamic>>[],
      };
    }

    // Attach fee structures to their class
    for (final fs in feeStructures) {
      final cid = fs['classId'];
      final classId = cid is Map ? (cid['_id'] ?? cid['id'] ?? '') : cid as String? ?? '';
      if (map.containsKey(classId)) {
        (map[classId]!['structures'] as List).add(fs);
      }
    }

    // Only return classes that have at least one structure
    return map.values
        .where((c) => (c['structures'] as List).isNotEmpty)
        .toList()
      ..sort((a, b) => (a['className'] as String)
          .compareTo(b['className'] as String));
  }
}

// ─── Per-class expansion card ─────────────────────────────────────────────────
class _ClassFeeCard extends StatelessWidget {
  const _ClassFeeCard({required this.classData});
  final Map<String, dynamic> classData;

  @override
  Widget build(BuildContext context) {
    final className  = classData['className'] as String;
    final structures = (classData['structures'] as List)
        .cast<Map<String, dynamic>>();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBlueBorder),
        boxShadow: [
          BoxShadow(
              color: _kBlueBorder.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        // Remove the default ExpansionTile divider line
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: _kBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10)),
            child:
                const Icon(Icons.class_rounded, color: _kBlue, size: 18),
          ),
          title: Text(className,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kBlueDarker)),
          subtitle: Text(
            '${structures.length} structure${structures.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 11, color: _kBlueMuted),
          ),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _kBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              '${structures.length}',
              style: const TextStyle(
                  color: _kBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          iconColor: _kBlue,
          collapsedIconColor: _kBlueMuted,
          children: structures.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: _kBlueMuted, size: 16),
                      const SizedBox(width: 8),
                      Text('No structure set yet',
                          style: const TextStyle(
                              fontSize: 12, color: _kBlueMuted)),
                    ]),
                  )
                ]
              : structures
                  .map((s) => _FeeStructureCard(structure: s))
                  .toList(),
        ),
      ),
    );
  }
}

// ─── Individual fee structure details ────────────────────────────────────────
class _FeeStructureCard extends StatelessWidget {
  const _FeeStructureCard({required this.structure});
  final Map<String, dynamic> structure;

  @override
  Widget build(BuildContext context) {
    final type        = (structure['type'] as String?)?.toLowerCase();
    final feeHead     = structure['feeHead'] as Map<String, dynamic>? ?? {};
    final totalAmount = structure['totalAmount'] ?? 0;

    final isNew    = type == 'new';
    final label    = isNew ? 'New Students' : 'Old Students';
    final icon     = isNew ? Icons.person_add_rounded : Icons.school_rounded;
    final color    = isNew ? const Color(0xFF059669) : _kBlue;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Type header ──────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'Total ₹$totalAmount',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
            ]),
          ),

          // ── Fee breakdown ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
            child: _FeeBreakdown(feeHead: feeHead, accentColor: color),
          ),
        ],
      ),
    );
  }
}

// ─── Fee line items ───────────────────────────────────────────────────────────
class _FeeBreakdown extends StatelessWidget {
  const _FeeBreakdown(
      {required this.feeHead, required this.accentColor});
  final Map<String, dynamic> feeHead;
  final Color accentColor;

  static const _items = [
    {'key': 'admissionFee',    'label': 'Admission Fee',    'icon': Icons.login_rounded},
    {'key': 'firstTermAmt',    'label': 'First Term',       'icon': Icons.looks_one_rounded},
    {'key': 'secondTermAmt',   'label': 'Second Term',      'icon': Icons.looks_two_rounded},
    {'key': 'busFirstTermAmt', 'label': 'Bus – First Term', 'icon': Icons.directions_bus_rounded},
    {'key': 'busSecondTermAmt','label': 'Bus – Second Term','icon': Icons.directions_bus_filled_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final rows = _items
        .where((item) {
          final v = feeHead[item['key'] as String];
          return v != null && v != 0;
        })
        .map<Widget>((item) {
          final val = feeHead[item['key'] as String];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(item['icon'] as IconData,
                    color: accentColor, size: 13),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(item['label'] as String,
                    style: const TextStyle(
                        fontSize: 12, color: _kBlueDarker)),
              ),
              Text('₹$val',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor)),
            ]),
          );
        })
        .toList();

    if (rows.isEmpty) {
      return Text('No fee details available',
          style: TextStyle(fontSize: 11, color: _kBlueMuted));
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}