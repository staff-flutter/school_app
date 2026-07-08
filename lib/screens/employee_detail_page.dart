import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:school_app/constants/api_constants.dart';
import '../../services/api_service.dart';
import 'create_employee_profile_page.dart';

// TODO: url_launcher is used to open documents/salary slips in the browser.
// Add `url_launcher: ^6.x` to pubspec.yaml if it's not already a dependency.
// import 'package:url_launcher/url_launcher.dart';

class _EmployeeApi {
  static String getOne(String userId) => '/api/employee-profile/get/$userId';
}

class EmployeeDetailPage extends StatefulWidget {
  final String userId;
  const EmployeeDetailPage({super.key, required this.userId});

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  final ApiService _apiService = Get.find<ApiService>();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _data = {};
  Map<String, dynamic> _user = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final String userId = widget.userId;
    try {
      final res = await _apiService.get('${ApiConstants.getOneEmployeeProfile}/$userId');
      print('response of single profile:$res');

      final data = (res.data is Map && res.data['data'] is Map)
          ? Map<String, dynamic>.from(res.data['data'])
          : Map<String, dynamic>.from(res.data ?? {});

      // Backend returns the linked account as a populated "userId" field,
      // not "user".
      final userField = data['userId'];
      final user = userField is Map ? Map<String, dynamic>.from(userField) : <String, dynamic>{};

      setState(() {
        _data = data;
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load employee details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openEdit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEmployeeProfilePage(userId: widget.userId, isEdit: true),
      ),
    );
    if (changed == true) _load();
  }

  String _fmt(dynamic v, [String fallback = 'N/A']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(_fmt(_user['userName'] ?? 'Employee Profile')),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.edit), onPressed: _isLoading ? null : _openEdit),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Account Profile'),
              Tab(text: 'Professional Details'),
              Tab(text: 'Contact Information'),
              Tab(text: 'Bank Details'),
              Tab(text: 'Education'),
              Tab(text: 'Salary Slips'),
              Tab(text: 'Documents'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : TabBarView(
          children: [
            _accountProfileTab(),
            _professionalDetailsTab(),
            _contactInformationTab(),
            _bankDetailsTab(),
            _educationTab(),
            _salarySlipsTab(),
            _documentsTab(),
          ],
        ),
      ),
    );
  }

  // ── Shared card/row helpers ────────────────────────────────────────────
  Widget _card({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────────────
  Widget _accountProfileTab() {
    final isActive = _data['isActive'] ?? true;
    return ListView(
      children: [
        _card(title: 'Basic Information', children: [
          _field('Full Name', _fmt(_user['userName'] ?? _user['name'])),
          _field('Email Address', _fmt(_user['email'])),
          _field('Phone Number', _fmt(_user['phoneNo'] ?? _user['phone'] ?? _user['phoneNumber'])),
          _field('Role Configuration', _fmt(_user['role'])),
          Row(
            children: [
              Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(color: isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ]),
      ],
    );
  }

  Widget _professionalDetailsTab() {
    return ListView(
      children: [
        _card(title: 'Professional Details', children: [
          _field('Employee Number', _fmt(_data['employeeNo'])),
          _field('Designation', _fmt(_data['designation'])),
          _field('Department', _fmt(_data['department'])),
          _field('Employment Type', _fmt(_data['employmentType']).replaceAll('_', ' ').toUpperCase()),
          _field('Date of Joining', _fmt(_data['dateOfJoining'])),
          _field('Years of Experience', _fmt(_data['yearsOfExperience'])),
          _field('Previous Workplace', _fmt(_data['previousWorkplace'])),
          _field('PF Number', _fmt(_data['pfNumber'])),
          _field('National ID', _fmt(_data['nationalId'])),
        ]),
      ],
    );
  }

  Widget _contactInformationTab() {
    final emg = _data['emergencyContact'];
    final emgMap = emg is Map ? Map<String, dynamic>.from(emg) : <String, dynamic>{};
    return ListView(
      children: [
        _card(title: 'Address', children: [
          _field('Current Address', _fmt(_data['currentAddress'])),
          _field('Permanent Address', _fmt(_data['permanentAddress'])),
        ]),
        _card(title: 'Emergency Contact', children: [
          _field('Name', _fmt(emgMap['name'])),
          _field('Relation', _fmt(emgMap['relation'])),
          _field('Phone', _fmt(emgMap['phone'])),
        ]),
      ],
    );
  }

  Widget _bankDetailsTab() {
    final bank = _data['bankDetails'];
    final bankMap = bank is Map ? Map<String, dynamic>.from(bank) : <String, dynamic>{};
    return ListView(
      children: [
        _card(title: 'Bank Details', children: [
          _field('Account Holder Name', _fmt(bankMap['accountName'])),
          _field('Bank Name', _fmt(bankMap['bankName'])),
          _field('Account Number', _fmt(bankMap['accountNumber'])),
          _field('IFSC Code', _fmt(bankMap['ifscCode'])),
        ]),
      ],
    );
  }

  Widget _educationTab() {
    final edu = _data['educationDetails'];
    final list = edu is List ? edu : [];
    if (list.isEmpty) {
      return const Center(child: Text('No education details added.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final e = list[index] is Map ? Map<String, dynamic>.from(list[index]) : <String, dynamic>{};
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entry ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _field('Degree', _fmt(e['degree'])),
                _field('Institution', _fmt(e['institution'])),
                _field('Year of Passing', _fmt(e['yearOfPassing'])),
                _field('Grade', _fmt(e['grade'])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _salarySlipsTab() {
    final slip = _data['salarySlip'];
    final doc = EmployeeDocument.fromJson(slip);
    if (doc == null) {
      return const Center(child: Text('No salary slip uploaded.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.blue),
            title: Text(doc.name),
            trailing: TextButton(
              onPressed: () => _openUrl(doc.url),
              child: const Text('Open'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _documentsTab() {
    final docsRaw = _data['documents'];
    final docs = <EmployeeDocument>[];
    if (docsRaw is List) {
      for (final d in docsRaw) {
        final doc = EmployeeDocument.fromJson(d);
        if (doc != null) docs.add(doc);
      }
    }
    if (docs.isEmpty) {
      return const Center(child: Text('No documents uploaded.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: const Icon(Icons.description, color: Colors.blue),
            title: Text(doc.name),
            trailing: TextButton(
              onPressed: () => _openUrl(doc.url),
              child: const Text('Open'),
            ),
          ),
        );
      },
    );
  }

  void _openUrl(String url) {
    // TODO: wire up with url_launcher, e.g.:
    // launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open: $url')),
    );
  }
}