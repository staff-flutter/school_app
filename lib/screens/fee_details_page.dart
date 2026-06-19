import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:school_app/controllers/auth_controller.dart';
import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../services/user_session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class FeeRecord {
  final String id;
  final String studentName;
  final String studentImage;

  final Map<String, int> feeStructure;
  final Map<String, int> feePaid;
  final Map<String, int> dues;
  final ConcessionModel concession;

  FeeRecord({
    required this.id,
    required this.studentName,
    required this.studentImage,
    required this.feeStructure,
    required this.feePaid,
    required this.dues,
    required this.concession,
  });

  factory FeeRecord.fromJson(Map<String, dynamic> json) {
    Map<String, int> _toIntMap(Map<String, dynamic>? raw) {
      if (raw == null) return {};
      return raw.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
    }

    final student = json['studentId'] as Map<String, dynamic>? ?? {};
    final imgObj = student['studentImage'] as Map<String, dynamic>? ?? {};

    return FeeRecord(
      id: json['_id'] ?? '',
      studentName: student['studentName'] ?? 'Student',
      studentImage: imgObj['url'] ?? '',
      feeStructure: _toIntMap(json['feeStructure'] as Map<String, dynamic>?),
      feePaid: _toIntMap(json['feePaid'] as Map<String, dynamic>?),
      dues: _toIntMap(json['dues'] as Map<String, dynamic>?),
      concession: ConcessionModel.fromJson(
          json['concession'] as Map<String, dynamic>? ?? {}),
    );
  }

  int get totalFeeStructure => feeStructure.values.fold(0, (a, b) => a + b);
  int get totalPaid => feePaid.values.fold(0, (a, b) => a + b);
  int get totalDues => dues.values.fold(0, (a, b) => a + b);
}

class ConcessionModel {
  final bool isApplied;
  final String type; // "percentage" | "fixed"
  final num value;
  final int inAmount;
  final String proofUrl;
  final String approvedBy;

  ConcessionModel({
    required this.isApplied,
    required this.type,
    required this.value,
    required this.inAmount,
    required this.proofUrl,
    required this.approvedBy,
  });

  factory ConcessionModel.fromJson(Map<String, dynamic> json) {
    final proof = json['proof'] as Map<String, dynamic>? ?? {};
    return ConcessionModel(
      isApplied: json['isApplied'] ?? false,
      type: json['type'] ?? 'percentage',
      value: (json['value'] as num?) ?? 0,
      inAmount: (json['inAmount'] as num?)?.toInt() ?? 0,
      proofUrl: proof['url'] ?? '',
      approvedBy: json['approvedBy']?.toString() ?? 'Pending',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class FeeDetailsFirstPage extends StatefulWidget {
  const FeeDetailsFirstPage({super.key});

  @override
  State<FeeDetailsFirstPage> createState() => _FeeDetailsFirstPageState();
}

class _FeeDetailsFirstPageState extends State<FeeDetailsFirstPage>
    with SingleTickerProviderStateMixin {
 // final session = Get.find<UserSession>();
  final auth_ctrl = Get.find<AuthController>();
  late TabController _tabController;
  late Future<FeeRecord?> _feeFuture;

  static const LinearGradient appGradient = LinearGradient(
    colors: [Color(0xff4A90E2), Color(0xff6FD3F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color _blue = Color(0xff4A90E2);

  final List<_TabMeta> _tabs = const [
    _TabMeta(icon: Icons.receipt_long_outlined, label: 'Fee Structure'),
    _TabMeta(icon: Icons.warning_amber_rounded, label: 'Dues'),
    _TabMeta(icon: Icons.check_circle_outline_rounded, label: 'Paid'),
    _TabMeta(icon: Icons.card_giftcard_rounded, label: 'Concession'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _feeFuture = _fetchFeeRecord();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<FeeRecord?> _fetchFeeRecord() async {
    final controller = Get.find<MyChildrenController>();
    final String token = auth_ctrl.storage.read('token');
    final String schoolId = auth_ctrl.user.value?.schoolId;
    final String studentId = controller.selectedChild['_id'] ?? '';

    final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/studentrecord/v1/getrecord/6a2bbf056bd3369bde740aec/6a2bd2376bd3369bde7411d3?academicYear=2026-2027');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      print('Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Response Data: ${response.body}');
        final body = jsonDecode(response.body);
        final data = body['data'];
        if (data != null) return FeeRecord.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
    print('fetchrecord');
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/Scientific UI background design header.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        title: const Text('Fee Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.8)),
        ),
        toolbarHeight: MediaQuery.sizeOf(context).height * 0.10,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.only(topRight: Radius.circular(28)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: _blue,
              indicatorWeight: 3,
              labelColor: _blue,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              tabs: _tabs
                  .map((t) => Tab(
                icon: Icon(t.icon, size: 18),
                text: t.label,
                iconMargin: const EdgeInsets.only(bottom: 2),
              ))
                  .toList(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<FeeRecord?>(
          future: _feeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final record = snapshot.data;
            if (record == null) {
              return const Center(child: Text("No fee data found"));
            }

            return Column(
              children: [
                // ── Student summary strip ──────────────────────────────────
                _StudentSummaryCard(record: record, gradient: appGradient),
                // ── Tab views ─────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _FeeStructureTab(record: record),
                      _DuesTab(record: record),
                      _PaidTab(record: record),
                      _ConcessionTab(record: record),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STUDENT SUMMARY STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _StudentSummaryCard extends StatelessWidget {
  final FeeRecord record;
  final LinearGradient gradient;
  const _StudentSummaryCard(
      {required this.record, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: record.studentImage.isNotEmpty
                ? NetworkImage(record.studentImage)
                : null,
            backgroundColor: const Color(0xff4A90E2).withOpacity(0.15),
            child: record.studentImage.isEmpty
                ? const Icon(Icons.person, color: Color(0xff4A90E2))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.studentName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text('Academic Year Fee Summary',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          // Total outstanding badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Total Due',
                    style:
                    TextStyle(color: Colors.white70, fontSize: 10)),
                Text('₹ ${record.totalDues}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 – FEE STRUCTURE
// ─────────────────────────────────────────────────────────────────────────────

class _FeeStructureTab extends StatelessWidget {
  final FeeRecord record;
  const _FeeStructureTab({required this.record});

  static const _labels = {
    'admissionFee': 'Admission Fee',
    'firstTermAmt': 'Term 1 Fee',
    'secondTermAmt': 'Term 2 Fee',
    'busFirstTermAmt': 'Bus Fee (Term 1)',
    'busSecondTermAmt': 'Bus Fee (Term 2)',
  };

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      headerColor: const Color(0xff4A90E2),
      headerIcon: Icons.receipt_long_outlined,
      headerTitle: 'Fee Structure',  // full label in content header
      headerSubtitle: 'Total: ₹ ${record.totalFeeStructure}',
      child: _FeeTable(
        rows: _labels.entries
            .where((e) => record.feeStructure.containsKey(e.key))
            .map((e) =>
            _FeeRow(label: e.value, amount: record.feeStructure[e.key]!))
            .toList(),
        totalLabel: 'Grand Total',
        totalAmount: record.totalFeeStructure,
        accentColor: const Color(0xff4A90E2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 – DUES
// ─────────────────────────────────────────────────────────────────────────────

class _DuesTab extends StatelessWidget {
  final FeeRecord record;
  const _DuesTab({required this.record});

  static const _labels = {
    'admissionDues': 'Admission Dues',
    'firstTermDues': 'Term 1 Dues',
    'secondTermDues': 'Term 2 Dues',
    'busfirstTermDues': 'Bus Dues (Term 1)',
    'busSecondTermDues': 'Bus Dues (Term 2)',
  };

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      headerColor: const Color(0xffE25F4A),
      headerIcon: Icons.warning_amber_rounded,
      headerTitle: 'Outstanding Dues',
      headerSubtitle: 'Pending: ₹ ${record.totalDues}',
      child: _FeeTable(
        rows: _labels.entries
            .where((e) => record.dues.containsKey(e.key))
            .map((e) =>
            _FeeRow(label: e.value, amount: record.dues[e.key]!))
            .toList(),
        totalLabel: 'Total Dues',
        totalAmount: record.totalDues,
        accentColor: const Color(0xffE25F4A),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 – PAID
// ─────────────────────────────────────────────────────────────────────────────

class _PaidTab extends StatelessWidget {
  final FeeRecord record;
  const _PaidTab({required this.record});

  static const _labels = {
    'admissionFee': 'Admission Fee',
    'firstTermAmt': 'Term 1 Fee',
    'secondTermAmt': 'Term 2 Fee',
    'busFirstTermAmt': 'Bus Fee (Term 1)',
    'busSecondTermAmt': 'Bus Fee (Term 2)',
  };

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      headerColor: const Color(0xff27AE60),
      headerIcon: Icons.check_circle_outline_rounded,
      headerTitle: 'Amount Paid',
      headerSubtitle: 'Paid: ₹ ${record.totalPaid}',
      child: _FeeTable(
        rows: _labels.entries
            .where((e) => record.feePaid.containsKey(e.key))
            .map((e) =>
            _FeeRow(label: e.value, amount: record.feePaid[e.key]!))
            .toList(),
        totalLabel: 'Total Paid',
        totalAmount: record.totalPaid,
        accentColor: const Color(0xff27AE60),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 – CONCESSION
// ─────────────────────────────────────────────────────────────────────────────

class _ConcessionTab extends StatelessWidget {
  final FeeRecord record;
  const _ConcessionTab({required this.record});

  @override
  Widget build(BuildContext context) {
    final c = record.concession;
    final discountLabel =
    c.type == 'percentage' ? '${c.value}%' : '₹ ${c.value}';

    return _TabScaffold(
      headerColor: const Color(0xff8E44AD),
      headerIcon: Icons.card_giftcard_rounded,
      headerTitle: 'Concession',
      headerSubtitle: c.isApplied ? 'Applied · $discountLabel off' : 'Not Applied',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chip
            _InfoChip(
              label: c.isApplied ? 'Concession Applied' : 'Not Applied',
              color: c.isApplied
                  ? const Color(0xff27AE60)
                  : Colors.grey.shade400,
              icon: c.isApplied
                  ? Icons.check_circle
                  : Icons.cancel_outlined,
            ),
            const SizedBox(height: 20),

            _ConcessionDetailCard(
              rows: [
                _DetailRow(label: 'Type', value: c.type.capitalize ?? c.type),
                _DetailRow(
                    label: 'Discount',
                    value: c.type == 'percentage'
                        ? '${c.value}%'
                        : '₹ ${c.value}'),
                _DetailRow(
                    label: 'Concession Amount', value: '₹ ${c.inAmount}'),
                _DetailRow(
                    label: 'Approved By',
                    value: (c.approvedBy.isEmpty || c.approvedBy == 'null')
                        ? 'Pending'
                        : c.approvedBy),
              ],
            ),
            const SizedBox(height: 20),

            if (c.proofUrl.isNotEmpty) ...[
              const Text('Proof Document',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff8E44AD))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showFullScreenImage(context, c.proofUrl),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        c.proofUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text('Unable to load proof image'),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_out_map,
                                color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text('Tap to expand',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showFullScreenImage(BuildContext context, String url) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _FullScreenImageViewer(url: url),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL SCREEN IMAGE VIEWER
// ─────────────────────────────────────────────────────────────────────────────

class _FullScreenImageViewer extends StatefulWidget {
  final String url;
  const _FullScreenImageViewer({required this.url});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformController =
  TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() => _transformController.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Proof Document',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Colors.white),
            tooltip: 'Reset zoom',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, color: Colors.white54, size: 64),
                SizedBox(height: 12),
                Text('Unable to load image',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Colored header card + scrollable body
class _TabScaffold extends StatelessWidget {
  final Color headerColor;
  final IconData headerIcon;
  final String headerTitle;
  final String headerSubtitle;
  final Widget child;

  const _TabScaffold({
    required this.headerColor,
    required this.headerIcon,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Colored header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: headerColor.withOpacity(0.08),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(headerIcon, color: headerColor, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headerTitle,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: headerColor,
                          fontSize: 15)),
                  Text(headerSubtitle,
                      style: TextStyle(
                          color: headerColor.withOpacity(0.7),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: SingleChildScrollView(child: child)),
      ],
    );
  }
}

class _FeeRow {
  final String label;
  final int amount;
  const _FeeRow({required this.label, required this.amount});
}

class _FeeTable extends StatelessWidget {
  final List<_FeeRow> rows;
  final String totalLabel;
  final int totalAmount;
  final Color accentColor;

  const _FeeTable({
    required this.rows,
    required this.totalLabel,
    required this.totalAmount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            ...rows.map((r) => _buildRow(r.label, r.amount, false)),
            const Divider(height: 1, thickness: 1),
            _buildRow(totalLabel, totalAmount, true),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, int amount, bool isTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: isTotal
          ? BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16)),
      )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 14 : 13,
                  fontWeight:
                  isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? accentColor : Colors.black87)),
          Text(
            '₹ $amount',
            style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight:
                isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? accentColor : Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _ConcessionDetailCard extends StatelessWidget {
  final List<_DetailRow> rows;
  const _ConcessionDetailCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: rows
            .map(
              (r) => ListTile(
            dense: true,
            title: Text(r.label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
            trailing: Text(r.value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        )
            .toList(),
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _InfoChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _TabMeta {
  final IconData icon;
  final String label;
  const _TabMeta({required this.icon, required this.label});
}