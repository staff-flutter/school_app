import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../constants/api_constants.dart';

class StudentController extends GetxController {
  final isLoading = false.obs;
  final students = <Student>[].obs;
  final selectedClass = ''.obs;
  final selectedSection = ''.obs;
  final searchQuery = ''.obs;
  final isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadStudents();
  }
  Future<bool> uploadStudentFiles({
    required String studentId,
    required List<PlatformFile> selectedFiles,
  }) async {
    if (selectedFiles.isEmpty) {
      Get.snackbar('Warning', 'No files selected to upload',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return false;
    }

    try {
      isUploading.value = true;

      final formData = dio.FormData();

      for (var file in selectedFiles) {
        if (file.bytes != null) {
          formData.files.add(MapEntry(
            'files',
            dio.MultipartFile.fromBytes(file.bytes!, filename: file.name),
          ));
        } else if (file.path != null) {
          formData.files.add(MapEntry(
            'files',
            await dio.MultipartFile.fromFile(file.path!, filename: file.name),
          ));
        }
      }

      final _dio = dio.Dio();
      final url = '${ApiConstants.baseUrl}/api/student/v1/upload-files/$studentId';

      final response = await _dio.post(
        url,
        data: formData,
        options: dio.Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Files uploaded successfully!',
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        Get.snackbar('Error', 'Upload failed. Status: ${response.statusCode}',
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      debugPrint('File upload error: $e');
      Get.snackbar('Error', 'Upload failed: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isUploading.value = false;
    }
  }
  void loadStudents() {
    // Dummy data
    students.value = [
      Student(
        id: '1',
        name: 'John Doe',
        rollNumber: '001',
        className: '10',
        section: 'A',
        fatherName: 'Robert Doe',
        motherName: 'Jane Doe',
        phoneNumber: '9876543210',
        address: '123 Main St, City',
        dateOfBirth: '2008-05-15',
        admissionDate: '2023-04-01',
        bloodGroup: 'O+',
        status: 'Active',
      ),
      Student(
        id: '2',
        name: 'Alice Smith',
        rollNumber: '002',
        className: '10',
        section: 'A',
        fatherName: 'David Smith',
        motherName: 'Sarah Smith',
        phoneNumber: '9876543211',
        address: '456 Oak Ave, City',
        dateOfBirth: '2008-08-22',
        admissionDate: '2023-04-01',
        bloodGroup: 'A+',
        status: 'Active',
      ),
      Student(
        id: '3',
        name: 'Bob Johnson',
        rollNumber: '003',
        className: '9',
        section: 'B',
        fatherName: 'Mike Johnson',
        motherName: 'Lisa Johnson',
        phoneNumber: '9876543212',
        address: '789 Pine St, City',
        dateOfBirth: '2009-03-10',
        admissionDate: '2023-04-01',
        bloodGroup: 'B+',
        status: 'Active',
      ),
    ];
  }

  List<Student> get filteredStudents {
    var filtered = students.where((student) {
      bool matchesClass = selectedClass.value.isEmpty || student.className == selectedClass.value;
      bool matchesSection = selectedSection.value.isEmpty || student.section == selectedSection.value;
      bool matchesSearch = searchQuery.value.isEmpty || 
          student.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          student.rollNumber.contains(searchQuery.value);
      
      return matchesClass && matchesSection && matchesSearch;
    }).toList();
    
    return filtered;
  }

  void addStudent(Student student) {
    students.add(student);
    Get.snackbar('Success', 'Student added successfully');
  }

  void updateStudent(Student student) {
    int index = students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      students[index] = student;
      Get.snackbar('Success', 'Student updated successfully');
    }
  }

  void deleteStudent(String studentId) {
    students.removeWhere((s) => s.id == studentId);
    Get.snackbar('Success', 'Student deleted successfully');
  }
}

class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String className;
  final String section;
  final String fatherName;
  final String motherName;
  final String phoneNumber;
  final String address;
  final String dateOfBirth;
  final String admissionDate;
  final String bloodGroup;
  final String status;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.className,
    required this.section,
    required this.fatherName,
    required this.motherName,
    required this.phoneNumber,
    required this.address,
    required this.dateOfBirth,
    required this.admissionDate,
    required this.bloodGroup,
    required this.status,
  });
}