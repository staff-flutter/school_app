class StudentRecord {
  final String id;
  final String schoolId;
  final String studentId;
  final String classId;
  final String sectionId;
  final String academicYear;
  final Map<String, dynamic>? feeStructure;
  final Map<String, dynamic>? feePaid;
  final Map<String, dynamic>? dues;
  final Map<String, dynamic>? concession;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentRecord({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.classId,
    required this.sectionId,
    required this.academicYear,
    this.feeStructure,
    this.feePaid,
    this.dues,
    this.concession,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentRecord.fromJson(Map<String, dynamic> json) {
    return StudentRecord(
      id: json['_id'] ?? '',
      schoolId: json['schoolId'] ?? '',
      studentId: json['studentId'] ?? '',
      classId: json['classId'] ?? '',
      sectionId: json['sectionId'] ?? '',
      academicYear: json['academicYear'] ?? '',
      feeStructure: json['feeStructure'],
      feePaid: json['feePaid'],
      dues: json['dues'],
      concession: json['concession'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'schoolId': schoolId,
      'studentId': studentId,
      'classId': classId,
      'sectionId': sectionId,
      'academicYear': academicYear,
      'feeStructure': feeStructure,
      'feePaid': feePaid,
      'dues': dues,
      'concession': concession,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class FeeReceipt {
  final String id;
  final String studentRecordId;
  final double amount;
  final String paymentMode;
  final Map<String, dynamic>? paidHeads;
  final List<Map<String, dynamic>>? cashDenominations;
  final String? referenceNumber;
  final String? bankName;
  final String? chequeDate;
  final String? remarks;
  final String status; // 'paid', 'cancelled', 'bounced'
  final DateTime createdAt;

  FeeReceipt({
    required this.id,
    required this.studentRecordId,
    required this.amount,
    required this.paymentMode,
    this.paidHeads,
    this.cashDenominations,
    this.referenceNumber,
    this.bankName,
    this.chequeDate,
    this.remarks,
    required this.status,
    required this.createdAt,
  });

  factory FeeReceipt.fromJson(Map<String, dynamic> json) {
    return FeeReceipt(
      id: json['_id'] ?? '',
      studentRecordId: json['studentRecordId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMode: json['paymentMode'] ?? '',
      paidHeads: json['paidHeads'],
      cashDenominations: json['cashDenominations'] != null 
          ? List<Map<String, dynamic>>.from(json['cashDenominations'])
          : null,
      referenceNumber: json['referenceNumber'],
      bankName: json['bankName'],
      chequeDate: json['chequeDate'],
      remarks: json['remarks'],
      status: json['status'] ?? 'paid',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'studentRecordId': studentRecordId,
      'amount': amount,
      'paymentMode': paymentMode,
      'paidHeads': paidHeads,
      'cashDenominations': cashDenominations,
      'referenceNumber': referenceNumber,
      'bankName': bankName,
      'chequeDate': chequeDate,
      'remarks': remarks,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AttendanceRecord {
  final String id;
  final String schoolId;
  final String classId;
  final String? sectionId;
  final String academicYear;
  final String date;
  final List<StudentAttendance> records;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecord({
    required this.id,
    required this.schoolId,
    required this.classId,
    this.sectionId,
    required this.academicYear,
    required this.date,
    required this.records,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'] ?? '',
      schoolId: json['schoolId'] ?? '',
      classId: json['classId'] ?? '',
      sectionId: json['sectionId'],
      academicYear: json['academicYear'] ?? '',
      date: json['date'] ?? '',
      records: (json['records'] as List? ?? [])
          .map((record) => StudentAttendance.fromJson(record))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'schoolId': schoolId,
      'classId': classId,
      'sectionId': sectionId,
      'academicYear': academicYear,
      'date': date,
      'records': records.map((record) => record.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class StudentAttendance {
  final String studentId;
  final String studentName;
  final String status; // 'present' or 'absent'
  final String? remark;

  StudentAttendance({
    required this.studentId,
    required this.studentName,
    required this.status,
    this.remark,
  });

  factory StudentAttendance.fromJson(Map<String, dynamic> json) {
    return StudentAttendance(
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      status: json['status'] ?? 'absent',
      remark: json['remark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'status': status,
      'remark': remark,
    };
  }
}