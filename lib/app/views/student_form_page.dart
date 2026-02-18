import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/school_controller.dart';
import '../data/models/school_models.dart';
import '../data/models/student_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/class_utils.dart';

class StudentFormPage extends StatefulWidget {
  final Student? student;
  final String schoolId;
  final bool isEdit;

  const StudentFormPage({
    Key? key,
    this.student,
    required this.schoolId,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
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
    selectedStudentType = student.newOld;
    if (student.dob != null && student.dob!.isNotEmpty) {
      dobController.text = student.dob!;
    }
    
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
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Modern AppBar
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.topRight,
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.primaryBlue.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Row(
                  children: [
                    // Back Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEdit ? 'Edit Student' : 'Add New Student',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 24 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.isEdit ? 'Update student information' : 'Fill in student details',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Save Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _submitForm,
                        icon: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: Column(
                  children: [
                    // Basic Information Card
                    _buildSectionCard(
                      'Basic Information',
                      Icons.person,
                      Colors.blue,
                      [
                        _buildTextField(
                          controller: nameController,
                          label: 'Student Name *',
                          icon: Icons.person_outline,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: rollNumberController,
                          label: 'Roll Number',
                          icon: Icons.numbers,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Gender',
                          value: selectedGender,
                          icon: Icons.wc,
                          items: ['Male', 'Female', 'Other'],
                          onChanged: (value) => setState(() => selectedGender = value),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Student Type',
                          value: selectedStudentType,
                          icon: Icons.category,
                          items: const ['new', 'old'],
                          itemLabels: const ['New Student', 'Old Student'],
                          onChanged: (value) => setState(() => selectedStudentType = value),
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Family Information Card
                    _buildSectionCard(
                      'Family Information',
                      Icons.family_restroom,
                      Colors.green,
                      [
                        _buildTextField(
                          controller: fatherNameController,
                          label: 'Father Name',
                          icon: Icons.man,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: motherNameController,
                          label: 'Mother Name',
                          icon: Icons.woman,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: guardianNameController,
                          label: 'Guardian Name',
                          icon: Icons.supervisor_account,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Contact Information Card
                    _buildSectionCard(
                      'Contact Information',
                      Icons.contact_phone,
                      Colors.orange,
                      [
                        _buildTextField(
                          controller: phoneController,
                          label: 'Mobile Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: alternateMobileController,
                          label: 'Alternate Mobile',
                          icon: Icons.phone_android,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: emailController,
                          label: 'Email',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: addressController,
                          label: 'Address',
                          icon: Icons.location_on,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: pincodeController,
                          label: 'Pincode',
                          icon: Icons.pin_drop,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Academic Information Card
                    _buildSectionCard(
                      'Academic Information',
                      Icons.school,
                      Colors.purple,
                      [
                        _buildClassDropdown(),
                        const SizedBox(height: 16),
                        _buildSectionDropdown(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: admissionNumberController,
                          label: 'Admission Number',
                          icon: Icons.confirmation_number,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: mediumOfInstructionController,
                          label: 'Medium of Instruction',
                          icon: Icons.language,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Additional Information Card
                    _buildSectionCard(
                      'Additional Information',
                      Icons.info,
                      Colors.teal,
                      [
                        _buildTextField(
                          controller: aadhaarNumberController,
                          label: 'Aadhaar Number',
                          icon: Icons.credit_card,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: aadhaarNameController,
                          label: 'Aadhaar Name',
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: bloodGroupController,
                          label: 'Blood Group',
                          icon: Icons.bloodtype,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: heightController,
                                label: 'Height (cm)',
                                icon: Icons.height,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: weightController,
                                label: 'Weight (kg)',
                                icon: Icons.monitor_weight,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.isEdit ? 'Update Student' : 'Create Student',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required IconData icon,
    required List<String> items,
    List<String>? itemLabels,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final displayLabel = itemLabels != null ? itemLabels[index] : item;
        return DropdownMenuItem(
          value: item,
          child: Text(displayLabel),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: dobController,
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 20),
        ),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
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
    );
  }

  Widget _buildClassDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
      value: controller.classes.any((cls) => cls.id == selectedClassId) ? selectedClassId : null,
      decoration: InputDecoration(
        labelText: 'Select Class *',
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.class_, color: AppTheme.primaryBlue, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: ClassUtils.sortClasses(controller.classes).map<DropdownMenuItem<String>>((cls) {
        return DropdownMenuItem<String>(
          value: cls.id,
          child: Row(
            children: [
              Icon(ClassUtils.getClassIcon(cls.name), size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Text(cls.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          selectedClassId = value;
          selectedSectionId = null;
        });
        if (value != null) {
          controller.getAllSections(classId: value, schoolId: widget.schoolId);
        } else {
          controller.sections.clear();
        }
      },
    ));
  }

  Widget _buildSectionDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
      value: controller.sections.any((section) => section.id == selectedSectionId) ? selectedSectionId : null,
      decoration: InputDecoration(
        labelText: 'Select Section *',
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.group, color: AppTheme.primaryBlue, size: 20),
        ),
        suffixIcon: controller.isLoading.value && selectedClassId != null
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: controller.sections.map<DropdownMenuItem<String>>((section) {
        return DropdownMenuItem<String>(
          value: section.id,
          child: Text(section.name),
        );
      }).toList(),
      onChanged: selectedClassId != null ? (String? value) => setState(() => selectedSectionId = value) : null,
    ));
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
      Get.back(); // Go back to previous screen
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