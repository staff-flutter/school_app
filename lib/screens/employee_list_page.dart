import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart' as dio;
import 'package:school_app/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/school_controller.dart';
import 'create_employee_profile_page.dart';
import 'employee_detail_page.dart';

class StaffMember {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['userName'] ?? 'Unnamed').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
      role: (json['role'] ?? 'N/A').toString(),
      isActive: json['isActive'] ?? true,
    );
  }
}

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final ApiService _apiService = Get.find<ApiService>();
  final _auth = Get.find<AuthController>();
  final _school = Get.find<SchoolController>();
  final ScrollController _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<StaffMember> _staff = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _deletingId;

  int _currentPage = 1;
  final int _limit = 15;

  // TODO: confirm these role values against your backend's actual role enum.
  static const List<String> _roleOptions = [
    'All',
    'Teacher',
    'Principal',
    'VicePrincipal',
    'Accountant',
    'Administrator',
    'Correspondent',
  ];
  String _selectedRole = 'All';

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
      _staff.clear();
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
    final pathRole = _selectedRole == 'All' ? 'all' : _selectedRole.toLowerCase();
    try {
      // ApiConstants.getUsersByRole = '/api/user'
      // TODO: confirm the exact query param names your backend expects here
      // (schoolId / role / search / page / limit are reasonable guesses
      // based on the pattern used by every other getall endpoint in this app).
      final query = <String, dynamic>{
        //'schoolId': schoolId,
        'page': _currentPage,
        'limit': _limit,
      };

      if (_searchCtrl.text.trim().isNotEmpty) query['search'] = _searchCtrl.text.trim();
      if (_selectedRole != 'All') query['role'] = _selectedRole;

      final response = await _apiService.get('${ApiConstants.getUsersByRole}/$pathRole/$schoolId', queryParameters: query);

      final raw = response.data;
      print('response:$raw');
      Map<String, dynamic> body;
      if (raw is Map) {
        body = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        final decoded = jsonDecode(raw);
        body = decoded is Map ? Map<String, dynamic>.from(decoded) : {};
      } else {
        body = {};
      }

      final List<dynamic> items = (body['data'] as List?) ?? (raw is List ? raw : []);
      final parsed = items
          .whereType<Map>()
          .map((e) => StaffMember.fromJson(Map<String, dynamic>.from(e)))
          .where((member) => !(_selectedRole == 'All' && member.role.toLowerCase() == 'parent'))
          .toList();

      setState(() {
        _staff.addAll(parsed);

        // If your backend provides a totalCount field:
        final totalCount = body['totalCount'] ?? body['total'] ?? 0;
        if (_staff.length >= totalCount) {
          _hasMore = false;
        }
      });
    } catch (e) {
      debugPrint('Error fetching staff: $e');
      if (mounted) {
        setState(() => _error = 'Failed to load staff list');
      }
    }
  }

  Future<void> _openAddStaff() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateEmployeeProfilePage(userId: null, isEdit: false),
      ),
    );
    if (saved == true) _fetchInitial();
  }

  Future<void> _openDetail(StaffMember member) async {
    if (member.id.isEmpty) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EmployeeDetailPage(userId: member.id)),
    );
    if (changed == true) _fetchInitial();
  }

  Future<void> _deleteStaff(StaffMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Staff'),
        content: Text('Remove "${member.name}"? This cannot be undone.'),
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
    setState(() => _deletingId = member.id);
    try {
      // ApiConstants.deleteUser = '/api/user/delete'
      // TODO: confirm whether userId is a path segment or a query/body param.
      final resp = await _apiService.dio.delete(
        '${ApiConstants.deleteUser}/${member.id}',
        options: dio.Options(headers: {'x-school-id': schoolId}),
      );
      final ok = resp.data is Map && resp.data['ok'] == true;
      if (ok) {
        setState(() {
          _staff.removeWhere((s) => s.id == member.id);
          _deletingId = null;
        });
      } else {
        throw Exception('Delete failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deletingId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove staff: $e')),
        );
      }
    }
  }

  Future<void> _assignRole(StaffMember member) async {
    String? newRole = member.role;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign Role — ${member.name}'),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => DropdownButtonFormField<String>(
            value: _roleOptions.contains(newRole) ? newRole : null,
            items: _roleOptions
                .where((r) => r != 'All')
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setDialogState(() => newRole = v),
            decoration: const InputDecoration(labelText: 'Role'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, newRole), child: const Text('Save')),
        ],
      ),
    );
    if (result == null || result == member.role) return;

    final schoolId = _resolvedSchoolId;
    try {
      // ApiConstants.assignRole = '/api/user/assignrole'
      // TODO: confirm body shape — guessed { userId, role }.
      final resp = await _apiService.dio.put(
        ApiConstants.assignRole,
        data: {'userId': member.id, 'role': result},
        options: dio.Options(headers: {'x-school-id': schoolId}),
      );
      final ok = resp.data is Map && resp.data['ok'] == true;
      if (ok) {
        _fetchInitial();
      } else {
        throw Exception('Assign role failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign role: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Staff Management'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddStaff,
        icon: const Icon(Icons.add),
        label: const Text('Add Staff'),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _staff.isEmpty
                ? Center(child: Text(_error!))
                : _staff.isEmpty
                ? const Center(child: Text('No staff found. Tap "Add Staff" to create one.'))
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: _staff.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _staff.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                return _buildStaffCard(_staff[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          TextField(
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    items: _roleOptions
                        .map((r) => DropdownMenuItem(value: r, child: Text('Role: $r', style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _selectedRole = v!);
                      _fetchInitial();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(StaffMember member, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openDetail(member),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Text('${index + 1}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(member.email.isNotEmpty ? member.email : member.phone,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(member.role.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ),
                  ],
                ),
              ),
              _deletingId == member.id
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') _openDetail(member);
                  if (value == 'role') _assignRole(member);
                  if (value == 'delete') _deleteStaff(member);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'view', child: Text('View')),
                  PopupMenuItem(value: 'role', child: Text('Assign Role')),
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