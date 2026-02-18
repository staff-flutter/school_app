// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../modules/auth/controllers/auth_controller.dart';
// import '../core/theme/app_theme.dart';
// import '../core/widgets/permission_wrapper.dart';
//
// class AttendanceView extends GetView<AttendanceController> {
//   AttendanceView({super.key});
//
//   final _formKey = GlobalKey<FormState>();
//   final _selectedClass = ''.obs;
//   final _selectedSection = ''.obs;
//   final _selectedDate = DateTime.now().obs;
//   final _academicYear = '2024-25'.obs;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Attendance Management'),
//         backgroundColor: AppTheme.primaryBlue,
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildFiltersSection(),
//               const SizedBox(height: 20),
//               _buildActionButtons(),
//               const SizedBox(height: 20),
//               Expanded(child: _buildAttendanceSheet()),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFiltersSection() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Select Class & Date',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: AppTheme.primaryText,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: Obx(() => DropdownButtonFormField<String>(
//                     decoration: const InputDecoration(
//                       labelText: 'Class',
//                       border: OutlineInputBorder(),
//                     ),
//                     value: _selectedClass.value.isEmpty ? null : _selectedClass.value,
//                     items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
//                         .map((cls) => DropdownMenuItem(
//                               value: cls,
//                               child: Text('Class $cls'),
//                             ))
//                         .toList(),
//                     onChanged: (value) {
//                       if (value != null) {
//                         _selectedClass.value = value;
//                       }
//                     },
//                     validator: (value) => value == null ? 'Please select a class' : null,
//                   )),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Obx(() => DropdownButtonFormField<String>(
//                     decoration: const InputDecoration(
//                       labelText: 'Section',
//                       border: OutlineInputBorder(),
//                     ),
//                     value: _selectedSection.value.isEmpty ? null : _selectedSection.value,
//                     items: ['A', 'B', 'C', 'D']
//                         .map((section) => DropdownMenuItem(
//                               value: section,
//                               child: Text('Section $section'),
//                             ))
//                         .toList(),
//                     onChanged: (value) {
//                       if (value != null) {
//                         _selectedSection.value = value;
//                       }
//                     },
//                     validator: (value) => value == null ? 'Please select a section' : null,
//                   )),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: Obx(() => InkWell(
//                     onTap: () => _selectDate(),
//                     child: InputDecorator(
//                       decoration: const InputDecoration(
//                         labelText: 'Date',
//                         border: OutlineInputBorder(),
//                         suffixIcon: Icon(Icons.calendar_today),
//                       ),
//                       child: Text(
//                         '${_selectedDate.value.day}/${_selectedDate.value.month}/${_selectedDate.value.year}',
//                       ),
//                     ),
//                   )),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Obx(() => DropdownButtonFormField<String>(
//                     decoration: const InputDecoration(
//                       labelText: 'Academic Year',
//                       border: OutlineInputBorder(),
//                     ),
//                     value: _academicYear.value,
//                     items: ['2023-24', '2024-25', '2025-26']
//                         .map((year) => DropdownMenuItem(
//                               value: year,
//                               child: Text(year),
//                             ))
//                         .toList(),
//                     onChanged: (value) {
//                       if (value != null) {
//                         _academicYear.value = value;
//                       }
//                     },
//                   )),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         PermissionWrapper(
//           permission: 'VIEW_attendance',
//           child: Expanded(
//             child: ElevatedButton.icon(
//               onPressed: _loadAttendanceSheet,
//               icon: const Icon(Icons.download),
//               label: const Text('Load Attendance Sheet'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.primaryBlue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 16),
//         PermissionWrapper(
//           permission: 'MARK_attendance',
//           child: Expanded(
//             child: ElevatedButton.icon(
//               onPressed: _markAttendance,
//               icon: const Icon(Icons.save),
//               label: const Text('Mark Attendance'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.successGreen,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildAttendanceSheet() {
//     return Obx(() {
//       if (controller.isLoading.value) {
//         return const Center(child: CircularProgressIndicator());
//       }
//
//       if (controller.attendanceSheet.isEmpty) {
//         return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.assignment,
//                 size: 64,
//                 color: Colors.grey[400],
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'No attendance sheet loaded',
//                 style: TextStyle(
//                   fontSize: 18,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Click "Load Attendance Sheet" to get started',
//                 style: TextStyle(
//                   color: Colors.grey[500],
//                 ),
//               ),
//             ],
//           ),
//         );
//       }
//
//       return Card(
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: AppTheme.primaryBlue.withOpacity(0.1),
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(8),
//                   topRight: Radius.circular(8),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: Text(
//                       'Student Name',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: AppTheme.primaryText,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       'Roll No.',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: AppTheme.primaryText,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       'Status',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: AppTheme.primaryText,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: controller.attendanceSheet.length,
//                 itemBuilder: (context, index) {
//                   final student = controller.attendanceSheet[index];
//                   return _buildStudentAttendanceRow(student, index);
//                 },
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }
//
//   Widget _buildStudentAttendanceRow(Map<String, dynamic> student, int index) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(color: Colors.grey[200]!),
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               student['studentName'] ?? 'Unknown',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ),
//           Expanded(
//             child: Text(student['rollNo']?.toString() ?? 'N/A'),
//           ),
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 Radio<String>(
//                   value: 'present',
//                   groupValue: student['status'] ?? 'present',
//                   onChanged: (value) {
//                     if (value != null) {
//                       controller.attendanceSheet[index]['status'] = value;
//                       controller.attendanceSheet.refresh();
//                     }
//                   },
//                   activeColor: AppTheme.successGreen,
//                 ),
//                 const Text('P'),
//                 Radio<String>(
//                   value: 'absent',
//                   groupValue: student['status'] ?? 'present',
//                   onChanged: (value) {
//                     if (value != null) {
//                       controller.attendanceSheet[index]['status'] = value;
//                       controller.attendanceSheet.refresh();
//                     }
//                   },
//                   activeColor: AppTheme.errorRed,
//                 ),
//                 const Text('A'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _selectDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: Get.context!,
//       initialDate: _selectedDate.value,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//     );
//     if (picked != null) {
//       _selectedDate.value = picked;
//     }
//   }
//
//   void _loadAttendanceSheet() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     final authController = Get.find<AuthController>();
//     final schoolId = authController.user.value?.schoolId ?? '';
//
//     if (schoolId.isEmpty) {
//       Get.snackbar('Error', 'School ID not found');
//       return;
//     }
//
//     await controller.getAttendanceSheet(
//       schoolId: schoolId,
//       classId: _selectedClass.value,
//       sectionId: _selectedSection.value,
//       date: controller.formatDate(_selectedDate.value),
//       academicYear: _academicYear.value,
//     );
//   }
//
//   void _markAttendance() async {
//     if (controller.attendanceSheet.isEmpty) {
//       Get.snackbar('Error', 'Please load attendance sheet first');
//       return;
//     }
//
//     final authController = Get.find<AuthController>();
//     final schoolId = authController.user.value?.schoolId ?? '';
//
//     if (schoolId.isEmpty) {
//       Get.snackbar('Error', 'School ID not found');
//       return;
//     }
//
//     final records = controller.attendanceSheet.map((student) {
//       return controller.createAttendanceRecord(
//         studentId: student['studentId'] ?? student['id'] ?? '',
//         studentName: student['studentName'] ?? 'Unknown',
//         status: student['status'] ?? 'present',
//         remark: student['remark'] ?? '',
//       );
//     }).toList();
//
//     final success = await controller.markAttendance(
//       schoolId: schoolId,
//       classId: _selectedClass.value,
//       sectionId: _selectedSection.value,
//       academicYear: _academicYear.value,
//       date: controller.formatDate(_selectedDate.value),
//       records: records,
//     );
//
//     if (success) {
//       Get.snackbar(
//         'Success',
//         'Attendance marked successfully',
//         backgroundColor: AppTheme.successGreen,
//         colorText: Colors.white,
//       );
//     }
//   }
// }