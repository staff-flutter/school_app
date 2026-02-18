import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_record_controller.dart';
import '../controllers/attendance_controller.dart' as old_attendance;

class ApiTestExamples {
  final StudentRecordController _studentRecordController = Get.find<StudentRecordController>();
  final old_attendance.AttendanceController _attendanceController = Get.find<old_attendance.AttendanceController>();

  // Test data
  final String schoolId = "6942923ab194c60dc810cc6b";
  final String studentId = "69450a91db9ab895d44128d3";
  final String classId = "6942a94da9deee103814fba0";
  final String sectionId = "6943a30b65f72f3b5201c7a7";

  // ==================== STUDENT RECORD API TESTS ====================

  // 1. Apply Concession Test
  Future<void> testApplyConcession() async {

    // Create a dummy proof file (you need to provide actual file)
    final File proofFile = File('path/to/proof/document.pdf');
    
    final result = await _studentRecordController.applyConcession(
      schoolId: schoolId,
      studentId: studentId,
      studentName: "Test Student",
      classId: classId,
      sectionId: sectionId,
      concessionType: "percentage", // or "amount"
      concessionValue: 10.0, // 10% or ₹10
      remark: "Financial hardship concession",
      proofFile: proofFile,
      newOld: "new",
      isBusApplicable: true,
      busPoint: "Main Gate",
    );

  }

  // 2. Collect Fee Test - Cash Payment with Manual Allocation
  Future<void> testCollectFeeCashManual() async {

    final result = await _studentRecordController.collectFee(
      schoolId: schoolId,
      studentId: studentId,
      classId: classId,
      sectionId: sectionId,
      amount: 5000.0,
      paymentMode: "cash",
      manualDueAllocation: true,
      paidHeads: {
        "firstTermAmt": 5000
      },
      cashDenominations: [
        {"label": "500", "count": 10}
      ],
      remarks: "First term fee payment",
      isBusApplicable: true,
    );

  }

  // 3. Collect Fee Test - Cheque Payment with Auto Allocation
  Future<void> testCollectFeeChequeAuto() async {

    final result = await _studentRecordController.collectFee(
      schoolId: schoolId,
      studentId: studentId,
      classId: classId,
      sectionId: sectionId,
      amount: 20000.0,
      paymentMode: "cheque",
      manualDueAllocation: false, // Auto allocation
      referenceNumber: "CHQ-123456",
      bankName: "SBI",
      chequeDate: "2025-12-25",
      remarks: "Full term fee via cheque",
    );

  }

  // 4. Get Student Record Test
  Future<void> testGetStudentRecord() async {

    final result = await _studentRecordController.getStudentRecord(schoolId, studentId);
    
    if (result != null) {

    } else {
      
    }
  }

  // 5. Get Dues Test
  Future<void> testGetDues() async {

    final result = await _studentRecordController.getDues(
      schoolId: schoolId,
      studentId: studentId,
      classId: classId,
      sectionId: sectionId,
    );
    
    if (result != null) {

    } else {
      
    }
  }

  // ==================== ATTENDANCE API TESTS ====================

  // 6. Get Attendance Sheet Test
  Future<void> testGetAttendanceSheet() async {

    final result = await _attendanceController.getAttendanceSheet(
      schoolId: schoolId,
      classId: classId,
      sectionId: sectionId,
      date: "2025-12-25",
      academicYear: "2025-2026",
    );
    
    if (result != null) {

      for (var student in result) {
        
      }
    } else {
      
    }
  }

  // 7. Mark Attendance Test
  Future<void> testMarkAttendance() async {

    final attendanceRecords = [
      {
        "studentId": studentId,
        "studentName": "Lakshaya",
        "status": "present",
        "remark": ""
      }
    ];
    
    final result = await _attendanceController.markAttendance(
      schoolId: schoolId,
      classId: classId,
      sectionId: sectionId,
      academicYear: "2025-2026",
      date: "2025-12-25",
      records: attendanceRecords,
    );

  }

  // 8. Get Attendance History Test
  Future<void> testGetAttendanceHistory() async {

    final result = await _attendanceController.getAttendanceHistory(
      schoolId: schoolId,
      classId: classId,
      sectionId: sectionId,
      academicYear: "2025-2026",
      page: 1,
      limit: 10,
      startDate: "2025-12-01",
      endDate: "2025-12-31",
    );
    
    if (result != null) {

      for (var record in result) {
        
      }
    } else {
      
    }
  }

  // ==================== RUN ALL TESTS ====================

  Future<void> runAllTests() async {

    try {
      await testCollectFeeCashManual();
      await Future.delayed(Duration(seconds: 1));
      
      await testCollectFeeChequeAuto();
      await Future.delayed(Duration(seconds: 1));
      
      await testGetStudentRecord();
      await Future.delayed(Duration(seconds: 1));
      
      await testGetDues();
      await Future.delayed(Duration(seconds: 1));
      
      await testGetAttendanceSheet();
      await Future.delayed(Duration(seconds: 1));
      
      await testMarkAttendance();
      await Future.delayed(Duration(seconds: 1));
      
      await testGetAttendanceHistory();

    } catch (e) {
      
    }
  }
}

// Usage Example in a Widget
class ApiTestWidget extends StatelessWidget {
  final ApiTestExamples _apiTests = ApiTestExamples();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('API Tests')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _apiTests.runAllTests(),
              child: Text('Run All Tests'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _apiTests.testCollectFeeCashManual(),
              child: Text('Test Cash Payment'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _apiTests.testCollectFeeChequeAuto(),
              child: Text('Test Cheque Payment'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _apiTests.testGetStudentRecord(),
              child: Text('Test Get Record'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _apiTests.testMarkAttendance(),
              child: Text('Test Mark Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}