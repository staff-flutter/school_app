import 'package:get/get.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/controllers/auth_controller.dart';

// ─── Range helpers ────────────────────────────────────────────────────────────
String _rangeToApi(String range) {
  switch (range) {
    case 'today':     return 'today';
    case 'this_week': return 'week';
    case 'this_year': return 'year';
    default:          return 'month'; // this_month
  }
}

String _rangeLabel(String range) {
  switch (range) {
    case 'today':     return 'Today';
    case 'this_week': return 'This Week';
    case 'this_year': return 'This Year';
    default:          return 'This Month';
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────
class ReportsController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final AuthController _auth = Get.find<AuthController>();

  // ── UI state ─────────────────────────────────────────────────────────────────
  final selectedReportType = 'overview'.obs;
  final selectedRange      = 'this_month'.obs;
  final isLoading          = false.obs;
  final hasData            = false.obs;
  final errorMessage       = ''.obs;

  // ── Loaded data ───────────────────────────────────────────────────────────────
  final financeStats   = Rxn<Map<String, dynamic>>();
  final feeStats       = Rxn<Map<String, dynamic>>();
  final expenseStats   = Rxn<Map<String, dynamic>>();
  final timelineData   = <Map<String, dynamic>>[].obs;
  final studentRecords = <Map<String, dynamic>>[].obs;
  final expenseList    = <Map<String, dynamic>>[].obs;

  // ── Getters ───────────────────────────────────────────────────────────────────
  String? get schoolId => _auth.user.value?.schoolId;
  String get rangeLabel => _rangeLabel(selectedRange.value);

  // ── Derived expense stats ─────────────────────────────────────────────────────
  Map<String, double> get expenseByCategory {
    final Map<String, double> map = {};
    for (final e in expenseList) {
      final cat = (e['category'] as String?) ?? 'Other';
      final amt = (e['amount'] as num?)?.toDouble() ?? 0;
      map[cat] = (map[cat] ?? 0) + amt;
    }
    return map;
  }

  double get totalExpenses =>
      expenseList.fold(0.0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));

  int get pendingExpenses =>
      expenseList.where((e) => (e['verificationStatus'] ?? e['status']) == 'pending').length;

  // ── Derived student / fee stats ───────────────────────────────────────────────
  List<Map<String, dynamic>> get concessionStudents =>
      studentRecords.where((r) => r['hasConcession'] == true).toList();

  double get totalConcessionAmount => concessionStudents.fold(0.0, (s, r) {
    final cs = r['concessionAmount'] ?? r['concession']?['amount'] ?? 0;
    return s + (cs as num).toDouble();
  });

  // ── Load everything ───────────────────────────────────────────────────────────
  Future<void> loadReportData() async {
    final sid = schoolId;
    if (sid == null || sid.isEmpty) {
      errorMessage.value = 'School ID not found';
      return;
    }
    isLoading.value = true;
    hasData.value   = false;
    errorMessage.value = '';

    try {
      final apiRange = _rangeToApi(selectedRange.value);

      await Future.wait([
        _fetchStats(sid, apiRange),
        _fetchTimeline(sid, apiRange),
        _fetchStudentRecords(sid),
        _fetchExpenses(sid),
      ]);

      hasData.value = true;
    } catch (e) {
      errorMessage.value = 'Failed to load report data. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────────
  Future<void> _fetchStats(String sid, String range) async {
    try {
      // Overall stats
      final overall = await _api.get('/api/financeledger/stats',
          queryParameters: {'schoolId': sid, 'range': range});
      if (overall.data?['ok'] == true || overall.data?['data'] != null) {
        financeStats.value = overall.data?['data'] as Map<String, dynamic>?;
      }

      // Fee-only stats
      final fee = await _api.get('/api/financeledger/stats',
          queryParameters: {'schoolId': sid, 'range': range, 'section': 'student_record'});
      if (fee.data?['data'] != null) {
        feeStats.value = fee.data['data'] as Map<String, dynamic>?;
      }

      // Expense-only stats
      final exp = await _api.get('/api/financeledger/stats',
          queryParameters: {'schoolId': sid, 'range': range, 'section': 'expense'});
      if (exp.data?['data'] != null) {
        expenseStats.value = exp.data['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
  }

  Future<void> _fetchTimeline(String sid, String range) async {
    try {
      final res = await _api.get('/api/financeledger/timeline',
          queryParameters: {'schoolId': sid, 'range': range});
      if (res.data?['ok'] == true && res.data?['data'] != null) {
        timelineData.value =
            List<Map<String, dynamic>>.from(res.data['data'] as List);
      }
    } catch (_) {}
  }

  Future<void> _fetchStudentRecords(String sid) async {
    try {
      final res = await _api.get('/api/studentrecord/getall',
          queryParameters: {'schoolId': sid, 'limit': 300});
      if (res.data?['ok'] == true && res.data?['data'] != null) {
        studentRecords.value =
            List<Map<String, dynamic>>.from(res.data['data'] as List);
      }
    } catch (_) {}
  }

  Future<void> _fetchExpenses(String sid) async {
    try {
      final res = await _api.get('/api/expense/getall',
          queryParameters: {'schoolId': sid});
      if (res.data?['ok'] == true && res.data?['data'] != null) {
        expenseList.value =
            List<Map<String, dynamic>>.from(res.data['data'] as List);
      }
    } catch (_) {}
  }
}
