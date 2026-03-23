import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/models/student_model.dart';

class StudentFormDialog extends StatefulWidget {
  final Student? student;
  final String schoolId;
  final bool isEdit;

  const StudentFormDialog({
    Key? key,
    this.student,
    required this.schoolId,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final controller = Get.find<SchoolController>();
  
  final nameController = TextEditingController();
  final rollNumberController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final dobController = TextEditingController();
  final fatherNameController = TextEditingController();
  final motherNameController = TextEditingController();
  final guardianNameController = TextEditingController();
  final aadhaarNumberController = TextEditingController();
  final aadhaarNameController = TextEditingController();
  final pincodeController = TextEditingController();
  final alternateMobileController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final admissionNumberController = TextEditingController();
  final mediumOfInstructionController = TextEditingController();
  
  String? selectedGender;
  String? selectedClassId;
  String? selectedSectionId;
  String? selectedStudentType;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.student != null) {
      _populateFields();
    }
    // Defer API call to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getAllClasses(widget.schoolId);
    });
  }

  void _populateFields() {
    final student = widget.student!;
    nameController.text = student.name ?? '';
    rollNumberController.text = student.rollNumber ?? '';
    emailController.text = student.email ?? '';
    phoneController.text = student.mobileNumber ?? '';
    addressController.text = student.address ?? '';
    fatherNameController.text = student.fatherName ?? '';
    motherNameController.text = student.motherName ?? '';
    guardianNameController.text = student.guardianName ?? '';
    aadhaarNumberController.text = student.aadhaarNumber ?? '';
    aadhaarNameController.text = student.aadhaarName ?? '';
    pincodeController.text = student.pincode ?? '';
    alternateMobileController.text = student.alternateMobile ?? '';
    bloodGroupController.text = student.bloodGroup ?? '';
    heightController.text = student.heightInCm ?? '';
    weightController.text = student.weightInKg ?? '';
    admissionNumberController.text = student.admissionNumber ?? '';
    mediumOfInstructionController.text = student.mediumOfInstruction ?? '';
    selectedGender = student.gender;
    selectedStudentType = student.newOld; // Don't default to 'new' if null
    if (student.dob != null && student.dob!.isNotEmpty) {
      dobController.text = student.dob!;
    }
    
    // Set class and section after classes are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (student.classId != null) {
        selectedClassId = student.classId;
        controller.getAllSections(classId: student.classId, schoolId: widget.schoolId).then((_) {
          setState(() {
            selectedSectionId = student.sectionId;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Student' : 'Create Student'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Student Name *')),
              const SizedBox(height: 16),
              TextField(controller: rollNumberController, decoration: const InputDecoration(labelText: 'Roll Number')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Gender'),
                value: selectedGender,
                items: ['Male', 'Female', 'Other'].map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) => setState(() => selectedGender = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Student Type'),
                value: selectedStudentType,
                items: const [
                  DropdownMenuItem(value: 'new', child: Text('New Student')),
                  DropdownMenuItem(value: 'old', child: Text('Old Student')),
                ],
                onChanged: (value) => setState(() => selectedStudentType = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dobController,
                decoration: const InputDecoration(labelText: 'Date of Birth', suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                      dobController.text = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(controller: fatherNameController, decoration: const InputDecoration(labelText: 'Father Name')),
              const SizedBox(height: 16),
              TextField(controller: motherNameController, decoration: const InputDecoration(labelText: 'Mother Name')),
              const SizedBox(height: 16),
              TextField(controller: guardianNameController, decoration: const InputDecoration(labelText: 'Guardian Name')),
              const SizedBox(height: 16),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Mobile Number')),
              const SizedBox(height: 16),
              TextField(controller: alternateMobileController, decoration: const InputDecoration(labelText: 'Alternate Mobile')),
              const SizedBox(height: 16),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
              const SizedBox(height: 16),
              TextField(controller: pincodeController, decoration: const InputDecoration(labelText: 'Pincode')),
              const SizedBox(height: 16),
              TextField(controller: aadhaarNumberController, decoration: const InputDecoration(labelText: 'Aadhaar Number')),
              const SizedBox(height: 16),
              TextField(controller: aadhaarNameController, decoration: const InputDecoration(labelText: 'Aadhaar Name')),
              const SizedBox(height: 16),
              TextField(controller: bloodGroupController, decoration: const InputDecoration(labelText: 'Blood Group')),
              const SizedBox(height: 16),
              TextField(controller: heightController, decoration: const InputDecoration(labelText: 'Height (cm)')),
              const SizedBox(height: 16),
              TextField(controller: weightController, decoration: const InputDecoration(labelText: 'Weight (kg)')),
              const SizedBox(height: 16),
              TextField(controller: admissionNumberController, decoration: const InputDecoration(labelText: 'Admission Number')),
              const SizedBox(height: 16),
              TextField(controller: mediumOfInstructionController, decoration: const InputDecoration(labelText: 'Medium of Instruction')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Class *'),
                value: controller.classes.any((cls) => cls.id == selectedClassId) ? selectedClassId : null,
                items: controller.classes.map<DropdownMenuItem<String>>((cls) {
                  return DropdownMenuItem<String>(value: cls.id, child: Text(cls.name));
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    selectedClassId = value;
                    selectedSectionId = null;
                  });
                  if (value != null) {
                    controller.getAllSections(classId: value, schoolId: widget.schoolId);
                  } else {
                    // Clear sections when no class is selected
                    controller.sections.clear();
                  }
                },
              ),
              const SizedBox(height: 16),
              Obx(() => DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Section *',
                  suffixIcon: controller.isLoading.value && selectedClassId != null
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                value: controller.sections.any((section) => section.id == selectedSectionId) ? selectedSectionId : null,
                items: controller.sections.map<DropdownMenuItem<String>>((section) {
                  return DropdownMenuItem<String>(value: section.id, child: Text(section.name));
                }).toList(),
                onChanged: selectedClassId != null ? (String? value) => setState(() => selectedSectionId = value) : null,
              )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: _submitForm,
          child: Text(widget.isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (nameController.text.isEmpty || selectedClassId == null || selectedSectionId == null) {
      Get.snackbar(
        'Error', 
        'Please fill required fields (marked with *)',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final mandatoryData = {
      'gender': selectedGender ?? '',
      'dob': selectedDate != null ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}' : '',
      'fatherName': fatherNameController.text,
      'motherName': motherNameController.text,
      'guardianName': guardianNameController.text,
      'mobileNumber': phoneController.text,
      'alternateMobile': alternateMobileController.text,
      'email': emailController.text,
      'address': addressController.text,
      'pincode': pincodeController.text,
      'aadhaarNumber': aadhaarNumberController.text,
      'aadhaarName': aadhaarNameController.text,
      'bloodGroup': bloodGroupController.text,
    };

    final nonMandatoryData = {
      'rollNumber': rollNumberController.text,
      'heightInCm': heightController.text,
      'weightInKg': weightController.text,
      'admissionNumber': admissionNumberController.text,
      'mediumOfInstruction': mediumOfInstructionController.text,
    };

    final studentData = {
      'schoolId': widget.schoolId,
      'studentName': nameController.text,
      'currentClassId': selectedClassId,
      'currentSectionId': selectedSectionId,
      'mandatory': jsonEncode(mandatoryData),
      'nonMandatory': jsonEncode(nonMandatoryData),
      'newOld': selectedStudentType,
    };

    bool success = false;
    if (widget.isEdit) {
      success = await controller.updateStudent(widget.student!.id, studentData);
    } else {
      success = await controller.createStudent(studentData);
    }

    if (success) {
      Navigator.of(context).pop(); // Close dialog only on success
      // Refresh the student list
      controller.getAllStudents(schoolId: widget.schoolId);
      Get.snackbar(
        'Success',
        widget.isEdit ? 'Student updated successfully' : 'Student created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    rollNumberController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    dobController.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    guardianNameController.dispose();
    aadhaarNumberController.dispose();
    aadhaarNameController.dispose();
    pincodeController.dispose();
    alternateMobileController.dispose();
    bloodGroupController.dispose();
    heightController.dispose();
    weightController.dispose();
    admissionNumberController.dispose();
    mediumOfInstructionController.dispose();
    super.dispose();
  }
}
