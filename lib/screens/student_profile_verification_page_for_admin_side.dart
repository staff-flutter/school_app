import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:school_app/controllers/school_controller.dart';

import '../constants/api_constants.dart';
import '../controllers/auth_controller.dart';
import '../services/user_session.dart';


// ── Model ─────────────────────────────────────────────────────────
class PendingProfileRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String requestedBy;
  final Map<String, String> changes;
  final Map<String, String> previousValues;
  final String status;
  final DateTime createdAt;

  PendingProfileRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.requestedBy,
    required this.changes,
    required this.previousValues,
    required this.status,
    required this.createdAt,
  });

  factory PendingProfileRequest.fromJson(Map<String, dynamic> json) {
    final student = json['studentId'] is Map ? json['studentId'] : {};
    final requester = json['requestedBy'] is Map ? json['requestedBy'] : {};

    return PendingProfileRequest(
      id:             json['_id']?.toString() ?? '',
      studentId:      student['_id']?.toString() ?? json['studentId']?.toString() ?? '',
      studentName:    student['studentName']?.toString() ?? student['userName']?.toString() ?? 'Unknown',
      className:      student['class']?.toString() ?? student['classId']?.toString() ?? '—',
      requestedBy:    requester['userName']?.toString() ?? 'Parent',
      changes:        (json['changes'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
      previousValues: (json['previousValues'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
      status:         json['status']?.toString() ?? 'pending',
      createdAt:      DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

// ── Page ──────────────────────────────────────────────────────────
class ProfileVerificationPage extends StatefulWidget {
  const ProfileVerificationPage({super.key});

  @override
  State<ProfileVerificationPage> createState() =>
      _ProfileVerificationPageState();
}

class _ProfileVerificationPageState extends State<ProfileVerificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _noteCtrl = TextEditingController();

  List<PendingProfileRequest> _pending  = [];
  List<PendingProfileRequest> _resolved = [];
  bool _isLoading = true;
  final Set<String> _processingIds = {};

  String? _lastFetchedSchoolId;
  Worker? _schoolWatcher;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Initial fetch
      _fetchRequests();

      try {
        final schoolController = Get.find<SchoolController>();

        // 2. Watch for subsequent changes
        _schoolWatcher = ever(schoolController.selectedSchool, (school) {
          if (!mounted) return;
          debugPrint('🔄 Sidebar school changed to: ${school?.id}. Refetching requests...');
          final newId = school?.id;
          final role = Get.find<AuthController>().user.value?.role?.toLowerCase();

          if (role == 'correspondent' && newId != _lastFetchedSchoolId && newId != null) {
            debugPrint('🔄 School changed in sidebar to: $newId. Refetching...');
            _fetchRequests();
          }
        });
      } catch (e) {
        debugPrint('SchoolController missing: $e');
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _noteCtrl.dispose();
    _schoolWatcher?.dispose();
    super.dispose();
  }

  String? _getToken() {
    try { return Get.find<AuthController>().storage.read('token'); } catch (_) { return null; }
  }

  String? _getSchoolId() {
    try {
      final userObj = Get.find<AuthController>().user.value;
      final role = userObj?.role?.toLowerCase();

      if (role == 'correspondent') {
        final selectedId = Get.find<SchoolController>().selectedSchool.value?.id;
        // If the sidebar selection is empty or uninitialized, fall back to the user's main schoolId
        return (selectedId != null && selectedId.isNotEmpty) ? selectedId : userObj?.schoolId;
      }

      return userObj?.schoolId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchRequests() async {
    if (!mounted) return;
 //final String schoolId = _getSchoolId();
    final token    = _getToken();
    final schoolId = _getSchoolId();
    print('schoolid: $schoolId');
    print('token: $token');


    if (token == null || schoolId == null) {
      setState(() => _isLoading = false);
      _snack('Session expired or invalid. Please log in again.', Colors.red.shade700);
      return;
    }
    _lastFetchedSchoolId = schoolId;
    setState(() => _isLoading = true);

    try {
      final pendingUri = Uri.parse('${ApiConstants.baseUrl}/api/student/all-pending')
          .replace(queryParameters: {
        'schoolId': schoolId,
        'status': 'pending',
      });

      final resolvedUri = Uri.parse('${ApiConstants.baseUrl}/api/student/all-pending')
          .replace(queryParameters: {
        'schoolId': schoolId,
        'status': 'resolved',
      });

      debugPrint('--- AUTH DIAGNOSTICS ---');
      debugPrint('Active User Role: ${Get.find<UserSession>().role}');
      debugPrint('Requesting SchoolID: $schoolId');
      debugPrint('Pending URI : $pendingUri');
      debugPrint('Resolved URI: $resolvedUri');
      debugPrint('Token snippet: ${token.length > 20 ? token.substring(0, 20) : token}...');
      debugPrint('------------------------');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      // .timeout() added — without this, a hung/unresponsive server just
      // sits on `await` forever with zero logging, which is exactly what
      // was happening. Each request now fails loudly after 15s instead.
      debugPrint('▶ sending GET $pendingUri ...');
      final pendingResponse = await http
          .get(pendingUri, headers: headers)
          .timeout(const Duration(seconds: 15));
      debugPrint('◀ PENDING  status=${pendingResponse.statusCode} body=${pendingResponse.body}');

      debugPrint('▶ sending GET $resolvedUri ...');
      final resolvedResponse = await http
          .get(resolvedUri, headers: headers)
          .timeout(const Duration(seconds: 15));
      debugPrint('◀ RESOLVED status=${resolvedResponse.statusCode} body=${resolvedResponse.body}');

      List<PendingProfileRequest> parse(http.Response r) {
        if (r.statusCode != 200) {
          debugPrint('API Error Status [${r.statusCode}]: ${r.body}');
          return [];
        }
        final decoded = jsonDecode(r.body);
        if (decoded is! Map<String, dynamic>) {
          debugPrint('✗ Unexpected response shape: ${decoded.runtimeType}');
          return [];
        }
        if (decoded['ok'] != true) {
          debugPrint('✗ ok!=true — message: ${decoded['message']}');
        }
        final list = decoded['data'] as List? ?? [];
        debugPrint('▶ parsed ${list.length} item(s)');
        return list
            .map((j) => PendingProfileRequest.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      if (mounted) {
        setState(() {
          _pending  = parse(pendingResponse);
          _resolved = parse(resolvedResponse);
          _isLoading = false;
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('✗ Request TIMED OUT: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Server took too long to respond. Check your connection / API.', Colors.red.shade700);
      }
    } catch (e, st) {
      debugPrint('Fetch requests error: $e\n$st');
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _reviewRequest(
      PendingProfileRequest req,
      String action, // 'approved' | 'rejected'
      String note,
      ) async {
    setState(() => _processingIds.add(req.id));
    final token = _getToken();

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/student/review-request/${req.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action, 'reviewNote': note}),
      );

      if (response.statusCode == 200) {
        // Move from pending to resolved
        final updated = PendingProfileRequest(
          id:             req.id,
          studentId:      req.studentId,
          studentName:    req.studentName,
          className:      req.className,
          requestedBy:    req.requestedBy,
          changes:        req.changes,
          previousValues: req.previousValues,
          status:         action,
          createdAt:      req.createdAt,
        );
        setState(() {
          _pending.removeWhere((r) => r.id == req.id);
          _resolved.insert(0, updated);
        });
        _snack(
          action == 'approved' ? '✓ Profile updated' : '✗ Request rejected',
          action == 'approved' ? Colors.green : Colors.red.shade700,
        );
      } else {
        debugPrint('Review failed: ${response.statusCode} ${response.body}');
        _snack('Failed — try again', Colors.red.shade700);
      }
    } catch (e) {
      debugPrint('Review error: $e');
      _snack('Connection error', Colors.red.shade700);
    } finally {
      setState(() => _processingIds.remove(req.id));
    }
  }

  void _showReviewDialog(PendingProfileRequest req, String action) {
    _noteCtrl.clear();
    final isApprove = action == 'approved';

    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isApprove ? Colors.green.shade50 : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isApprove ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isApprove ? Colors.green : Colors.red,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isApprove ? 'Approve Changes?' : 'Reject Changes?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            isApprove
                ? 'This will update the student\'s profile with the new values.'
                : 'The parent will need to re-submit the request.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: isApprove
                  ? 'Add a note (optional)...'
                  : 'Reason for rejection (optional)...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  _reviewRequest(req, action, _noteCtrl.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isApprove ? Colors.green : Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(isApprove ? 'Approve' : 'Reject'),
              ),
            ),
          ]),
        ]),
      ),
    ));
  }

  void _snack(String msg, Color color) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      Get.snackbar('', msg,
          titleText: const SizedBox.shrink(),
          messageText: Text(msg, style: const TextStyle(color: Colors.white)),
          backgroundColor: color,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
          duration: const Duration(seconds: 3));
    });
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios_new,
        //       size: 18, color: Color(0xFF1A1A2E)),
        //   onPressed: () => Get.back(),
        // ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.pending_actions_rounded,
                color: Colors.orange.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Profile Verification',
              style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A1A2E)),
            onPressed: _fetchRequests,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                    width: 3, color: Colors.orange.shade700),
                insets: const EdgeInsets.symmetric(horizontal: 16),
              ),
              labelColor: Colors.orange.shade700,
              unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: [
                Tab(child: Row(children: [
                  const Icon(Icons.pending_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Pending'),
                  if (_pending.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_pending.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ])),
                const Tab(child: Row(children: [
                  Icon(Icons.history_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('History'),
                ])),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A90E2)))
          : TabBarView(
        controller: _tabCtrl,
        children: [
          _buildPendingTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ── Pending tab ──────────────────────────────────────────────────
  Widget _buildPendingTab() {
    if (_pending.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_rounded,
                size: 40, color: Colors.green.shade400),
          ),
          const SizedBox(height: 16),
          const Text('All caught up!',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          Text('No pending profile update requests.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _pending.length,
      itemBuilder: (_, i) => _buildRequestCard(_pending[i], isPending: true),
    );
  }

  // ── History tab ──────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    if (_resolved.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.history_rounded,
                size: 40, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text('No history yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _resolved.length,
      itemBuilder: (_, i) =>
          _buildRequestCard(_resolved[i], isPending: false),
    );
  }

  // ── Request card ─────────────────────────────────────────────────
  Widget _buildRequestCard(PendingProfileRequest req,
      {required bool isPending}) {
    final isProcessing = _processingIds.contains(req.id);
    final isApproved   = req.status == 'approved';
    final isRejected   = req.status == 'rejected';

    final statusColor = isPending
        ? Colors.orange.shade700
        : isApproved
        ? Colors.green
        : Colors.red.shade700;

    final statusLabel = isPending
        ? 'Pending'
        : isApproved
        ? 'Approved'
        : 'Rejected';

    final statusIcon = isPending
        ? Icons.pending_rounded
        : isApproved
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    // Format date
    final d = req.createdAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Card header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade50,
              child: Text(
                req.studentName.isNotEmpty
                    ? req.studentName[0].toUpperCase()
                    : 'S',
                style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.studentName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 2),
                    Text('Requested by ${req.requestedBy}  ·  $dateStr',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500])),
                  ]),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: statusColor.withOpacity(0.3), width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ]),
            ),
          ]),
        ),

        Divider(height: 1, color: Colors.grey.shade100),

        // ── Changed fields ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${req.changes.length} field${req.changes.length == 1 ? '' : 's'} changed',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600])),
              const SizedBox(height: 10),
              ...req.changes.entries.map((entry) {
                final oldVal = req.previousValues[entry.key] ?? '—';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.grey.shade200, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      Row(children: [
                        // Old value
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500])),
                              const SizedBox(height: 2),
                              Text(
                                oldVal.isNotEmpty ? oldVal : '—',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isRejected
                                      ? Colors.black87
                                      : Colors.black54,
                                  decoration: isApproved
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Arrow
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 14,
                              color: isPending
                                  ? Colors.orange.shade600
                                  : isApproved
                                  ? Colors.green
                                  : Colors.red.shade400),
                        ),
                        // New value
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Requested',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500])),
                              const SizedBox(height: 2),
                              Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isPending
                                      ? Colors.orange.shade900
                                      : isApproved
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // ── Action buttons (only on pending) ─────────────────────
        if (isPending) ...[
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: isProcessing
                ? const Center(
                child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)))
                : Row(children: [
              // Reject button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showReviewDialog(req, 'rejected'),
                  icon: Icon(Icons.close_rounded,
                      size: 16, color: Colors.red.shade700),
                  label: Text('Reject',
                      style:
                      TextStyle(color: Colors.red.shade700)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                    const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Approve button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showReviewDialog(req, 'approved'),
                  icon: const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white),
                  label: const Text('Approve',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                    const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}