import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/fee_structure_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/models/school_models.dart';

class _FeeStructureTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final feeController = Get.put(FeeStructureController());
    final schoolController = Get.find<SchoolController>();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Set Fee Structure',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text('Fee structure setup functionality will be implemented here.'),
        ],
      ),
    );
  }
}

class AllFeeStructuresTab extends StatelessWidget {
  const AllFeeStructuresTab({super.key});

  @override
  Widget build(BuildContext context) {
    final feeController = Get.put(FeeStructureController());
    final schoolController = Get.find<SchoolController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (schoolController.selectedSchool.value != null) {
        feeController.getAllFeeStructures(
            schoolController.selectedSchool.value!.id);
        schoolController
            .getAllClasses(schoolController.selectedSchool.value!.id);
      }
    });

    return Obx(() {
      if (feeController.isLoading.value)
        return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)));

      final groupedStructures = _groupFeeStructuresByClass(
        feeController.allFeeStructures,
        schoolController.classes,
      );

      if (groupedStructures.isEmpty)
        return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_rounded,
                  size: 32, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 16),
            const Text('No fee structures yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            const Text('Set a fee structure from the Set Fee tab',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          ]),
        );

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: groupedStructures.length,
        itemBuilder: (context, index) =>
            _buildClassFeeCard(groupedStructures[index]),
      );
    });
  }

  List<Map<String, dynamic>> _groupFeeStructuresByClass(
      List<Map<String, dynamic>> feeStructures,
      List<SchoolClass> classes,
      ) {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (var cls in classes) {
      grouped[cls.id] = {
        'classId': cls.id,
        'className': cls.name,
        'structures': <Map<String, dynamic>>[],
      };
    }
    for (var structure in feeStructures) {
      final classId = structure['classId'] as String?;
      if (classId != null && grouped.containsKey(classId))
        (grouped[classId]!['structures'] as List).add(structure);
    }
    // Only return classes that have structures
    return grouped.values
        .where((c) => (c['structures'] as List).isNotEmpty)
        .toList();
  }

  // Color pair per class (bg, accent) — cycles through _DS-aligned ramps
  List<Color> _classColors(String className) {
    final palettes = [
      [const Color(0xFFEFF6FF), const Color(0xFF3B82F6)], // blue
      [const Color(0xFFECFDF5), const Color(0xFF059669)], // green
      [const Color(0xFFFFFBEB), const Color(0xFFD97706)], // amber
      [const Color(0xFFF5F3FF), const Color(0xFF7C3AED)], // purple
      [const Color(0xFFFFF1F2), const Color(0xFFE11D48)], // rose
      [const Color(0xFFECFEFF), const Color(0xFF0891B2)], // cyan
    ];
    return palettes[className.hashCode.abs() % palettes.length];
  }

  Widget _buildClassFeeCard(Map<String, dynamic> classData) {
    final className = classData['className'] as String;
    final structures = classData['structures'] as List<dynamic>;
    final colors = _classColors(className);
    final bg = colors[0];
    final accent = colors[1];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 1)),
          BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 12,
              offset: Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding:
          const EdgeInsets.fromLTRB(14, 0, 14, 14),
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            child: Icon(Icons.class_rounded, color: accent, size: 20),
          ),
          title: Text(className,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
          subtitle: Text(
            '${structures.length} structure${structures.length == 1 ? '' : 's'}',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          trailing: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                structures.length.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
          ),
          children: structures
              .map<Widget>((s) =>
              _buildStructureCard(s as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildStructureCard(Map<String, dynamic> structure) {
    final type = structure['type'] as String?;
    final feeHead =
        structure['feeHead'] as Map<String, dynamic>? ?? {};
    final totalAmount = structure['totalAmount'] ?? 0;

    final isNew = type?.toLowerCase() == 'new';
    final typeColor =
    isNew ? const Color(0xFF059669) : const Color(0xFF3B82F6);
    final typeBg =
    isNew ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF);
    final typeIcon =
    isNew ? Icons.person_add_rounded : Icons.school_rounded;
    final typeLabel =
    isNew ? 'New Students' : 'Old Students';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: typeBg,
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: typeColor.withOpacity(0.2), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(typeLabel,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: typeColor)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('₹$totalAmount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            Divider(height: 1, color: typeColor.withOpacity(0.15)),

            // ── Fee rows ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(children: [
                _feeRow('Admission Fee', feeHead['admissionFee'],
                    Icons.login_rounded, typeColor),
                _feeRow('First Term', feeHead['firstTermAmt'],
                    Icons.looks_one_rounded, typeColor),
                _feeRow('Second Term', feeHead['secondTermAmt'],
                    Icons.looks_two_rounded, typeColor),
                _feeRow('Bus First Term', feeHead['busFirstTermAmt'],
                    Icons.directions_bus_rounded, typeColor),
                _feeRow('Bus Second Term', feeHead['busSecondTermAmt'],
                    Icons.directions_bus_filled_rounded, typeColor),
              ]),
            ),
          ]),
    );
  }

  Widget _feeRow(
      String label, dynamic value, IconData icon, Color accent) {
    if (value == null || value == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 13, color: accent.withOpacity(0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF475569))),
        ),
        Text('₹$value',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent)),
      ]),
    );
  }
}