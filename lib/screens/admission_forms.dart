import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/bill_admission_controller.dart';

import 'admission_form_detail_view.dart';
import 'bill_book_page.dart';

class AdmissionFormListView extends StatefulWidget {
  const AdmissionFormListView({super.key});

  @override
  State<AdmissionFormListView> createState() => _AdmissionFormListViewState();
}

class _AdmissionFormListViewState extends State<AdmissionFormListView> {
  final BillAdmissionController _controller = Get.find<BillAdmissionController>();
  final AuthController _authController = Get.find<AuthController>();

  final _searchController = TextEditingController();
  final _academicYearController = TextEditingController();

  // Adjust this list to whatever status values your backend actually uses.
  static const List<String> _statusOptions = ['All', 'pending', 'approved', 'rejected'];
  String _selectedStatus = 'All';

  int _page = 1;
  static const int _pageLimit = 20;

  @override
  void initState() {
    super.initState();
    _fetchForms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  String? get _schoolId => _authController.user.value?.schoolId;

  Future<void> _fetchForms({bool resetPage = true}) async {
    final schoolId = _schoolId;
    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School ID not found. Please login again.')),
      );
      return;
    }

    if (resetPage) _page = 1;

    await _controller.getAllAdmissionForms(
      schoolId: schoolId,
      academicYear: _academicYearController.text.trim().isEmpty ? null : _academicYearController.text.trim(),
      status: _selectedStatus == 'All' ? null : _selectedStatus,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      page: _page,
      limit: _pageLimit,
    );
  }

  Future<void> _openDetail(Map<String, dynamic> form) async {
    final id = (form['_id'] ?? form['id'] ?? form['admissionFormId'])?.toString();
    if (id == null) return;

    final result = await Get.to(() => AdmissionFormDetailView(
      admissionFormId: id,
      initialData: form,
    ));

    // Refresh the list if the detail screen made a change (status update, edit, delete, link).
    if (result == true) {
      _fetchForms(resetPage: false);
    }
  }

  Future<void> _createNew() async {
    final result = await Get.to(() => const AdmissionBillBookView());
    if (result == true) {
      _fetchForms();
    } else {
      // Always refresh on return in case a record was saved without an explicit result.
      _fetchForms(resetPage: false);
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return const Color(0xFF15803D);
      case 'rejected':
        return const Color(0xFFB91C1C);
      case 'pending':
        return const Color(0xFFB45309);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admission Forms'),
        backgroundColor: const Color(0xFF0F2042),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A8A),
        onPressed: _createNew,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchForms(resetPage: false),
              child: Obx(() {
                final forms = _controller.admissionForms;
                final loading = _controller.isLoading.value;

                if (loading && forms.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (forms.isEmpty) {
                  return ListView(
                    // Wrapped in a ListView so pull-to-refresh still works on an empty state.
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'No admission forms found.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: forms.length,
                  itemBuilder: (context, index) => _buildFormCard(forms[index]),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by student name...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _fetchForms(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _academicYearController,
                  decoration: InputDecoration(
                    hintText: 'Year',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _fetchForms(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStatus = value);
                    _fetchForms();
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _fetchForms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Filter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(Map<String, dynamic> form) {
    final studentName = form['studentName']?.toString() ?? 'Unnamed Applicant';
    final formNumber = (form['formNumber'] ?? form['sequence'] ?? form['_id'] ?? '').toString();
    final soughtFor = form['soughtForClass']?.toString();
    final status = form['status']?.toString() ?? 'pending';
    final academicYear = form['academicYear']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openDetail(form),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0F2042).withOpacity(0.1),
                child: const Icon(Icons.person_rounded, color: Color(0xFF0F2042)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (formNumber.isNotEmpty) 'Form #$formNumber',
                        if (soughtFor != null && soughtFor.isNotEmpty) soughtFor,
                        if (academicYear != null && academicYear.isNotEmpty) academicYear,
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor(status)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}