import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/bill_admission_controller.dart';

class AdmissionBookSetupView extends StatefulWidget {
  const AdmissionBookSetupView({super.key});

  @override
  State<AdmissionBookSetupView> createState() => _AdmissionBookSetupViewState();
}

class _AdmissionBookSetupViewState extends State<AdmissionBookSetupView> {
  final BillAdmissionController _controller = Get.find<BillAdmissionController>();
  final AuthController _authController = Get.find<AuthController>();

  String? get _schoolId => _authController.user.value?.schoolId;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    final schoolId = _schoolId;
    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School ID not found. Please login again.')),
      );
      return;
    }
    await _controller.getAllAdmissionBooks(schoolId: schoolId);
  }

  String _bookId(Map<String, dynamic> book) => (book['_id'] ?? book['id'] ?? '').toString();

  bool _isActive(Map<String, dynamic> book) => book['isActive'] == true;

  Future<void> _toggleActive(Map<String, dynamic> book) async {
    final id = _bookId(book);
    if (id.isEmpty) return;

    final success = await _controller.updateAdmissionBook(
      admissionBookId: id,
      isActive: !_isActive(book),
    );
    if (success) _fetchBooks();
  }

  Future<void> _confirmDelete(Map<String, dynamic> book) async {
    final id = _bookId(book);
    if (id.isEmpty) return;

    if (_isActive(book)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deactivate this book before deleting it.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admission Book'),
        content: const Text('This action cannot be undone. Delete this admission book?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _controller.deleteInactiveAdmissionBook(admissionBookId: id);
      if (success) _fetchBooks();
    }
  }

  Future<void> _openSequenceDialog(Map<String, dynamic> book) async {
    final id = _bookId(book);
    if (id.isEmpty) return;

    // formNumber is a formatted string per the schema (e.g. "ADM-2026-001"),
    // not a plain integer.
    final currentFormNumber = (book['formNumber'] ?? book['currentFormNumber'] ?? '').toString();
    final controller = TextEditingController(text: currentFormNumber);

    final newValue = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adjust Form Number Sequence'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Next form number',
            hintText: 'e.g. ADM-2026-100',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue != null && newValue.isNotEmpty) {
      final success = await _controller.manuallyUpdateAdmissionFormNumber(
        admissionBookId: id,
        newFormNumber: newValue,
      );
      if (success) _fetchBooks();
    }
  }

  Future<void> _openCreateOrEditSheet({Map<String, dynamic>? existing}) async {
    final nameController = TextEditingController(text: existing?['bookName']?.toString() ?? '');
    final startingFormNumberController = TextEditingController(
      text: existing == null ? 'ADM-001' : '',
    );
    bool isActive = existing == null ? true : _isActive(existing);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existing == null ? 'Create Admission Book' : 'Edit Admission Book',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Note: creating a new admission book automatically deactivates any other active book for this school.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Book Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (existing == null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: startingFormNumberController,
                        decoration: InputDecoration(
                          labelText: 'Starting Form Number',
                          hintText: 'e.g. ADM-001',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      subtitle: const Text('Admissions can only be submitted while active'),
                      value: isActive,
                      onChanged: (value) => setSheetState(() => isActive = value),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(() {
                        final saving = _controller.isLoading.value;
                        return ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                            final schoolId = _schoolId;
                            if (schoolId == null) return;

                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Book Name is required.')),
                              );
                              return;
                            }

                            bool success;
                            if (existing == null) {
                              if (startingFormNumberController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Starting Form Number is required.')),
                                );
                                return;
                              }
                              success = await _controller.createNewAdmissionBook(
                                schoolId: schoolId,
                                bookName: nameController.text.trim(),
                                startingFormNumber: startingFormNumberController.text.trim(),
                              );
                            } else {
                              success = await _controller.updateAdmissionBook(
                                admissionBookId: _bookId(existing),
                                bookName: nameController.text.trim(),
                                isActive: isActive,
                              );
                            }

                            if (success) {
                              Get.back();
                              _fetchBooks();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: saving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : Text(existing == null ? 'Create' : 'Save Changes'),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admission Book Setup'),
        backgroundColor: const Color(0xFF0F2042),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A8A),
        onPressed: () => _openCreateOrEditSheet(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBooks,
        child: Obx(() {
          final books = _controller.admissionBooks;
          final loading = _controller.isLoading.value;

          if (loading && books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (books.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 140),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'No admission books yet. Create one to start accepting admissions for this school.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: books.length,
            itemBuilder: (context, index) => _buildBookCard(books[index]),
          );
        }),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    final name = book['bookName']?.toString() ?? 'Untitled Book';
    final year = book['academicYear']?.toString();
    final formNumber = (book['formNumber'] ?? book['currentFormNumber'])?.toString();
    final active = _isActive(book);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (year != null && year.isNotEmpty) year,
                          if (formNumber != null && formNumber.isNotEmpty) 'Next: $formNumber',
                        ].join(' · '),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: active,
                  activeColor: const Color(0xFF15803D),
                  onChanged: (_) => _toggleActive(book),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _openSequenceDialog(book),
                  icon: const Icon(Icons.format_list_numbered_rounded, size: 18),
                  label: const Text('Sequence'),
                ),
                TextButton.icon(
                  onPressed: () => _openCreateOrEditSheet(existing: book),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(book),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}