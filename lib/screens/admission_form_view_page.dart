import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/bill_admission_controller.dart';

class AdmissionFormViewPage extends StatefulWidget {
  final String studentId;
  const AdmissionFormViewPage({super.key, required this.studentId});

  @override
  State<AdmissionFormViewPage> createState() => _AdmissionFormViewPageState();
}

class _AdmissionFormViewPageState extends State<AdmissionFormViewPage> {
  late final BillAdmissionController _admissionController;
  Map<String, dynamic>? _formData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _admissionController = Get.isRegistered<BillAdmissionController>()
        ? Get.find<BillAdmissionController>()
        : Get.put(BillAdmissionController());
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _admissionController.getSingleAdmissionForm(studentId: widget.studentId);
    print('data:$data');
    print('studentId:${widget.studentId}');
    if (mounted) {
      setState(() {
        _formData = data;
        _isLoading = false;
      });
    }
  }

  String _field(String key) => _formData?[key]?.toString().trim() ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      appBar: AppBar(
        title: const Text('Admission Form'),
        backgroundColor: const Color(0xff4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_formData == null)
          ? _emptyState()
          : RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statusBadge(),
              const SizedBox(height: 12),
              _infoCard('Student Details', Icons.person_outline_rounded, {
                'Student Name': _field('studentName'),
                'Date of Birth': _field('dob'),
                'Age': _field('age'),
                'Gender': _field('gender'),
                'Mother Tongue': _field('motherTongue'),
                'Religion': _field('religion'),
                'Community': _field('community'),
                'EMIS Number': _field('emisNumber'),
              }),
              _infoCard('Academic & Contact', Icons.school_outlined, {
                'Academic Year': _field('academicYear'),
                'Admission Sought For': _field('admissionSoughtFor'),
                'Previous Exam / Last Class Passed': _field('examinationPassed'),
                'Mobile Number': _field('mobileNumber'),
                'Current Address': _field('currentAddress'),
                'Permanent Address': _field('permanentAddress'),
              }),
              _infoCard('Parent Information', Icons.family_restroom_rounded, {
                "Father's Name": _field('fatherName'),
                "Father's Education": _field('fatherEducation'),
                "Father's Occupation": _field('fatherOccupation'),
                "Mother's Name": _field('motherName'),
                "Mother's Education": _field('motherEducation'),
                "Mother's Occupation": _field('motherOccupation'),
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge() {
    final status = _field('status').isEmpty ? 'Pending' : _field('status');
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _infoCard(String title, IconData icon, Map<String, String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xff4A90E2)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: items.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(e.key,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: Text(
                          e.value.isEmpty ? '—' : e.value,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Icons.description_outlined, size: 36, color: Colors.blue.shade400),
            ),
            const SizedBox(height: 14),
            const Text('No Admission Form', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('No admission form is linked to your profile yet.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}