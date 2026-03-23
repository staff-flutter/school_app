import 'package:get/get.dart';

class StudentController extends GetxController {
  final isLoading = false.obs;
  final students = <Student>[].obs;
  final selectedClass = ''.obs;
  final selectedSection = ''.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadStudents();
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