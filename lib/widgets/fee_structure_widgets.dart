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
  @override
  Widget build(BuildContext context) {
    final feeController = Get.put(FeeStructureController());
    final schoolController = Get.find<SchoolController>();
    
    // Load fee structures when this tab is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (schoolController.selectedSchool.value != null) {
        feeController.getAllFeeStructures(schoolController.selectedSchool.value!.id);
        schoolController.getAllClasses(schoolController.selectedSchool.value!.id);
      }
    });
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'All Fee Structures',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Fee structures list
          Expanded(
            child: Obx(() {
              if (feeController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final groupedStructures = _groupFeeStructuresByClass(
                feeController.allFeeStructures,
                schoolController.classes,
              );
              
              if (groupedStructures.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No fee structures found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: groupedStructures.length,
                itemBuilder: (context, index) {
                  final classData = groupedStructures[index];
                  return _buildClassFeeCard(classData);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
  
  List<Map<String, dynamic>> _groupFeeStructuresByClass(
    List<Map<String, dynamic>> feeStructures,
    List<SchoolClass> classes,
  ) {
    final Map<String, Map<String, dynamic>> grouped = {};
    
    // Initialize with all classes
    for (var cls in classes) {
      grouped[cls.id] = {
        'classId': cls.id,
        'className': cls.name,
        'structures': <Map<String, dynamic>>[],
      };
    }
    
    // Group fee structures by classId
    for (var structure in feeStructures) {
      final classId = structure['classId'] as String?;
      if (classId != null && grouped.containsKey(classId)) {
        grouped[classId]!['structures'].add(structure);
      }
    }
    
    return grouped.values.toList();
  }
  
  Widget _buildClassFeeCard(Map<String, dynamic> classData) {
    final className = classData['className'] as String;
    final structures = classData['structures'] as List<Map<String, dynamic>>;
    final structureCount = structures.length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getClassGradient(className).colors.first.withOpacity(0.08),
            _getClassGradient(className).colors.last.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: _getClassGradient(className).colors.first.withOpacity(0.15),
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
      child: Theme(
        data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.all(16),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _getClassGradient(className).colors.first.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.class_, color: _getClassGradient(className).colors.first, size: 20),
          ),
          title: Flexible(
            child: Text(
              className,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.titleOnWhite,
              ),
            ),
          ),
          subtitle: Flexible(
            child: Text(
              _getStructureCountText(structureCount),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.subtitleOnWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: _getStructureCountGradient(structureCount),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _getStructureCountColor(structureCount).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              structureCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          children: [
            if (structures.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'No structure set yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...structures.map((structure) => _buildFeeStructureDetails(structure)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeeStructureDetails(Map<String, dynamic> structure) {
    final type = structure['type'] as String?;
    final feeHead = structure['feeHead'] as Map<String, dynamic>? ?? {};
    final totalAmount = structure['totalAmount'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _getTypeGradient(type),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getTypeTitle(type),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹$totalAmount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Fee breakdown
          _buildFeeBreakdown(feeHead),
        ],
      ),
    );
  }
  
  Widget _buildFeeBreakdown(Map<String, dynamic> feeHead) {
    final fees = <Widget>[];
    
    final feeItems = [
      {'key': 'admissionFee', 'label': 'Admission Fee', 'icon': Icons.login},
      {'key': 'firstTermAmt', 'label': 'First Term', 'icon': Icons.looks_one},
      {'key': 'secondTermAmt', 'label': 'Second Term', 'icon': Icons.looks_two},
      {'key': 'busFirstTermAmt', 'label': 'Bus First Term', 'icon': Icons.directions_bus},
      {'key': 'busSecondTermAmt', 'label': 'Bus Second Term', 'icon': Icons.directions_bus_filled},
    ];
    
    for (var item in feeItems) {
      final value = feeHead[item['key']];
      if (value != null && value != 0) {
        fees.add(
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                Text(
                  '₹$value',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return Column(children: fees);
  }
  
  LinearGradient _getClassGradient(String className) {
    final gradients = [
      const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)]), // Red
      const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]), // Teal
      const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFECACA)]), // Pink
      const LinearGradient(colors: [Color(0xFFA8E6CF), Color(0xFF88D8A3)]), // Green
      const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFF6BCF7F)]), // Yellow-Green
      const LinearGradient(colors: [Color(0xFFB19CD9), Color(0xFFFFB347)]), // Purple-Orange
      const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]), // Purple
      const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]), // Magenta
      const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]), // Cyan
      const LinearGradient(colors: [Color(0xFF43e97b), Color(0xFF38f9d7)]), // Mint
    ];
    return gradients[className.hashCode % gradients.length];
  }
  
  LinearGradient _getTypeGradient(String? type) {
    switch (type?.toLowerCase()) {
      case 'new':
        return const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]); // Green gradient
      case 'old':
        return const LinearGradient(colors: [Color(0xFFfc466b), Color(0xFF3f5efb)]); // Red-Purple gradient
      default:
        return const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]); // Purple gradient
    }
  }
  
  IconData _getTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'new':
        return Icons.person_add;
      case 'old':
        return Icons.school;
      default:
        return Icons.payment;
    }
  }
  
  String _getTypeTitle(String? type) {
    switch (type?.toLowerCase()) {
      case 'new':
        return 'New Student Fee Structure';
      case 'old':
        return 'Old Student Fee Structure';
      default:
        return 'General Fee Structure';
    }
  }
  
  String _getStructureCountText(int count) {
    switch (count) {
      case 0:
        return 'No Structure';
      case 1:
        return '1 Structure';
      default:
        return '$count Structures';
    }
  }
  
  LinearGradient _getStructureCountGradient(int count) {
    switch (count) {
      case 0:
        return const LinearGradient(colors: [Color(0xFFff7675), Color(0xFFd63031)]); // Red gradient
      case 1:
        return const LinearGradient(colors: [Color(0xFFfdcb6e), Color(0xFFe17055)]); // Orange gradient
      default:
        return const LinearGradient(colors: [Color(0xFF00b894), Color(0xFF00a085)]); // Green gradient
    }
  }
  
  Color _getStructureCountColor(int count) {
    switch (count) {
      case 0:
        return const Color(0xFFd63031);
      case 1:
        return const Color(0xFFe17055);
      default:
        return const Color(0xFF00a085);
    }
  }
}