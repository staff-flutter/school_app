import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/student_record_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

class StudentRecordDetailsPage extends StatelessWidget {
  final String schoolId;
  final String studentId;

  const StudentRecordDetailsPage({
    super.key,
    required this.schoolId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final StudentRecordController controller = Get.find<StudentRecordController>();
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('Student Record Details'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: controller.getStudentRecord(schoolId, studentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load student record',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: isLandscape && isTablet
                  ? _buildTabletLandscapeLayout(data, size)
                  : _buildMobileLayout(data, size, isTablet),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Map<String, dynamic> data, Size size, bool isTablet) {
    return Column(
      children: [
        _studentInfoCard(data, size, isTablet),
        _buildFeeSection(data, size, isTablet),
        if (data['concession']?['isApplied'] == true)
          _concessionCard(data, size, isTablet),
        SizedBox(height: isTablet ? 32 : 24),
      ],
    );
  }

  Widget _buildTabletLandscapeLayout(Map<String, dynamic> data, Size size) {
    return Column(
      children: [
        _studentInfoCard(data, size, true),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _feeStructureCard(data, size, true)),
            const SizedBox(width: 24),
            Expanded(child: _feePaidCard(data, size, true)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _duesCard(data, size, true)),
            const SizedBox(width: 24),
            if (data['concession']?['isApplied'] == true)
              Expanded(child: _concessionCard(data, size, true))
            else
              const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFeeSection(Map<String, dynamic> data, Size size, bool isTablet) {
    if (isTablet && size.width > 800) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _feeStructureCard(data, size, isTablet)),
              const SizedBox(width: 16),
              Expanded(child: _feePaidCard(data, size, isTablet)),
            ],
          ),
          const SizedBox(height: 16),
          _duesCard(data, size, isTablet),
        ],
      );
    }
    return Column(
      children: [
        _feeStructureCard(data, size, isTablet),
        _feePaidCard(data, size, isTablet),
        _duesCard(data, size, isTablet),
      ],
    );
  }

  Widget _studentInfoCard(Map<String, dynamic> data, Size size, bool isTablet) {
    return _sectionCard(
      title: 'Student Information',
      icon: Icons.person,
      color: AppTheme.primaryBlue,
      size: size,
      isTablet: isTablet,
      children: [
        _row('Name', data['studentId']?['studentName'], isTablet),
        _row('SR ID', data['studentId']?['srId'], isTablet),
        _row('Academic Year', data['academicYear'], isTablet),
        _row('Class', data['classId']?['name'], isTablet),
        _row('Section', data['sectionId']?['name'], isTablet),
        _statusRow('Status', data['isActive'] == true, isTablet),
        _statusRow('Fully Paid', data['isFullyPaid'] == true, isTablet),
      ],
    );
  }

  Widget _feeStructureCard(Map<String, dynamic> data, Size size, bool isTablet) {
    final fs = data['feeStructure'] ?? {};
    return _sectionCard(
      title: 'Fee Structure',
      icon: Icons.account_balance_wallet,
      color: Colors.blue,
      size: size,
      isTablet: isTablet,
      children: [
        _currencyRow('Admission Fee', fs['admissionFee'], isTablet),
        _currencyRow('First Term', fs['firstTermAmt'], isTablet),
        _currencyRow('Second Term', fs['secondTermAmt'], isTablet),
        _currencyRow('Bus First Term', fs['busFirstTermAmt'], isTablet),
        _currencyRow('Bus Second Term', fs['busSecondTermAmt'], isTablet),
      ],
    );
  }

  Widget _feePaidCard(Map<String, dynamic> data, Size size, bool isTablet) {
    final paid = data['feePaid'] ?? {};
    return _sectionCard(
      title: 'Fee Paid',
      icon: Icons.payment,
      color: Colors.green,
      size: size,
      isTablet: isTablet,
      children: [
        _currencyRow('Admission Paid', paid['admissionFee'], isTablet),
        _currencyRow('First Term Paid', paid['firstTermAmt'], isTablet),
        _currencyRow('Second Term Paid', paid['secondTermAmt'], isTablet),
        _currencyRow('Bus First Term Paid', paid['busFirstTermAmt'], isTablet),
        _currencyRow('Bus Second Term Paid', paid['busSecondTermAmt'], isTablet),
      ],
    );
  }

  Widget _duesCard(Map<String, dynamic> data, Size size, bool isTablet) {
    final dues = data['dues'] ?? {};
    return _sectionCard(
      title: 'Pending Dues',
      icon: Icons.warning,
      color: Colors.orange,
      size: size,
      isTablet: isTablet,
      children: [
        _currencyRow('Admission Dues', dues['admissionDues'], isTablet),
        _currencyRow('First Term Dues', dues['firstTermDues'], isTablet),
        _currencyRow('Second Term Dues', dues['secondTermDues'], isTablet),
        _currencyRow('Bus First Term Dues', dues['busfirstTermDues'], isTablet),
        _currencyRow('Bus Second Term Dues', dues['busSecondTermDues'], isTablet),
      ],
    );
  }

  Widget _concessionCard(Map<String, dynamic> data, Size size, bool isTablet) {
    final c = data['concession'];
    return _sectionCard(
      title: 'Concession Details',
      icon: Icons.discount,
      color: Colors.purple,
      size: size,
      isTablet: isTablet,
      children: [
        _row('Type', c['type']?.toString().toUpperCase(), isTablet),
        _row('Value', '${c['value']}${c['type'] == 'percentage' ? '%' : ''}', isTablet),
        _currencyRow('Amount', c['inAmount'], isTablet),
        if (c['proof']?['url'] != null)
          Padding(
            padding: EdgeInsets.only(top: isTablet ? 16 : 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewProof(c['proof']['url']),
                icon: const Icon(Icons.visibility),
                label: const Text('View Proof'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 16 : 12,
                    horizontal: isTablet ? 24 : 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Size size,
    required bool isTablet,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isTablet ? 20 : 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                  ),
                  child: Icon(icon, color: color, size: isTablet ? 24 : 20),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, dynamic value, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyRow(String label, dynamic value, bool isTablet) {
    final amount = value ?? 0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '₹${amount.toString()}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 16 : 14,
                color: amount > 0 ? Colors.green[700] : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, bool status, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: status ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
              ),
              child: Text(
                status ? 'Yes' : 'No',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 14 : 12,
                  color: status ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewProof(String url) {
    Get.to(() => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Concession Proof'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ));
  }
}