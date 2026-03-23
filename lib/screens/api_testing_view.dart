import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/student_management_controller.dart';
import 'package:school_app/controllers/finance_ledger_controller.dart';
import 'package:school_app/controllers/system_management_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/auth_controller.dart';

class ApiTestingView extends StatefulWidget {
  const ApiTestingView({Key? key}) : super(key: key);

  @override
  State<ApiTestingView> createState() => _ApiTestingViewState();
}

class _ApiTestingViewState extends State<ApiTestingView> with TickerProviderStateMixin {
  late TabController _tabController;
  final studentController = Get.put(StudentManagementController());
  final financeController = Get.put(FinanceLedgerController());
  final systemController = Get.put(SystemManagementController());
  final authController = Get.find<AuthController>();

  String lastRequest = '';
  String lastResponse = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Testing'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Student APIs'),
            Tab(text: 'Finance APIs'),
            Tab(text: 'System APIs'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentAPIs(),
                _buildFinanceAPIs(),
                _buildSystemAPIs(),
              ],
            ),
          ),
          _buildResponseSection(),
        ],
      ),
    );
  }

  Widget _buildStudentAPIs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Student Management Note',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Student-to-class assignment is already available in the existing School Management → Students tab. The APIs below are for parent assignment and attendance viewing.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Get.toNamed('/school-management', arguments: {'initialTab': 3}),
                    child: const Text('Go to School Management → Students'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildApiCard(
            'Assign Student to Parent',
            'PUT /api/student/assignstudent',
            '{"parentId": "parent123", "studentId": "student456"}',
            () => _testAssignParent(),
          ),
          _buildApiCard(
            'Remove Student from Parent',
            'PUT /api/student/removestudent',
            '{"parentId": "parent123", "studentId": "student456"}',
            () => _testRemoveParent(),
          ),
          _buildApiCard(
            'Get Student Attendance',
            'GET /api/attendance/student/:studentId',
            'Query: month=12, year=2024',
            () => _testGetAttendance(),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceAPIs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildApiCard(
            'Get Finance Stats',
            'GET /api/financeledger/stats',
            'Query: schoolId=school123, range=today',
            () => _testFinanceStats(),
          ),
          _buildApiCard(
            'Get Timeline Data',
            'GET /api/financeledger/timeline',
            'Query: schoolId=school123, range=month',
            () => _testTimelineData(),
          ),
          _buildApiCard(
            'Get All Transactions',
            'GET /api/financeledger/getall',
            'Query: schoolId=school123, page=1, limit=20',
            () => _testGetTransactions(),
          ),
          _buildApiCard(
            'Get Single Transaction',
            'GET /api/financeledger/get/:id',
            'Path: id=transaction123',
            () => _testGetTransaction(),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemAPIs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildApiCard(
            'Get All Archived Items',
            'GET /api/deletearchive/getall',
            'Query: schoolId=school123, page=1, limit=20',
            () => _testGetArchivedItems(),
          ),
          _buildApiCard(
            'Get Archived Item',
            'GET /api/deletearchive/get/:id',
            'Path: id=archive123',
            () => _testGetArchivedItem(),
          ),
          _buildApiCard(
            'Delete Archived Item',
            'DELETE /api/deletearchive/delete/:id',
            'Path: id=archive123',
            () => _testDeleteArchivedItem(),
          ),
          _buildApiCard(
            'Get All Audit Logs',
            'GET /api/audit/getall',
            'Query: schoolId=school123, page=1, limit=20',
            () => _testGetAuditLogs(),
          ),
          _buildApiCard(
            'Get Audit Log',
            'GET /api/audit/get/:id',
            'Path: id=audit123',
            () => _testGetAuditLog(),
          ),
        ],
      ),
    );
  }

  Widget _buildApiCard(String title, String endpoint, String payload, VoidCallback onTest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              endpoint,
              style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payload,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onTest,
              child: const Text('Test API'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 20),
                const SizedBox(width: 8),
                const Text('API Response', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    lastRequest = '';
                    lastResponse = '';
                  }),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lastRequest.isNotEmpty) ...[
                    const Text('Request:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Text(lastRequest, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                    const SizedBox(height: 12),
                  ],
                  if (lastResponse.isNotEmpty) ...[
                    const Text('Response:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 4),
                    Text(lastResponse, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  ],
                  if (lastRequest.isEmpty && lastResponse.isEmpty)
                    const Text('Click "Test API" on any endpoint above to see request/response data'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _testAssignParent() async {
    final request = '{"parentId": "parent123", "studentId": "student456"}';
    setState(() {
      lastRequest = 'PUT /api/student/assignstudent\\n$request';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await studentController.assignStudentToParent('parent123', 'student456');
      setState(() {
        lastResponse = '{"success": $result, "message": "Student assignment ${result ? 'successful' : 'failed'}"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testRemoveParent() async {
    final request = '{"parentId": "parent123", "studentId": "student456"}';
    setState(() {
      lastRequest = 'PUT /api/student/removestudent\\n$request';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await studentController.removeStudentFromParent('parent123', 'student456');
      setState(() {
        lastResponse = '{"success": $result, "message": "Student removal ${result ? 'successful' : 'failed'}"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testGetAttendance() async {
    setState(() {
      lastRequest = 'GET /api/attendance/student/student456?month=12&year=2024';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await studentController.getStudentAttendance('student456', month: 12, year: 2024);
      setState(() {
        lastResponse = result?.toString() ?? '{"error": "No data returned"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testAssignClass() async {
    final data = {
      'schoolId': authController.user.value?.schoolId ?? 'school123',
      'studentId': 'student456',
      'classId': 'class789',
      'sectionId': 'section101',
      'academicYear': '2024-2025',
      'rollNumber': '15',
      'sectionName': 'A',
      'className': '10',
      'studentName': 'John Doe',
      'isBusApplicable': true,
      'newOld': 'new',
    };
    
    setState(() {
      lastRequest = 'PUT /api/studentrecord/assign\\n${data.toString()}';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await studentController.assignStudentToClass(data);
      setState(() {
        lastResponse = '{"success": $result, "message": "Class assignment ${result ? 'successful' : 'failed'}"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testRemoveClass() async {
    final schoolId = authController.user.value?.schoolId ?? 'school123';
    setState(() {
      lastRequest = 'PUT /api/studentrecord/remove\\n{"schoolId": "$schoolId", "studentId": "student456", "academicYear": "2024-2025"}';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await studentController.removeStudentFromClass(schoolId, 'student456', '2024-2025');
      setState(() {
        lastResponse = '{"success": $result, "message": "Class removal ${result ? 'successful' : 'failed'}"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testFinanceStats() async {
    final schoolId = authController.user.value?.schoolId ?? 'school123';
    setState(() {
      lastRequest = 'GET /api/financeledger/stats?schoolId=$schoolId&range=today';
      lastResponse = 'Testing...';
    });
    
    try {
      await financeController.getFinanceStats(schoolId: schoolId, range: 'today');
      setState(() {
        lastResponse = financeController.stats.value?.toString() ?? '{"message": "No stats data"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testTimelineData() async {
    final schoolId = authController.user.value?.schoolId ?? 'school123';
    setState(() {
      lastRequest = 'GET /api/financeledger/timeline?schoolId=$schoolId&range=month';
      lastResponse = 'Testing...';
    });
    
    try {
      await financeController.getTimelineData(schoolId: schoolId, range: 'month');
      setState(() {
        lastResponse = financeController.timelineData.toString();
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testGetTransactions() async {
    final schoolId = authController.user.value?.schoolId ?? 'school123';
    setState(() {
      lastRequest = 'GET /api/financeledger/getall?schoolId=$schoolId&page=1&limit=20';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await financeController.getAllTransactions(schoolId: schoolId);
      setState(() {
        lastResponse = result?.toString() ?? '{"message": "No transactions data"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testGetTransaction() async {
    setState(() {
      lastRequest = 'GET /api/financeledger/get/transaction123';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await financeController.getTransaction('transaction123');
      setState(() {
        lastResponse = result?.toString() ?? '{"message": "No transaction data"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testGetArchivedItems() async {
    final schoolId = authController.user.value?.schoolId ?? 'school123';
    setState(() {
      lastRequest = 'GET /api/deletearchive/getall?schoolId=$schoolId&page=1&limit=20';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await systemController.getAllArchivedItems(schoolId: schoolId);
      setState(() {
        lastResponse = result?.toString() ?? '{"message": "No archived items"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testGetArchivedItem() async {
    setState(() {
      lastRequest = 'GET /api/deletearchive/get/archive123';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await systemController.getArchivedItem('archive123');
      setState(() {
        lastResponse = result?.toString() ?? '{"message": "No archived item data"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testDeleteArchivedItem() async {
    setState(() {
      lastRequest = 'DELETE /api/deletearchive/delete/archive123';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await systemController.permanentlyDeleteItem('archive123');
      setState(() {
        lastResponse = '{"success": $result, "message": "Permanent deletion ${result ? 'successful' : 'failed'}"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testGetAuditLogs() async {
    final schoolId = authController.user.value?.schoolId ?? 'school123';
    setState(() {
      lastRequest = 'GET /api/audit/getall?schoolId=$schoolId&page=1&limit=20';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await systemController.getAllAuditLogs(schoolId: schoolId);
      setState(() {
        lastResponse = result?.toString() ?? '{"message": "No audit logs"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }

  void _testGetAuditLog() async {
    setState(() {
      lastRequest = 'GET /api/audit/get/audit123';
      lastResponse = 'Testing...';
    });
    
    try {
      final result = await systemController.getAuditLog('audit123');
      setState(() {
        lastResponse = result?.toString() ?? '{"message": "No audit log data"}';
      });
    } catch (e) {
      setState(() {
        lastResponse = '{"error": "$e"}';
      });
    }
  }
}