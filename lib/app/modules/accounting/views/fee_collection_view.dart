import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/accounting_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/api_constants.dart';

class FeeCollectionView extends GetView<AccountingController> {
  FeeCollectionView({super.key});
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Collection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Student',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: _showStudentSelector,
                            child: Row(
                              children: [
                                const Icon(Icons.person),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Obx(() => Text(
                                    controller.selectedStudent.value?['studentName'] ?? 'Select Student',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  )),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Outstanding Dues
                Obx(() => controller.selectedStudent.value != null
                    ? _buildOutstandingDues(context)
                    : const SizedBox()),
                
                const SizedBox(height: 16),
                
                // Payment Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Details',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        
                        // Amount Field
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₹ ',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter valid amount';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Payment Mode Selection
                        Text(
                          'Payment Mode',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() => Wrap(
                          spacing: 8,
                          children: ['cash', 'upi', 'cheque', 'bank'].map((mode) {
                            return ChoiceChip(
                              label: Text(mode.toUpperCase()),
                              selected: controller.selectedPaymentMode.value == mode,
                              onSelected: (selected) {
                                if (selected) {
                                  controller.selectedPaymentMode.value = mode;
                                }
                              },
                            );
                          }).toList(),
                        )),
                        
                        const SizedBox(height: 16),
                        
                        // Conditional Fields based on Payment Mode
                        Obx(() => _buildPaymentModeFields(context)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Collect Fee Button
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value || controller.selectedStudent.value == null
                        ? null
                        : _collectFee,
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Collect Fee'),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutstandingDues(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outstanding Dues (FIFO Order)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Obx(() => controller.studentDues.isEmpty
                ? const Text('No outstanding dues')
                : Column(
                    children: controller.studentDues.map((due) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.warningYellow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.pending_actions,
                            color: AppTheme.warningYellow,
                          ),
                        ),
                        title: Text(due.feeHead),
                        subtitle: Text('Due: ${due.dueDate}'),
                        trailing: Text(
                          '₹${due.dueAmount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      );
                    }).toList(),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentModeFields(BuildContext context) {
    final paymentMode = controller.selectedPaymentMode.value;
    
    switch (paymentMode) {
      case 'cash':
        return _buildCashDenominationFields(context);
      case 'cheque':
        return _buildChequeFields(context);
      case 'upi':
        return _buildUPIFields(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCashDenominationFields(BuildContext context) {
    final denominations = [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Denomination Tally',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter denomination count to verify cash amount',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: denominations.map((denom) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text('₹$denom:'),
                    ),
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        onChanged: (value) {
                          final count = int.tryParse(value) ?? 0;
                          controller.updateCashDenomination(denom.toString(), count);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() {
                      final count = controller.cashDenominations[denom.toString()] ?? 0;
                      final total = denom * count;
                      return SizedBox(
                        width: 80,
                        child: Text(
                          '₹$total',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final totalCash = controller.totalCashAmount;
          final enteredAmount = double.tryParse(_amountController.text) ?? 0;
          final isMatching = totalCash == enteredAmount;
          
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMatching ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Cash: ₹$totalCash',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMatching ? AppTheme.successGreen : AppTheme.errorRed,
                  ),
                ),
                Icon(
                  isMatching ? Icons.check_circle : Icons.error,
                  color: isMatching ? AppTheme.successGreen : AppTheme.errorRed,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChequeFields(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Cheque Number',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cheque number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Bank Name',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter bank name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUPIFields(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'UPI Reference (Optional)',
      ),
    );
  }

  void _showStudentSelector() {
    // Get current user's school ID
    final schoolId = _authController.user.value?.schoolId;
    if (schoolId == null) {
      Get.snackbar('Error', 'School ID not found. Please login again.');
      return;
    }
    
    // Load students from the school
    _loadAndShowStudents(schoolId);
  }
  
  Future<void> _loadAndShowStudents(String schoolId) async {
    try {
      controller.isLoading.value = true;

      await controller.loadStudentsForSchool(schoolId);
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load students: ${e.toString()}');
    } finally {
      controller.isLoading.value = false;
    }
  }

  void _collectFee() {
    if (_formKey.currentState!.validate()) {
      final student = controller.selectedStudent.value!;
      final amount = double.parse(_amountController.text);
      
      controller.collectFee(
        studentId: student['studentId'],
        classId: student['classId'],
        sectionId: student['sectionId'],
        amount: amount,
        paymentMode: controller.selectedPaymentMode.value,
      );
    }
  }
}