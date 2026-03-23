import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_app/controllers/student_record_controller.dart';
import 'package:school_app/controllers/attendance_controller.dart' as old_attendance;

class FeeCollectionScreen extends StatefulWidget {
  @override
  _FeeCollectionScreenState createState() => _FeeCollectionScreenState();
}

class _FeeCollectionScreenState extends State<FeeCollectionScreen> {
  final StudentRecordController controller = Get.put(StudentRecordController());
  final _formKey = GlobalKey<FormState>();
  
  final schoolIdController = TextEditingController(text: "6942923ab194c60dc810cc6b");
  final studentIdController = TextEditingController(text: "69450a91db9ab895d44128d3");
  final classIdController = TextEditingController(text: "6942a94da9deee103814fba0");
  final sectionIdController = TextEditingController(text: "6943a30b65f72f3b5201c7a7");
  final amountController = TextEditingController();
  final remarksController = TextEditingController();
  final referenceController = TextEditingController();
  final bankController = TextEditingController();
  final chequeDateController = TextEditingController();
  
  String paymentMode = 'cash';
  bool manualAllocation = false;
  bool isBusApplicable = false;
  Map<String, dynamic> paidHeads = {};
  List<Map<String, dynamic>> cashDenominations = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fee Collection')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: paymentMode,
                  decoration: InputDecoration(labelText: 'Payment Mode'),
                  items: ['cash', 'cheque'].map((mode) => 
                    DropdownMenuItem(value: mode, child: Text(mode.toUpperCase()))
                  ).toList(),
                  onChanged: (value) => setState(() => paymentMode = value!),
                ),
                SizedBox(height: 16),
                
                if (paymentMode == 'cheque') ...[
                  TextFormField(
                    controller: referenceController,
                    decoration: InputDecoration(labelText: 'Reference Number'),
                  ),
                  TextFormField(
                    controller: bankController,
                    decoration: InputDecoration(labelText: 'Bank Name'),
                  ),
                  TextFormField(
                    controller: chequeDateController,
                    decoration: InputDecoration(labelText: 'Cheque Date (YYYY-MM-DD)'),
                  ),
                ],
                
                if (paymentMode == 'cash') ...[
                  Text('Cash Denominations:'),
                  ElevatedButton(
                    onPressed: _addCashDenomination,
                    child: Text('Add Denomination'),
                  ),
                  ...cashDenominations.map((denom) => 
                    ListTile(
                      title: Text('₹${denom['label']} x ${denom['count']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => setState(() => cashDenominations.remove(denom)),
                      ),
                    )
                  ),
                ],
                
                SwitchListTile(
                  title: Text('Manual Allocation'),
                  value: manualAllocation,
                  onChanged: (value) => setState(() => manualAllocation = value),
                ),
                
                if (manualAllocation) ...[
                  Text('Paid Heads:'),
                  ElevatedButton(
                    onPressed: _addPaidHead,
                    child: Text('Add Fee Head'),
                  ),
                  ...paidHeads.entries.map((entry) => 
                    ListTile(
                      title: Text('${entry.key}: ₹${entry.value}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => setState(() => paidHeads.remove(entry.key)),
                      ),
                    )
                  ),
                ],
                
                SwitchListTile(
                  title: Text('Bus Applicable'),
                  value: isBusApplicable,
                  onChanged: (value) => setState(() => isBusApplicable = value),
                ),
                
                TextFormField(
                  controller: remarksController,
                  decoration: InputDecoration(labelText: 'Remarks'),
                ),
                SizedBox(height: 20),
                
                Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : _collectFee,
                  child: controller.isLoading.value 
                    ? CircularProgressIndicator() 
                    : Text('Collect Fee'),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addCashDenomination() {
    showDialog(
      context: context,
      builder: (context) {
        final labelController = TextEditingController();
        final countController = TextEditingController();
        return AlertDialog(
          title: Text('Add Cash Denomination'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(labelText: 'Denomination (e.g., 500)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: countController,
                decoration: InputDecoration(labelText: 'Count'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  cashDenominations.add({
                    'label': labelController.text,
                    'count': int.parse(countController.text),
                  });
                });
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addPaidHead() {
    showDialog(
      context: context,
      builder: (context) {
        final headController = TextEditingController();
        final amountController = TextEditingController();
        return AlertDialog(
          title: Text('Add Fee Head'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: headController,
                decoration: InputDecoration(labelText: 'Fee Head (e.g., firstTermAmt)'),
              ),
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  paidHeads[headController.text] = double.parse(amountController.text);
                });
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _collectFee() async {
    if (!_formKey.currentState!.validate()) return;
    
    await controller.collectFee(
      schoolId: schoolIdController.text,
      studentId: studentIdController.text,
      classId: classIdController.text,
      sectionId: sectionIdController.text,
      amount: double.parse(amountController.text),
      paymentMode: paymentMode,
      manualDueAllocation: manualAllocation,
      paidHeads: manualAllocation ? paidHeads : null,
      cashDenominations: paymentMode == 'cash' ? cashDenominations : null,
      referenceNumber: paymentMode == 'cheque' ? referenceController.text : null,
      bankName: paymentMode == 'cheque' ? bankController.text : null,
      chequeDate: paymentMode == 'cheque' ? chequeDateController.text : null,
      isBusApplicable: isBusApplicable,
      remarks: remarksController.text,
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final old_attendance.AttendanceController controller = Get.put(old_attendance.AttendanceController());
  
  final schoolIdController = TextEditingController(text: "6942923ab194c60dc810cc6b");
  final classIdController = TextEditingController(text: "6942a94da9deee103814fba0");
  final sectionIdController = TextEditingController(text: "6943a30b65f72f3b5201c7a7");
  final academicYearController = TextEditingController(text: "2025-2026");
  final dateController = TextEditingController(text: "2025-12-25");
  
  List<Map<String, dynamic>> attendanceRecords = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: dateController,
              decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _getAttendanceSheet,
                    child: Text('Get Attendance Sheet'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _markAttendance,
                    child: Text('Mark Attendance'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _getAttendanceHistory,
                child: Text('Get Attendance History'),
              ),
            ),
            SizedBox(height: 16),
            
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: controller.attendanceSheet.length,
                itemBuilder: (context, index) {
                  final student = controller.attendanceSheet[index];
                  return Card(
                    child: ListTile(
                      title: Text(student['studentName'] ?? 'Unknown'),
                      subtitle: Text('ID: ${student['studentId']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => _updateAttendance(index, 'present'),
                            child: Text('Present'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: student['status'] == 'present' ? Colors.green : null,
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateAttendance(index, 'absent'),
                            child: Text('Absent'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: student['status'] == 'absent' ? Colors.red : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _getAttendanceSheet() async {
    await controller.getAttendanceSheet(
      schoolId: schoolIdController.text,
      classId: classIdController.text,
      sectionId: sectionIdController.text,
      date: dateController.text,
      academicYear: academicYearController.text,
    );
  }

  void _updateAttendance(int index, String status) {
    setState(() {
      controller.attendanceSheet[index]['status'] = status;
    });
  }

  void _markAttendance() async {
    final records = controller.attendanceSheet.map((student) => {
      'studentId': student['studentId'],
      'studentName': student['studentName'],
      'status': student['status'] ?? 'absent',
      'remark': student['remark'] ?? '',
    }).toList();

    await controller.markAttendance(
      schoolId: schoolIdController.text,
      classId: classIdController.text,
      sectionId: sectionIdController.text,
      academicYear: academicYearController.text,
      date: dateController.text,
      records: records,
    );
  }

  void _getAttendanceHistory() async {
    await controller.getAttendanceHistory(
      schoolId: schoolIdController.text,
      classId: classIdController.text,
      sectionId: sectionIdController.text,
      academicYear: academicYearController.text,
      page: 1,
      limit: 10,
    );
  }
}

class StudentRecordScreen extends StatefulWidget {
  @override
  _StudentRecordScreenState createState() => _StudentRecordScreenState();
}

class _StudentRecordScreenState extends State<StudentRecordScreen> {
  final StudentRecordController controller = Get.put(StudentRecordController());
  
  final schoolIdController = TextEditingController(text: "6942923ab194c60dc810cc6b");
  final studentIdController = TextEditingController(text: "69450a91db9ab895d44128d3");
  
  Map<String, dynamic>? studentRecord;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Record')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _getStudentRecord,
              child: Text('Get Student Record'),
            ),
            SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _getDues,
              child: Text('Get Student Dues'),
            ),
            SizedBox(height: 16),
            
            if (studentRecord != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Academic Year: ${studentRecord!['academicYear']}'),
                      SizedBox(height: 8),
                      Text('Fee Structure: ${studentRecord!['feeStructure']}'),
                      SizedBox(height: 8),
                      Text('Fee Paid: ${studentRecord!['feePaid']}'),
                      SizedBox(height: 8),
                      Text('Dues: ${studentRecord!['dues']}'),
                      SizedBox(height: 8),
                      Text('Concession: ${studentRecord!['concession']}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _getStudentRecord() async {
    final result = await controller.getStudentRecord(
      schoolIdController.text,
      studentIdController.text,
    );
    setState(() {
      studentRecord = result;
    });
  }

  void _getDues() async {
    await controller.getDues(
      schoolId: schoolIdController.text,
      studentId: studentIdController.text,
      classId: "6942a94da9deee103814fba0",
      sectionId: "6943a30b65f72f3b5201c7a7",
    );
  }
}

class ApiTestHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('API Test Screens')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => Get.to(() => FeeCollectionScreen()),
              child: Text('Fee Collection Test'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.to(() => AttendanceScreen()),
              child: Text('Attendance Test'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.to(() => StudentRecordScreen()),
              child: Text('Student Record Test'),
            ),
          ],
        ),
      ),
    );
  }
}