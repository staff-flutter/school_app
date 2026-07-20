import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/school_controller.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  MODEL
// ═════════════════════════════════════════════════════════════════════════════

class BillBook {
  final String id;
  final String bookName;
  final int billNumber;       // current/next sequence number
  final String academicYear;
  final bool isActive;
  final String? createdByName;

  const BillBook({
    required this.id,
    required this.bookName,
    required this.billNumber,
    required this.academicYear,
    required this.isActive,
    this.createdByName,
  });

  factory BillBook.fromJson(Map<String, dynamic> j) => BillBook(
    id: j['_id'] ?? '',
    bookName: j['bookName'] ?? '',
    // NOTE: doc doesn't give the exact response field name for the running
    // sequence — trying a few likely candidates. Confirm against a real
    // GET response and adjust if the actual key differs.
    billNumber: _parseInt(j['billNumber'] ?? j['currentBillNumber'] ?? j['sequence']),
    academicYear: j['academicYear'] ?? '',
    isActive: j['isActive'] ?? false,
    createdByName: j['createdBy'] is Map ? j['createdBy']['name'] : null,
  );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class BillBookManagementScreen extends StatefulWidget {
  //final String schoolId;
  const BillBookManagementScreen({super.key});

  @override
  State<BillBookManagementScreen> createState() => _BillBookManagementScreenState();
}

class _BillBookManagementScreenState extends State<BillBookManagementScreen> {
  final _auth = Get.find<AuthController>();
  final schoolController = Get.find<SchoolController>();
  List<BillBook> _books = [];
  bool _loading = true;
  Worker? _schoolWorker;

  String? get _schoolId {
    final role = _auth.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') {
      return schoolController.selectedSchool.value?.id;
    }
    return _auth.user.value?.schoolId;
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${_auth.storage.read('token')}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  void _log(String method, Uri uri, http.Response? res, {Object? err}) {
    debugPrint('▶️ [BILLBOOK API] $method $uri');
    if (res != null) debugPrint('◀️ [BILLBOOK API] $method $uri -> ${res.statusCode}\n   body: ${res.body}');
    if (err != null) debugPrint('❌ [BILLBOOK API] $method $uri -> ERROR: $err');
  }

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    final role = _auth.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') {
      _schoolWorker = ever(schoolController.selectedSchool, (_) {
        if (mounted) _fetchBooks();
      });
    }
  }
  @override
  void dispose() {
    _schoolWorker?.dispose();
    super.dispose();
  }
  // ── API: fetch all bill books for this school ──────────────────────────
  // GET /api/school-config/bill-book/:schoolId
  Future<void> _fetchBooks() async {
    final sid = _schoolId;
    if (sid == null || sid.isEmpty) {
      debugPrint('⚠️ [BILLBOOK API] GET skipped — schoolId is null');
      setState(() { _loading = false; _books = []; });
      return;
    }
    setState(() => _loading = true);
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllBillBooks}/$sid');
    try {
      final res = await http.get(uri, headers: _headers);
      _log('GET', uri, res);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] as List? ?? []).map((e) => BillBook.fromJson(e)).toList();
        setState(() { _books = list; _loading = false; });
      } else {
        setState(() => _loading = false);
        _snack('Failed to load bill books');
      }
    } catch (e) {
      _log('GET', uri, null, err: e);
      setState(() => _loading = false);
      _snack('Error loading bill books');
    }
  }

  // ── API: create a new bill book ─────────────────────────────────────────
  // POST /api/school-config/bill-book/
  // Body: { schoolId, bookName, billNumber }
  Future<void> _createBook(String bookName, int startingNumber) async {
    final sid = _schoolId;
    if (sid == null || sid.isEmpty) { _snack('No school selected'); return; }
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createNewBillBook}');
    final payload = {
      'schoolId': sid,
      'bookName': bookName,
      'billNumber': startingNumber,
    };
    try {
      final res = await http.post(uri, headers: _headers, body: jsonEncode(payload));
      _log('POST', uri, res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack('Bill book created', success: true);
        _fetchBooks(); // backend deactivates old active book automatically
      } else {
        _snack('Failed: ${_msg(res)}');
      }
    } catch (e) {
      _log('POST', uri, null, err: e);
      _snack('Error: $e');
    }
  }

  // ── API: update bill book (name and/or active status) ──────────────────
  // PATCH /api/school-config/bill-book/:id
  // Body: { bookName?, isActive? }
  Future<void> _updateBook(BillBook book, {String? bookName, bool? isActive}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateBillBook}/${book.id}');
    final payload = <String, dynamic>{
      if (bookName != null) 'bookName': bookName,
      if (isActive != null) 'isActive': isActive,
    };
    try {
      final res = await http.patch(uri, headers: _headers, body: jsonEncode(payload));
      _log('PATCH', uri, res);
      if (res.statusCode == 200) {
        _snack('Updated', success: true);
        _fetchBooks(); // activating one deactivates the others — refresh full list
      } else {
        // Doc explicitly notes: "Cannot deactivate the only active bill book."
        // — surface that backend message directly rather than a generic one.
        _snack(_msg(res));
      }
    } catch (e) {
      _log('PATCH', uri, null, err: e);
      _snack('Error: $e');
    }
  }

  // ── API: manually override the running sequence number ─────────────────
  // PATCH /api/school-config/bill-book/:id/sequence
  // Body: { newBillNumber }
  Future<void> _updateSequence(BillBook book, int newNumber) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.manuallyUpdateBillNumber.replaceFirst(':id', book.id)}');
    try {
      final res = await http.patch(uri, headers: _headers, body: jsonEncode({'newBillNumber': newNumber}));
      _log('PATCH', uri, res);
      if (res.statusCode == 200) {
        _snack('Sequence updated', success: true);
        _fetchBooks();
      } else {
        _snack('Failed: ${_msg(res)}');
      }
    } catch (e) {
      _log('PATCH', uri, null, err: e);
      _snack('Error: $e');
    }
  }

  // ── API: delete an inactive bill book ───────────────────────────────────
  // DELETE /api/school-config/bill-book/:id
  Future<void> _deleteBook(BillBook book) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteInactiveBillBook}/${book.id}');
    try {
      final res = await http.delete(uri, headers: _headers);
      _log('DELETE', uri, res);
      if (res.statusCode == 200) {
        _snack('Deleted', success: true);
        setState(() => _books.removeWhere((b) => b.id == book.id));
      } else {
        // Doc: "Active bill books cannot be deleted" — backend message covers this.
        _snack(_msg(res));
      }
    } catch (e) {
      _log('DELETE', uri, null, err: e);
      _snack('Error: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _msg(http.Response r) {
    try { return jsonDecode(r.body)['message'] ?? 'Request failed (${r.statusCode})'; }
    catch (_) { return 'Request failed (${r.statusCode})'; }
  }

  void _snack(String msg, {bool success = false}) {
    Get.snackbar(success ? 'Success' : 'Error', msg,
        backgroundColor: success ? const Color(0xFF22C55E) : Colors.redAccent,
        colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final numCtrl = TextEditingController(text: '1');

    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('New bill book', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Book name')),
        const SizedBox(height: 12),
        TextField(controller: numCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Starting bill number')),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: Text(
          'Creating this book will automatically deactivate the current active book.',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        )),
      ]),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            final num = int.tryParse(numCtrl.text.trim());
            if (name.isEmpty || num == null) {
              _snack('Enter a valid name and starting number', success: false);
              return;
            }
            Get.back();
            _createBook(name, num);
          },
          child: const Text('Create'),
        ),
      ],
    ));
  }

  void _showSequenceDialog(BillBook book) {
    final ctrl = TextEditingController(text: '${book.billNumber}');
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Update sequence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New next bill number')),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final num = int.tryParse(ctrl.text.trim());
            if (num == null) { _snack('Enter a valid number'); return; }
            Get.back();
            _updateSequence(book, num);
          },
          child: const Text('Save'),
        ),
      ],
    ));
  }

  void _confirmDelete(BillBook book) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete bill book?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      content: Text('Delete "${book.bookName}"? This can\'t be undone.', style: const TextStyle(fontSize: 13)),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () { Get.back(); _deleteBook(book); },
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Bill Books', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.black), onPressed: _showCreateDialog),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
          ? Center(child: Text('No bill books yet — tap + to create one.', style: TextStyle(color: Colors.grey[600])))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _books.length,
        itemBuilder: (ctx, i) {
          final book = _books[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: book.isActive ? Colors.blue.shade300 : Colors.grey.shade200,
                  width: book.isActive ? 1.5 : 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(book.bookName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                if (book.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Text('Active', style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.w700)),
                  ),
              ]),
              const SizedBox(height: 4),
              Text('Next number: ${book.billNumber} · ${book.academicYear}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (!book.isActive)
                  OutlinedButton(
                    onPressed: () => _updateBook(book, isActive: true),
                    child: const Text('Activate', style: TextStyle(fontSize: 12)),
                  ),
                OutlinedButton(
                  onPressed: () => _showSequenceDialog(book),
                  child: const Text('Edit sequence', style: TextStyle(fontSize: 12)),
                ),
                if (!book.isActive)
                  OutlinedButton(
                    onPressed: () => _confirmDelete(book),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete', style: TextStyle(fontSize: 12)),
                  ),
              ]),
            ]),
          );
        },
      ),
    );
  }
}