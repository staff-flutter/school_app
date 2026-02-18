import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/system_management_controller.dart';
import '../core/theme/app_theme.dart';
import '../modules/auth/controllers/auth_controller.dart';

class SystemManagementView extends StatefulWidget {
  SystemManagementView({Key? key}) : super(key: key);

  @override
  State<SystemManagementView> createState() => _SystemManagementViewState();
}

class _SystemManagementViewState extends State<SystemManagementView> with TickerProviderStateMixin {
  final controller = Get.put(SystemManagementController());
  final authController = Get.find<AuthController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final schoolId = authController.user.value?.schoolId;
    if (schoolId != null) {
      controller.getAllArchivedItems(schoolId: schoolId);
      controller.getAllAuditLogs(schoolId: schoolId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Delete Archive'),
            Tab(text: 'Audit Logs'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDeleteArchiveTab(),
            _buildAuditLogsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteArchiveTab() {
    if (!_hasPermission(['correspondent', 'accountant', 'principal', 'viceprincipal'])) {
      return _buildNoPermissionWidget('delete archive');
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Deleted Items Archive',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.archivedItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No archived items',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.archivedItems.length,
                itemBuilder: (context, index) {
                  final item = controller.archivedItems[index];
                  return _buildArchivedItemCard(item);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAuditLogsTab() {
    if (!_hasPermission(['administrator', 'correspondent', 'principal', 'viceprincipal'])) {
      return _buildNoPermissionWidget('audit logs');
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'System Audit Logs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.auditLogs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No audit logs found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.auditLogs.length,
                itemBuilder: (context, index) {
                  final log = controller.auditLogs[index];
                  return _buildAuditLogCard(log);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildArchivedItemCard(Map<String, dynamic> item) {
    final category = item['category']?.toString() ?? 'Unknown Category';
    final deletedAt = _formatDate(item['deletedAt']);
    final deletedBy = item['deletedBy']['userName']?.toString() ?? 'Unknown';
    final originalData = item['deletedData'] as Map<String, dynamic>? ?? {};
    
    // Extract meaningful info based on category
    String itemTitle = category;
    String itemSubtitle = 'Deleted on $deletedAt';
    
    if (category.toLowerCase().contains('student')) {
      final className = originalData['className']?.toString() ?? '';
      final rollNumber = originalData['rollNumber']?.toString() ?? '';
      final sectionName = originalData['sectionName']?.toString() ?? '';
      final studentId = originalData['studentId']?.toString();
      
      String studentName = 'Student Record';
      if (studentId != null) {
        studentName = controller.getStudentName(studentId);
        if (studentName == 'Unknown Student' && rollNumber.isNotEmpty) {
          studentName = 'Student Roll No: $rollNumber';
        }
      } else if (rollNumber.isNotEmpty) {
        studentName = 'Student Roll No: $rollNumber';
      }
      
      itemTitle = studentName;
      if (className.isNotEmpty) {
        itemSubtitle = 'Class $className${sectionName.isNotEmpty ? '-$sectionName' : ''} • $deletedAt';
      } else {
        itemSubtitle = 'Student Fee Record • $deletedAt';
      }
    } else if (category.toLowerCase().contains('expense')) {
      final amount = originalData['amount'] ?? 0;
      final expenseCategory = originalData['category']?.toString() ?? 'General';
      itemTitle = 'Expense: ₹${_formatAmount(amount)}';
      itemSubtitle = '$expenseCategory • $deletedAt';
    }
    
    return _buildItemCard(item, category, itemTitle, itemSubtitle, deletedBy);
  }

  Widget _buildItemCard(Map<String, dynamic> item, String category, String itemTitle, String itemSubtitle, String deletedBy) {
    return Card(
      color: AppTheme.chemistryYellow.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getCategoryIcon(category), color: Colors.red, size: 20),
        ),
        title: Text(
          itemTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(itemSubtitle),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _confirmPermanentDelete(item);
            } else if (value == 'details') {
              _showItemDetails(item);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'details', child: Text('View Details')),
            if (_hasPermission(['correspondent']))
              const PopupMenuItem(
                value: 'delete',
                child: Text('Permanently Delete', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Category', category),
                _buildInfoRow('Deleted By', deletedBy),
                _buildInfoRow('Deleted On', _formatDate(item['deletedAt'])),
                if (item['reason']?.toString().isNotEmpty == true) _buildInfoRow('Reason', item['reason'].toString()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showItemDetails(item),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_hasPermission(['correspondent']))
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmPermanentDelete(item),
                          icon: const Icon(Icons.delete_forever, size: 16),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('student')) return Icons.person;
    if (cat.contains('expense')) return Icons.money_off;
    if (cat.contains('fee')) return Icons.payment;
    if (cat.contains('user')) return Icons.account_circle;
    return Icons.delete;
  }

  Widget _buildAuditLogCard(Map<String, dynamic> log) {
    final actionColor = _getActionColor(log['action']);
    final action = log['action']?.toString().toUpperCase() ?? 'UNKNOWN';
    final module = log['module'] ?? 'Unknown Module';
    final userName = log['userName'] ?? 'Unknown User';
    final role = log['role'] ?? 'Unknown Role';
    final timestamp = _formatDate(log['createdAt']);
    final description = log['description'] ?? 'No description available';
    
    // Clean up description to be more user-friendly
    String cleanDescription = description;
    if (description.contains('(') && description.contains(')')) {
      // Remove technical IDs in parentheses
      cleanDescription = description.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    }
    
    return Card(
      color: actionColor.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAuditLogDetails(log),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getActionIcon(log['action']), color: actionColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$action in ${module.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cleanDescription,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$userName ($role)',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            timestamp,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPermissionWidget(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Access Denied',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have permission to access $feature',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(Map<String, dynamic> item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Permanent Delete'),
        content: const Text(
          'This action cannot be undone. The item will be permanently deleted from the system.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await controller.permanentlyDeleteItem(item['_id']);
              if (success) {
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    final category = item['category']?.toString() ?? 'Unknown';
    final originalData = item['deletedData'] as Map<String, dynamic>? ?? {};
    
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(_getCategoryIcon(category), color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text('$category Details')),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Category', category),
                        _buildDetailRow('Deleted At', _formatDate(item['deletedAt'])),
                        _buildDetailRow('Deleted By', item['deletedBy']['userName']?.toString() ?? 'Unknown'),
                        _buildDetailRow('Role', item['deletedBy']['role']?.toString() ?? 'Unknown'),
                        if (item['reason']?.toString().isNotEmpty == true) 
                          _buildDetailRow('Reason', item['reason'].toString()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Original Item Details:', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ...(_buildUserFriendlyDetails(category, originalData)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          if (_hasPermission(['correspondent']))
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(Get.context!);
                _confirmPermanentDelete(item);
              },
              icon: const Icon(Icons.delete_forever, size: 16),
              label: const Text('Delete Forever'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildUserFriendlyDetails(String category, Map<String, dynamic> data) {
    final widgets = <Widget>[];
    
    if (category.toLowerCase().contains('student')) {
      
      // Get student name from studentId
      final studentId = data['studentId']?.toString();
      if (studentId != null) {
        final studentName = controller.getStudentNameById(studentId);
        widgets.add(_buildDetailRow('Student Name', studentName));
      }
      if (data['className'] != null) widgets.add(_buildDetailRow('Class', data['className'].toString()));
      if (data['sectionName'] != null) widgets.add(_buildDetailRow('Section', data['sectionName'].toString()));
      if (data['rollNumber'] != null) widgets.add(_buildDetailRow('Roll Number', data['rollNumber'].toString()));
      if (data['academicYear'] != null) widgets.add(_buildDetailRow('Academic Year', data['academicYear'].toString()));
    } else if (category.toLowerCase().contains('expense')) {
      
      if (data['amount'] != null) widgets.add(_buildDetailRow('Amount', '₹${data['amount']}'));
      if (data['category'] != null) widgets.add(_buildDetailRow('Category', data['category'].toString()));
      if (data['remarks'] != null) widgets.add(_buildDetailRow('Remarks', data['remarks'].toString()));
      if (data['paymentMode'] != null) widgets.add(_buildDetailRow('Payment Mode', data['paymentMode'].toString()));
      if (data['expenseNo'] != null) widgets.add(_buildDetailRow('Expense No', data['expenseNo'].toString()));
    } else if (category.toLowerCase().contains('class')) {
      
      // Get class teacher names from classTeacherId array
      if (data['name'] != null) widgets.add(_buildDetailRow('Class Name', data['name'].toString()));
      if (data['order'] != null) widgets.add(_buildDetailRow('Order', data['order'].toString()));
      if (data['hasSections'] != null) widgets.add(_buildDetailRow('Has Sections', data['hasSections'].toString()));
      
      final classTeacherIds = data['classTeacherId'];
      if (classTeacherIds != null && classTeacherIds is List && classTeacherIds.isNotEmpty) {
        final teacherNames = controller.getTeacherNames(classTeacherIds.cast<String>());
        widgets.add(_buildDetailRow('Class Teachers', teacherNames));
      }
    } else {
      // For other categories, show key-value pairs but filter out technical fields
      data.forEach((key, value) {
        if (!_isTechnicalField(key) && value != null) {
          widgets.add(_buildDetailRow(_formatFieldName(key), value.toString()));
        }
      });
      
    }
    
    return widgets;
  }

  bool _isTechnicalField(String key) {
    const technicalFields = ['_id', '__v', 'createdAt', 'updatedAt', 'schoolId', 'studentId', 'classId', 'sectionId'];
    return technicalFields.contains(key);
  }

  String _formatFieldName(String key) {
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}').trim();
  }

  void _showAuditLogDetails(Map<String, dynamic> log) {
    Get.dialog(
      AlertDialog(
        title: Text('Audit Log Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Action', log['action']),
              _buildDetailRow('Module', log['module']),
              _buildDetailRow('User', log['userName']),
              _buildDetailRow('Role', log['role']),
              _buildDetailRow('Timestamp', _formatDate(log['timestamp'])),
              if (log['details'] != null) _buildDetailRow('Details', log['details']),
              if (log['ipAddress'] != null) _buildDetailRow('IP Address', log['ipAddress']),
              if (log['userAgent'] != null) _buildDetailRow('User Agent', log['userAgent']),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is String ? double.tryParse(amount) ?? 0 : amount;
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String? action) {
    switch (action?.toLowerCase()) {
      case 'create':
      case 'add':
        return Colors.green;
      case 'update':
      case 'edit':
        return Colors.blue;
      case 'delete':
      case 'remove':
        return Colors.red;
      case 'login':
        return Colors.purple;
      case 'logout':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String? action) {
    switch (action?.toLowerCase()) {
      case 'create':
      case 'add':
        return Icons.add;
      case 'update':
      case 'edit':
        return Icons.edit;
      case 'delete':
      case 'remove':
        return Icons.delete;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'view':
        return Icons.visibility;
      default:
        return Icons.info;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date.toString();
    }
  }

  bool _hasPermission(List<String> allowedRoles) {
    final userRole = authController.user.value?.role.toLowerCase();
    return userRole != null && allowedRoles.map((r) => r.toLowerCase()).contains(userRole);
  }
}