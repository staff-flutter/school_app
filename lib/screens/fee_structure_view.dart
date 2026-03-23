import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/accounting_controller.dart';
import 'package:school_app/controllers/fee_structure_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';

class FeeStructureView extends GetView<AccountingController> {
  FeeStructureView({super.key});
  final selectedClass = ''.obs;
  final selectedSection = ''.obs;
  final feeControllers = <String, TextEditingController>{}.obs;

  @override
  Widget build(BuildContext context) {
    _initializeFeeControllers();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Structure'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class & Section Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Class & Section',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => DropdownButtonFormField<String>(
                            value: selectedClass.value.isEmpty ? null : selectedClass.value,
                            decoration: const InputDecoration(
                              labelText: 'Class',
                              border: OutlineInputBorder(),
                            ),
                            items: ['LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
                                .map((cls) => DropdownMenuItem(
                                      value: cls,
                                      child: Text('Class $cls'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                selectedClass.value = value;
                                selectedSection.value = ''; // Reset section
                              }
                            },
                          )),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(() => DropdownButtonFormField<String>(
                            value: selectedSection.value.isEmpty ? null : selectedSection.value,
                            decoration: const InputDecoration(
                              labelText: 'Section (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            items: ['A', 'B', 'C', 'D']
                                .map((section) => DropdownMenuItem(
                                      value: section,
                                      child: Text('Section $section'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              selectedSection.value = value ?? '';
                            },
                          )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Fee Structure Form
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fee Structure Configuration',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildFeeField(context, 'Admission Fee', 'admissionFee'),
                              const SizedBox(height: 16),
                              _buildFeeField(context, 'First Term Amount', 'firstTermAmt'),
                              const SizedBox(height: 16),
                              _buildFeeField(context, 'Second Term Amount', 'secondTermAmt'),
                              const SizedBox(height: 16),
                              _buildFeeField(context, 'Annual Fee', 'annualFee'),
                              const SizedBox(height: 16),
                              _buildFeeField(context, 'Bus First Term Amount', 'busFirstTermAmt'),
                              const SizedBox(height: 16),
                              _buildFeeField(context, 'Bus Second Term Amount', 'busSecondTermAmt'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                onPressed: selectedClass.value.isEmpty || controller.isLoading.value
                    ? null
                    : _saveFeeStructure,
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Fee Structure'),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeField(BuildContext context, String label, String key) {
    return TextFormField(
      controller: feeControllers[key],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
        border: const OutlineInputBorder(),
        helperText: _getFeeFieldHelper(key),
      ),
    );
  }

  String _getFeeFieldHelper(String key) {
    switch (key) {
      case 'admissionFee':
        return 'One-time admission fee';
      case 'firstTermAmt':
        return 'Tuition fee for first term';
      case 'secondTermAmt':
        return 'Tuition fee for second term';
      case 'annualFee':
        return 'Annual charges (books, activities, etc.)';
      case 'busFirstTermAmt':
        return 'Transportation fee for first term';
      case 'busSecondTermAmt':
        return 'Transportation fee for second term';
      default:
        return '';
    }
  }

  void _initializeFeeControllers() {
    final feeFields = [
      'admissionFee',
      'firstTermAmt',
      'secondTermAmt',
      'annualFee',
      'busFirstTermAmt',
      'busSecondTermAmt',
    ];

    for (String field in feeFields) {
      if (!feeControllers.containsKey(field)) {
        feeControllers[field] = TextEditingController();
      }
    }
  }

  void _saveFeeStructure() {
    // Validate that at least one fee field has a value
    bool hasValue = false;
    final feeData = <String, double>{};

    for (String key in feeControllers.keys) {
      final text = feeControllers[key]!.text.trim();
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null && value > 0) {
          feeData[key] = value;
          hasValue = true;
        }
      }
    }

    if (!hasValue) {
      Get.snackbar('Error', 'Please enter at least one fee amount');
      return;
    }

    // Show confirmation dialog
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Fee Structure'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class: ${selectedClass.value}'),
            if (selectedSection.value.isNotEmpty)
              Text('Section: ${selectedSection.value}'),
            const SizedBox(height: 16),
            const Text('Fee Structure:'),
            ...feeData.entries.map((entry) => Text(
              '${_getFeeFieldLabel(entry.key)}: ₹${entry.value.toStringAsFixed(0)}',
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _submitFeeStructure(feeData);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getFeeFieldLabel(String key) {
    switch (key) {
      case 'admissionFee':
        return 'Admission Fee';
      case 'firstTermAmt':
        return 'First Term Amount';
      case 'secondTermAmt':
        return 'Second Term Amount';
      case 'annualFee':
        return 'Annual Fee';
      case 'busFirstTermAmt':
        return 'Bus First Term Amount';
      case 'busSecondTermAmt':
        return 'Bus Second Term Amount';
      default:
        return key;
    }
  }

  void _submitFeeStructure(Map<String, double> feeData) async {
    final feeController = Get.put(FeeStructureController());
    final authController = Get.find<AuthController>();
    
    final schoolId = authController.user.value?.schoolId;
    if (schoolId == null) {
      Get.snackbar('Error', 'School ID not found');
      return;
    }
    
    // For now, using a dummy classId - this should be from actual class selection
    final classId = 'class_${selectedClass.value.toLowerCase()}';
    
    await feeController.setFeeStructure(
      schoolId: schoolId,
      classId: classId,
      feeHead: feeData,
    );
    
    // Clear form on success
    for (var controller in feeControllers.values) {
      controller.clear();
    }
    selectedClass.value = '';
    selectedSection.value = '';
  }
}