import 'package:get/get.dart';
import 'package:flutter/material.dart';

class StudentsController extends GetxController {
  final isLoading = false.obs;
  final students = <Student>[].obs;
  
  String userRole = 'correspondent';
  String permission = 'full';
  
  bool get canCreate => ['correspondent', 'administrator', 'accountant'].contains(userRole);
  bool get canEdit => ['correspondent', 'administrator', 'accountant'].contains(userRole);
  bool get canDelete => userRole == 'correspondent';
  bool get isFinanceView => permission == 'financeView';
  bool get isReadOnly => ['readOnly', 'classScopedReadOnly'].contains(permission);

  @override
  void onInit() {
    super.onInit();
    loadStudents();
  }

  Future<void> loadStudents() async {
    isLoading.value = true;
    await Future.delayed(Duration(milliseconds: 500));
    _loadDummyStudents();
    isLoading.value = false;
  }

  void _loadDummyStudents() {
    students.value = List.generate(20, (index) => Student(
      id: 'student_$index',
      name: 'Student ${index + 1}',
      rollNumber: '${index + 1}'.padLeft(3, '0'),
      className: 'Class ${(index % 5) + 1}',
      section: 'Section ${String.fromCharCode(65 + (index % 3))}',
      feeStatus: index % 3 == 0 ? 'Due' : 'Paid',
      parentName: 'Parent ${index + 1}',
      phone: '+91 98765${index.toString().padLeft(5, '0')}',
      email: 'student${index + 1}@school.com',
      address: 'Address ${index + 1}',
      admissionDate: '2024-01-${(index % 28 + 1).toString().padLeft(2, '0')}',
    ));
  }

  Future<void> createStudent(Student student) async {
    if (!canCreate) {
      Get.snackbar('Error', 'No permission to create students');
      return;
    }
    students.add(student);
    Get.snackbar('Success', 'Student created successfully');
  }

  Future<void> updateStudent(Student student) async {
    if (!canEdit) {
      Get.snackbar('Error', 'No permission to edit students');
      return;
    }
    final index = students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      students[index] = student;
      Get.snackbar('Success', 'Student updated successfully');
    }
  }

  Future<void> deleteStudent(String studentId) async {
    if (!canDelete) {
      Get.snackbar('Error', 'No permission to delete students');
      return;
    }
    students.removeWhere((s) => s.id == studentId);
    Get.snackbar('Success', 'Student deleted successfully');
  }

  List<Student> get filteredStudents {
    if (permission == 'classScopedReadOnly') {
      return students.where((s) => s.className.contains('1') || s.className.contains('2')).toList();
    }
    return students;
  }
}

class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String className;
  final String section;
  final String feeStatus;
  final String parentName;
  final String phone;
  final String email;
  final String address;
  final String admissionDate;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.className,
    required this.section,
    required this.feeStatus,
    required this.parentName,
    required this.phone,
    required this.email,
    required this.address,
    required this.admissionDate,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      rollNumber: json['rollNumber'] ?? '',
      className: json['className'] ?? json['class'] ?? '',
      section: json['section'] ?? '',
      feeStatus: json['feeStatus'] ?? 'Unknown',
      parentName: json['parentName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      admissionDate: json['admissionDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rollNumber': rollNumber,
      'className': className,
      'section': section,
      'parentName': parentName,
      'phone': phone,
      'email': email,
      'address': address,
      'admissionDate': admissionDate,
    };
  }
}