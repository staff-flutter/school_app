class DashboardKPI {
  final double todayCollection;
  final double outstandingTotal;
  final double expensesMTD;
  final double netBalance;
  
  // Academic role fields
  final int? totalStudents;
  final int? activeClasses;
  final double? monthlyRevenue;
  
  // Teacher role fields
  final int? myClasses;
  final int? myStudents;
  final double? attendanceRate;
  final int? pendingTasks;
  
  // Student/Parent role fields
  final double? studentFeeDue;
  final double? studentAttendance;
  final int? unreadNotices;
  final int? activeActivities;

  DashboardKPI({
    required this.todayCollection,
    required this.outstandingTotal,
    required this.expensesMTD,
    required this.netBalance,
    this.totalStudents,
    this.activeClasses,
    this.monthlyRevenue,
    this.myClasses,
    this.myStudents,
    this.attendanceRate,
    this.pendingTasks,
    this.studentFeeDue,
    this.studentAttendance,
    this.unreadNotices,
    this.activeActivities,
  });

  factory DashboardKPI.fromJson(Map<String, dynamic> json) {
    return DashboardKPI(
      todayCollection: (json['today_collection'] ?? 0).toDouble(),
      outstandingTotal: (json['outstanding_total'] ?? 0).toDouble(),
      expensesMTD: (json['expenses_mtd'] ?? 0).toDouble(),
      netBalance: (json['net_balance'] ?? 0).toDouble(),
      totalStudents: json['total_students']?.toInt(),
      activeClasses: json['active_classes']?.toInt(),
      monthlyRevenue: json['monthly_revenue']?.toDouble(),
      myClasses: json['my_classes']?.toInt(),
      myStudents: json['my_students']?.toInt(),
      attendanceRate: json['attendance_rate']?.toDouble(),
      pendingTasks: json['pending_tasks']?.toInt(),
      studentFeeDue: json['student_fee_due']?.toDouble(),
      studentAttendance: json['student_attendance']?.toDouble(),
      unreadNotices: json['unread_notices']?.toInt(),
      activeActivities: json['active_activities']?.toInt(),
    );
  }
}

class StudentDue {
  final String dueId;
  final String feeHead;
  final double dueAmount;
  final String dueDate;

  StudentDue({
    required this.dueId,
    required this.feeHead,
    required this.dueAmount,
    required this.dueDate,
  });

  factory StudentDue.fromJson(Map<String, dynamic> json) {
    return StudentDue(
      dueId: json['due_id'] ?? '',
      feeHead: json['fee_head'] ?? '',
      dueAmount: (json['due_amount'] ?? 0).toDouble(),
      dueDate: json['due_date'] ?? '',
    );
  }
}

class FeeReceipt {
  final String receiptId;
  final String receiptNo;
  final String status;
  final double amount;
  final String paymentMode;
  final String date;

  FeeReceipt({
    required this.receiptId,
    required this.receiptNo,
    required this.status,
    required this.amount,
    required this.paymentMode,
    required this.date,
  });

  factory FeeReceipt.fromJson(Map<String, dynamic> json) {
    return FeeReceipt(
      receiptId: json['receipt_id'] ?? '',
      receiptNo: json['receipt_no'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMode: json['payment_mode'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class Expense {
  final String id;
  final String schoolId;
  final String academicYear;
  final String category;
  final double amount;
  final String paymentMode;
  final String verificationStatus;
  final String date;
  final String? expenseNo;
  final String? remarks;
  final List<dynamic> bill;
  final List<dynamic> workPhoto;
  final String recordedBy;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic>? chequeDetails;

  Expense({
    required this.id,
    required this.schoolId,
    required this.academicYear,
    required this.category,
    required this.amount,
    required this.paymentMode,
    required this.verificationStatus,
    required this.date,
    this.expenseNo,
    this.remarks,
    required this.bill,
    required this.workPhoto,
    required this.recordedBy,
    required this.createdAt,
    required this.updatedAt,
    this.chequeDetails,
  });

  // Getter for backward compatibility
  String get status => verificationStatus;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['_id'] ?? '',
      schoolId: json['schoolId'] ?? '',
      academicYear: json['academicYear'] ?? '',
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMode: json['paymentMode'] ?? '',
      verificationStatus: json['verificationStatus'] ?? 'pending',
      date: json['date'] ?? json['createdAt'] ?? '',
      expenseNo: json['expenseNo'],
      remarks: json['remarks'],
      bill: json['bill'] ?? [],
      workPhoto: json['workPhoto'] ?? [],
      recordedBy: json['recordedBy'] is Map 
          ? json['recordedBy']['_id'] ?? ''
          : json['recordedBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      chequeDetails: json['chequeDetails'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'schoolId': schoolId,
      'academicYear': academicYear,
      'category': category,
      'amount': amount,
      'paymentMode': paymentMode,
      'verificationStatus': verificationStatus,
      'date': date,
      'expenseNo': expenseNo,
      'bill': bill,
      'workPhoto': workPhoto,
      'recordedBy': recordedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'chequeDetails': chequeDetails,
    };
  }
}