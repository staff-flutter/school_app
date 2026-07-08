import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart' as dio;
import 'package:collection/collection.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/student_management_controller.dart';
import 'package:school_app/controllers/user_management_controller.dart';

/// -----------------------------------------------------------------------
/// Model
/// -----------------------------------------------------------------------
class ParentMember {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> studentIds;

  const ParentMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.studentIds,
  });

  factory ParentMember.fromJson(Map<String, dynamic> json) {
    // TODO: confirm the actual key your backend uses to store a parent's
    // linked children. AuthController/MyChildrenController already reads
    // `studentId` off the logged-in user, so that's the primary guess here.
    final rawIds = json['studentId'] ??
        json['studentIds'] ??
        json['children'] ??
        [];
    return ParentMember(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['userName'] ?? json['name'] ?? 'Unnamed').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? json['phoneNo'] ?? '')
          .toString(),
      studentIds: rawIds is List
          ? rawIds.map((e) => e.toString()).toList()
          : <String>[],
    );
  }
}

/// -----------------------------------------------------------------------
/// Parent Management Page (list + search + add)
/// -----------------------------------------------------------------------
class ParentManagementPage extends StatefulWidget {
  const ParentManagementPage({super.key});

  @override
  State<ParentManagementPage> createState() => _ParentManagementPageState();
}

class _ParentManagementPageState extends State<ParentManagementPage> {
  final ApiService _apiService = Get.find<ApiService>();
  final _auth = Get.find<AuthController>();
  final _school = Get.find<SchoolController>();
  final ScrollController _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<ParentMember> _parents = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _deletingId;

  int _currentPage = 1;
  final int _limit = 15;

  String? get _resolvedSchoolId {
    final role = _auth.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') return _school.selectedSchool.value?.id;
    return _auth.user.value?.schoolId;
  }

  @override
  void initState() {
    super.initState();
    _fetchInitial();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchInitial() async {
    setState(() {
      _currentPage = 1;
      _isLoading = true;
      _hasMore = true;
      _error = null;
      _parents.clear();
    });
    await _loadData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadData();
    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetchInitial);
  }

  Future<void> _loadData() async {
    final schoolId = _resolvedSchoolId;
    if (schoolId == null || schoolId.isEmpty) {
      setState(() => _error = 'School information missing. Please log in again.');
      return;
    }
    try {
      // Reuses the same "getUsersByRole/:role/:schoolId" pattern used by
      // StaffManagementPage, just pinned to the 'parent' role.
      final query = <String, dynamic>{
        'page': _currentPage,
        'limit': _limit,
      };
      if (_searchCtrl.text.trim().isNotEmpty) {
        query['search'] = _searchCtrl.text.trim();
      }

      final response = await _apiService.get(
        '${ApiConstants.getUsersByRole}/parent/$schoolId',
        queryParameters: query,
      );

      final raw = response.data;
      Map<String, dynamic> body;
      if (raw is Map) {
        body = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        final decoded = jsonDecode(raw);
        body = decoded is Map ? Map<String, dynamic>.from(decoded) : {};
      } else {
        body = {};
      }

      final List<dynamic> items =
          (body['data'] as List?) ?? (raw is List ? raw : []);
      final parsed = items
          .whereType<Map>()
          .map((e) => ParentMember.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        _parents.addAll(parsed);
        final totalCount = body['totalCount'] ?? body['total'] ?? 0;
        if (_parents.length >= totalCount) {
          _hasMore = false;
        }
      });
    } catch (e) {
      debugPrint('Error fetching parents: $e');
      if (mounted) setState(() => _error = 'Failed to load parent list');
    }
  }

  Future<void> _openAddParent() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => _AddParentDialog(schoolId: _resolvedSchoolId),
    );
    // Cancel button pops explicit `false`. Anything else (our own success
    // pop, or UserManagementController.createUser closing the dialog
    // itself) means the parent was actually created — refresh from the
    // server so role/studentId come back exactly as persisted, using the
    // same creation path already verified correct from the Users tab.
    if (result != false) {
      _fetchInitial();
    }
  }

  Future<void> _openManageStudents(ParentMember parent) async {
    final schoolId = _resolvedSchoolId;
    if (schoolId == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ManageParentStudentsPage(
          parent: parent,
          schoolId: schoolId,
        ),
      ),
    );
    if (changed == true) _fetchInitial();
  }

  Future<void> _deleteParent(ParentMember parent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Parent'),
        content: Text('Remove "${parent.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final schoolId = _resolvedSchoolId;
    setState(() => _deletingId = parent.id);
    try {
      // Same endpoint/header convention already confirmed working in
      // StaffManagementPage._deleteStaff.
      final resp = await _apiService.dio.delete(
        '${ApiConstants.deleteUser}/${parent.id}',
        options: dio.Options(headers: {'x-school-id': schoolId}),
      );
      final ok = resp.data is Map && resp.data['ok'] == true;
      if (ok) {
        setState(() {
          _parents.removeWhere((p) => p.id == parent.id);
          _deletingId = null;
        });
      } else {
        throw Exception('Delete failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deletingId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove parent: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Parent Management'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddParent,
        icon: const Icon(Icons.add),
        label: const Text('Add Parent'),
      ),
      body: Column(
        children: [
          _buildSearch(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchInitial,
              child: _isLoading
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator()),
                ],
              )
                  : _error != null && _parents.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 160),
                  Center(child: Text(_error!)),
                ],
              )
                  : _parents.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(
                      child: Text(
                          'No parents found. Tap "Add Parent" to create one.')),
                ],
              )
                  : ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: _parents.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _parents.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  return _buildParentCard(_parents[index], index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by name, email, or phone',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildParentCard(ParentMember parent, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openManageStudents(parent),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Text('${index + 1}',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parent.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(parent.email.isNotEmpty ? parent.email : parent.phone,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${parent.studentIds.length} STUDENT${parent.studentIds.length == 1 ? '' : 'S'}',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _deletingId == parent.id
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'manage') _openManageStudents(parent);
                  if (value == 'delete') _deleteParent(parent);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'manage', child: Text('Manage Students')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// "Register New Parent" dialog (matches the Full Name / Email / Phone /
/// Password modal in the reference screenshot).
/// -----------------------------------------------------------------------
class _AddParentDialog extends StatefulWidget {
  final String? schoolId;
  const _AddParentDialog({required this.schoolId});

  @override
  State<_AddParentDialog> createState() => _AddParentDialogState();
}

class _AddParentDialogState extends State<_AddParentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.schoolId == null || widget.schoolId!.isEmpty) {
      Get.snackbar('Error', 'School information missing.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Reuse the exact same creation path already proven correct from the
      // Users tab (SchoolManagementView._showCreateUserDialog calling
      // UserManagementController.createUser). That flow sets the role
      // correctly at creation time and leaves the new parent with no
      // students linked — both things a hand-rolled POST to
      // ApiConstants.createUser was getting subtly wrong (likely a field
      // name mismatch, e.g. 'phone' vs 'phoneNo').
      final userController = Get.isRegistered<UserManagementController>()
          ? Get.find<UserManagementController>()
          : Get.put(UserManagementController());
      final schoolController = Get.find<SchoolController>();

      if (schoolController.schools.isEmpty) {
        await schoolController.getAllSchools();
      }
      final schoolCode = schoolController.schools
          .firstWhereOrNull((s) => s.id == widget.schoolId)
          ?.schoolCode;

      await userController.createUser(
        email: _emailCtrl.text.trim(),
        userName: _nameCtrl.text.trim(),
        password: _passwordCtrl.text,
        phoneNo: _phoneCtrl.text.trim(),
        schoolId: widget.schoolId!,
        schoolCode: schoolCode,
        // IMPORTANT: must be lowercase 'parent' to exactly match
        // SchoolManagementView._showCreateUserDialog's validRoles list
        // (['correspondent','teacher','principal','viceprincipal',
        // 'administrator','accountant','parent']). Sending 'Parent'
        // (capitalized) is what was causing the backend to treat the
        // account as if it had no student filter at all and return every
        // student in the school instead of none.
        role: 'parent',
      );

      // Do NOT pop here. UserManagementController.createUser already
      // closes this dialog itself via Get.back() on success (same as it
      // does when called from the Users tab). Calling
      // Navigator.of(context).pop(true) again afterwards was a *second*
      // pop that landed on the actual ParentManagementPage route
      // underneath — that's exactly what showed up as a black screen.
    } catch (e) {
      String msg = 'Failed to create parent';
      if (e is dio.DioException && e.response?.data is Map) {
        msg = e.response?.data['message'] ?? msg;
      } else {
        msg = e.toString().replaceAll('Exception: ', '');
      }
      Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register New Parent'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Rahul Sharma',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'name@example.com',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    hintText: '10-digit mobile number',
                    border: OutlineInputBorder(),
                    isDense: true,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Password *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                          size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create Parent'),
        ),
      ],
    );
  }
}

/// -----------------------------------------------------------------------
/// "Manage Students for {parent}" page: search/filter students by class +
/// section, link/unlink against this parent, and show currently enrolled
/// (linked) students below — mirrors the reference screenshot.
/// -----------------------------------------------------------------------
class ManageParentStudentsPage extends StatefulWidget {
  final ParentMember parent;
  final String schoolId;

  const ManageParentStudentsPage({
    super.key,
    required this.parent,
    required this.schoolId,
  });

  @override
  State<ManageParentStudentsPage> createState() =>
      _ManageParentStudentsPageState();
}

class _ManageParentStudentsPageState
    extends State<ManageParentStudentsPage> {
  final ApiService _apiService = Get.find<ApiService>();
  final SchoolController _school = Get.find<SchoolController>();
  final StudentManagementController _studentCtrl =
  Get.find<StudentManagementController>();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  SchoolClass? _selectedClass;
  Section? _selectedSection;
  bool _loadingSections = false;

  List<Map<String, dynamic>> _candidates = [];
  bool _loadingCandidates = false;

  List<Map<String, dynamic>> _enrolled = [];
  bool _loadingEnrolled = false;

  late Set<String> _linkedIds;
  final Set<String> _pendingIds = {}; // ids currently being linked/unlinked
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _linkedIds = Set<String>.from(widget.parent.studentIds);
    _school.sections.clear();
    _loadEnrolled();
    _loadCandidates();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadCandidates);
  }

  /// Fetches the details of every student already linked to this parent.
  /// Mirrors the per-id loop MyChildrenController.loadChildrenByIds already
  /// uses elsewhere in the app.
  Future<void> _loadEnrolled() async {
    setState(() => _loadingEnrolled = true);
    final results = <Map<String, dynamic>>[];
    for (final id in _linkedIds) {
      try {
        final resp = await _apiService.get('/api/student/get/$id');
        if (resp.data is Map && resp.data['ok'] == true) {
          final data = Map<String, dynamic>.from(resp.data['data'] ?? {});
          data['_id'] = data['_id'] ?? id;
          results.add(data);
        }
      } catch (_) {
        // Ignore individual failures so one bad id doesn't break the list.
      }
    }
    if (mounted) {
      setState(() {
        _enrolled = results;
        _loadingEnrolled = false;
      });
    }
  }

  /// Fetches candidate students to link, filtered by class/section/search.
  Future<void> _loadCandidates() async {
    setState(() => _loadingCandidates = true);
    try {
      // TODO: confirm the real "list students" endpoint + query param names.
      // Guessed to follow the same schoolId/classId/sectionId/search
      // convention used by getAllSections and the club getall endpoint.
      final query = <String, dynamic>{'schoolId': widget.schoolId};
      if (_selectedClass != null) query['classId'] = _selectedClass!.id;
      if (_selectedSection != null) query['sectionId'] = _selectedSection!.id;
      if (_searchCtrl.text.trim().isNotEmpty) {
        query['search'] = _searchCtrl.text.trim();
      }

      final resp = await _apiService.get('/api/student/getall', queryParameters: query);
      if (resp.data is Map && resp.data['ok'] == true) {
        final list = List<Map<String, dynamic>>.from(
            (resp.data['data'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
        if (mounted) setState(() => _candidates = list);
      } else {
        if (mounted) setState(() => _candidates = []);
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (mounted) setState(() => _candidates = []);
    } finally {
      if (mounted) setState(() => _loadingCandidates = false);
    }
  }

  Future<void> _onClassChanged(SchoolClass? cls) async {
    setState(() {
      _selectedClass = cls;
      _selectedSection = null;
      _school.sections.clear();
      _loadingSections = cls != null;
    });
    if (cls != null) {
      await _school.getAllSections(classId: cls.id, schoolId: widget.schoolId);
    }
    if (mounted) setState(() => _loadingSections = false);
    _loadCandidates();
  }

  Future<void> _confirmAndToggleLink(
      String studentId,
      String studentName, {
        required bool link,
      }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(link ? 'Link Student' : 'Unlink Student'),
        content: Text(
          link
              ? 'Do you want to link "$studentName" to ${widget.parent.name}?'
              : 'Do you want to unlink "$studentName" from ${widget.parent.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: link ? Colors.green : Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(link ? 'Link' : 'Unlink',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _toggleLink(studentId, link: link);
  }

  Future<void> _toggleLink(String studentId, {required bool link}) async {
    setState(() => _pendingIds.add(studentId));
    try {
      final success = link
          ? await _studentCtrl.assignStudentToParent(widget.parent.id, studentId)
          : await _studentCtrl.removeStudentFromParent(widget.parent.id, studentId);

      if (success) {
        setState(() {
          _hasChanges = true;
          if (link) {
            _linkedIds.add(studentId);
          } else {
            _linkedIds.remove(studentId);
            _enrolled.removeWhere((s) => s['_id'] == studentId);
          }
        });
        if (link) await _loadEnrolled();
      } else {
        Get.snackbar('Error', link ? 'Failed to link student' : 'Failed to unlink student',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _pendingIds.remove(studentId));
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_hasChanges);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text('Manage Students for ${widget.parent.name}'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FIND STUDENT TO LINK',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<SchoolClass>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      value: _school.classes.contains(_selectedClass) ? _selectedClass : null,
                      items: _school.classes
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                          .toList(),
                      onChanged: _onClassChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _loadingSections
                        ? const Center(
                        child: SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : DropdownButtonFormField<Section>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Section',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        hintText: _selectedClass == null ? 'Select class first' : null,
                      ),
                      value: _school.sections.contains(_selectedSection)
                          ? _selectedSection
                          : null,
                      items: _school.sections
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                          .toList(),
                      onChanged: _selectedClass == null
                          ? null
                          : (s) {
                        setState(() => _selectedSection = s);
                        _loadCandidates();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by Name or ID...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 3,
                child: _loadingCandidates
                    ? const Center(child: CircularProgressIndicator())
                    : _candidates.isEmpty
                    ? const Center(child: Text('No students found'))
                    : ListView.builder(
                  itemCount: _candidates.length,
                  itemBuilder: (context, index) {
                    final student = _candidates[index];
                    final id = (student['_id'] ?? '').toString();
                    final name = (student['name'] ?? student['studentName'] ?? 'Unknown').toString();
                    final isLinked = _linkedIds.contains(id);
                    final isPending = _pendingIds.contains(id);
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_outline),
                      title: Text(name),
                      subtitle: Text(id, style: const TextStyle(fontSize: 11)),
                      trailing: isPending
                          ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : isLinked
                          ? const Chip(
                        label: Text('Linked', style: TextStyle(fontSize: 12)),
                        backgroundColor: Color(0xFFDFF5E1),
                      )
                          : ElevatedButton(
                        onPressed: () =>
                            _confirmAndToggleLink(id, name, link: true),
                        child: const Text('Link'),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 18),
                  const SizedBox(width: 6),
                  Text('Enrolled Students (${_enrolled.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: _loadingEnrolled
                    ? const Center(child: CircularProgressIndicator())
                    : _enrolled.isEmpty
                    ? const Center(
                    child: Text('No students linked yet', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  itemCount: _enrolled.length,
                  itemBuilder: (context, index) {
                    final student = _enrolled[index];
                    final id = (student['_id'] ?? '').toString();
                    final name =
                    (student['name'] ?? student['studentName'] ?? 'Unknown').toString();
                    final className = (student['className'] ??
                        student['nonMandatory']?['className'] ??
                        'N/A')
                        .toString();
                    final section = (student['sectionName'] ??
                        student['nonMandatory']?['sectionName'] ??
                        'N/A')
                        .toString();
                    final isPending = _pendingIds.contains(id);
                    return ListTile(
                      dense: true,
                      leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
                      title: Text(name),
                      subtitle: Text('CLASS: $className   SEC: $section\nID: $id',
                          style: const TextStyle(fontSize: 11)),
                      isThreeLine: true,
                      trailing: isPending
                          ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                        icon: const Icon(Icons.link_off, color: Colors.red),
                        tooltip: 'Unlink',
                        onPressed: () =>
                            _confirmAndToggleLink(id, name, link: false),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}