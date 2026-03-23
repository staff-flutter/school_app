import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/models/student_model.dart';
import 'package:school_app/core/theme/app_theme.dart';

class CreateStudentView extends StatefulWidget {
  final Student? student;
  final String schoolId;
  final bool isEdit;

  const CreateStudentView({
    Key? key,
    this.student,
    required this.schoolId,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<CreateStudentView> createState() => _CreateStudentViewState();
}

class _CreateStudentViewState extends State<CreateStudentView> {
  final controller = Get.find<SchoolController>();
  final _formKey = GlobalKey<FormState>();

  // Controllers - Mandatory Fields
  final nameController = TextEditingController();
  final fatherNameController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final educationNumberController = TextEditingController();
  final motherNameController = TextEditingController();
  final guardianNameController = TextEditingController();
  final aadhaarNumberController = TextEditingController();
  final aadhaarNameController = TextEditingController();
  final addressController = TextEditingController();
  final pincodeController = TextEditingController();
  final alternateMobileController = TextEditingController();
  final emailController = TextEditingController();
  final motherTongueController = TextEditingController();
  final bloodGroupController = TextEditingController();

  // Controllers - Non-Mandatory Fields
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final distanceToSchoolController = TextEditingController();
  final admissionNumberController = TextEditingController();
  final admissionDateController = TextEditingController();
  final rollNumberController = TextEditingController();
  final mediumOfInstructionController = TextEditingController();
  final languagesStudiedController = TextEditingController();
  final subjectsStudiedController = TextEditingController();
  final gradeStudiedLastYearController = TextEditingController();
  final marksObtainedPercentageController = TextEditingController();
  final daysAttendedLastYearController = TextEditingController();
  final mainstreamedDateController = TextEditingController();
  final disabilityPercentController = TextEditingController();

  String? selectedGender;
  String? selectedClassId;
  String? selectedSectionId;
  String? selectedStudentType;
  String? selectedSocialCategory;
  String? selectedMinorityGroup;
  String? selectedBpl;
  String? selectedAay;
  String? selectedEws;
  String? selectedCwsn;
  String? selectedImpairments;
  String? selectedIndian;
  String? selectedOutOfSchool;
  String? selectedDisabilityCert;
  String? selectedFacilitiesProvided;
  String? selectedFacilitiesForCWSN;
  String? selectedScreenedForSLD;
  String? selectedSldType;
  String? selectedScreenedForASD;
  String? selectedScreenedForADHD;
  String? selectedIsGiftedOrTalented;
  String? selectedParticipatedInCompetitions;
  String? selectedParticipatedInActivities;
  String? selectedCanHandleDigitalDevices;
  String? selectedParentEducationLevel;
  String? selectedAcademicStream;
  String? selectedStatusInPreviousYear;
  String? selectedEnrolledUnder;
  String? selectedPreviousResult;
  DateTime? selectedDate;
  DateTime? selectedAdmissionDate;
  DateTime? selectedMainstreamedDate;

  final isLoading = false.obs;

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
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Modern App Bar
            _buildAppBar(context, isTablet),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionCard(
                        title: 'Basic Information',
                        icon: Icons.person,
                        gradient: AppTheme.primaryGradient,
                        children: [
                          _buildTextField(
                            controller: nameController,
                            label: 'Student Name',
                            icon: Icons.person_outline,
                            required: true,
                            validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: rollNumberController,
                            label: 'Roll Number',
                            icon: Icons.numbers,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: admissionNumberController,
                            label: 'Admission Number',
                            icon: Icons.badge,
                          ),

                          const SizedBox(height: 16),

                          _buildDropdown(
                            value: selectedGender,
                            label: 'Gender',
                            icon: Icons.wc,
                            items: ['Male', 'Female', 'Other'],
                            onChanged: (value) => setState(() => selectedGender = value),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: selectedStudentType,
                            label: 'Student Type',
                            icon: Icons.school,
                            items: ['new', 'old'],
                            itemLabels: ['New Student', 'Old Student'],
                            onChanged: (value) => setState(() => selectedStudentType = value),
                          ),

                          const SizedBox(height: 16),
                          _buildDateField(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: educationNumberController,
                            label: 'Education Number',
                            icon: Icons.school,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: motherTongueController,
                            label: 'Mother Tongue',
                            icon: Icons.language,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: bloodGroupController,
                            label: 'Blood Group',
                            icon: Icons.bloodtype,
                          ),
                          const SizedBox(height: 16),

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

                          _buildDropdown(
                            value: selectedSocialCategory,
                            label: 'Social Category',
                            icon: Icons.group,
                            items: ['General', 'OBC', 'SC', 'ST'],
                            onChanged: (value) => setState(() => selectedSocialCategory = value),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: selectedMinorityGroup,
                            label: 'Minority Group',
                            icon: Icons.people,
                            items: ['Yes', 'No'],
                            onChanged: (value) => setState(() => selectedMinorityGroup = value),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Academic Information Section
                      _buildSectionCard(
                        title: 'Academic Information',
                        icon: Icons.school,
                        gradient: AppTheme.successGradient,
                        children: [
                          Obx(() => _buildDropdown(
                            value: controller.classes.any((cls) => cls.id == selectedClassId) ? selectedClassId : null,
                            label: 'Select Class',
                            icon: Icons.class_,
                            required: true,
                            items: controller.classes.map((cls) => cls.id).toList(),
                            itemLabels: controller.classes.map((cls) => cls.name).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedClassId = value;
                                selectedSectionId = null;
                              });
                              if (value != null) {
                                controller.getAllSections(classId: value, schoolId: widget.schoolId);
                              }
                            },
                          )),
                          const SizedBox(height: 16),
                          Obx(() => _buildDropdown(
                            value: controller.sections.any((section) => section.id == selectedSectionId) ? selectedSectionId : null,
                            label: 'Select Section',
                            icon: Icons.group,
                            required: true,
                            items: controller.sections.map((section) => section.id).toList(),
                            itemLabels: controller.sections.map((section) => section.name).toList(),
                            onChanged: (value) => setState(() => selectedSectionId = value),
                            enabled: selectedClassId != null,
                          )),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: mediumOfInstructionController,
                            label: 'Medium of Instruction',
                            icon: Icons.language,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Contact Information Section
                      _buildSectionCard(
                        title: 'Contact Information',
                        icon: Icons.contact_phone,
                        gradient: AppTheme.warningGradient,
                        children: [
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

                      // Family Information Section
                      _buildSectionCard(
                        title: 'Family Information',
                        icon: Icons.family_restroom,
                        gradient: AppTheme.mathGradient,
                        children: [
                          _buildTextField(
                            controller: fatherNameController,
                            label: 'Father Name',
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: motherNameController,
                            label: 'Mother Name',
                            icon: Icons.person,
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

                      // Government Schemes
                      _buildSectionCard(
                        title: 'Government Schemes & Categories',
                        icon: Icons.account_balance,
                        gradient: AppTheme.errorGradient,
                        children: [
                          _buildDropdown(
                            value: selectedBpl,
                            label: 'BPL',
                            icon: Icons.account_balance,
                            items: ['Yes', 'No'],
                            onChanged: (value) => setState(() => selectedBpl = value),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: selectedEws,
                            label: 'EWS',
                            icon: Icons.monetization_on,
                            items: ['Yes', 'No'],
                            onChanged: (value) => setState(() => selectedEws = value),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: selectedCwsn,
                            label: 'CWSN',
                            icon: Icons.accessible,
                            items: ['Yes', 'No'],
                            onChanged: (value) => setState(() => selectedCwsn = value),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: selectedIndian,
                            label: 'Indian Citizen',
                            icon: Icons.flag,
                            items: ['Yes', 'No'],
                            onChanged: (value) => setState(() => selectedIndian = value),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Physical Information
                      _buildSectionCard(
                        title: 'Physical & Health Information',
                        icon: Icons.health_and_safety,
                        gradient: AppTheme.chemistryGradient,
                        children: [
                          _buildTextField(
                            controller: heightController,
                            label: 'Height (cm)',
                            icon: Icons.height,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: weightController,
                            label: 'Weight (kg)',
                            icon: Icons.monitor_weight,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: distanceToSchoolController,
                            label: 'Distance to School (km)',
                            icon: Icons.directions,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Special Needs
                      _buildSectionCard(
                        title: 'Special Needs & Screening',
                        icon: Icons.psychology,
                        gradient: AppTheme.physicsGradient,
                        children: [
                          _buildDropdown(
                            value: selectedFacilitiesProvided,
                            label: 'Facilities Provided',
                            icon: Icons.check_circle,
                            items: ['Yes', 'No'],
                            onChanged: (value) => setState(() => selectedFacilitiesProvided = value),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: selectedScreenedForSLD,
                            label: 'Screened for SLD',
                            icon: Icons.search,
                            items: ['Yes', 'No'],
                            onChanged: (value) => setState(() => selectedScreenedForSLD = value),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: selectedIsGiftedOrTalented,
                            label: 'Gifted/Talented',
                            icon: Icons.star,
                            items: ['Yes', 'No'],
                            onChanged: (value) => setState(() => selectedIsGiftedOrTalented = value),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: selectedCanHandleDigitalDevices,
                            label: 'Can Handle Digital Devices',
                            icon: Icons.devices,
                            items: ['Yes', 'No'],
                            onChanged: (value) => setState(() => selectedCanHandleDigitalDevices = value),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Academic Details
                      _buildSectionCard(
                        title: 'Extended Academic Information',
                        icon: Icons.menu_book,
                        gradient: AppTheme.biologyGradient,
                        children: [
                          _buildTextField(
                            controller: languagesStudiedController,
                            label: 'Languages Studied',
                            icon: Icons.translate,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: selectedAcademicStream,
                            label: 'Academic Stream',
                            icon: Icons.stream,
                            items: ['Science', 'Commerce', 'Arts', 'Vocational'],
                            onChanged: (value) => setState(() => selectedAcademicStream = value),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: marksObtainedPercentageController,
                            label: 'Marks Obtained (%)',
                            icon: Icons.percent,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: daysAttendedLastYearController,
                            label: 'Days Attended Last Year',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      _buildActionButtons(context),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit ? 'Edit Student' : 'Create New Student',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.isEdit ? 'Update student information' : 'Add a new student to the system',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required List<Widget> children,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
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
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    List<String>? itemLabels,
    required void Function(String?) onChanged,
    bool required = false,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon, color: enabled ? AppTheme.primaryBlue : Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final displayLabel = itemLabels != null && index < itemLabels.length
            ? itemLabels[index]
            : item;
        return DropdownMenuItem<String>(
          value: item,
          child: Text(displayLabel),
        );
      }).toList(),
    );
  }

  Widget _buildDateField({
    TextEditingController? controller,
    String? label,
    DateTime? selectedDate,
    Function(DateTime)? onDateSelected,
  }) {
    final dateController = controller ?? dobController;
    final dateLabel = label ?? 'Date of Birth';
    final currentSelectedDate = selectedDate ?? this.selectedDate;

    return TextFormField(
      controller: dateController,
      readOnly: true,
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: currentSelectedDate ?? DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            if (onDateSelected != null) {
              onDateSelected(pickedDate);
            } else {
              this.selectedDate = pickedDate;
            }
            dateController.text = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
          });
        }
      },
      decoration: InputDecoration(
        labelText: dateLabel,
        prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: AppTheme.primaryBlue),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 2,
          child: Obx(() => Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: isLoading.value ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading.value
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                widget.isEdit ? 'Update Student' : 'Create Student',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          )),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Validation Error',
        'Please fill all required fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (selectedClassId == null || selectedSectionId == null) {
      Get.snackbar(
        'Error',
        'Please select both class and section',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    isLoading.value = true;

    final mandatoryData = {
      'gender': selectedGender,
      'fatherName': fatherNameController.text,
      'mobileNumber': phoneController.text,
      'dob': selectedDate != null ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}' : null,
      'educationNumber': educationNumberController.text.isEmpty ? null : educationNumberController.text,
      'motherName': motherNameController.text.isEmpty ? null : motherNameController.text,
      'guardianName': guardianNameController.text.isEmpty ? null : guardianNameController.text,
      'aadhaarNumber': aadhaarNumberController.text.isEmpty ? null : aadhaarNumberController.text,
      'aadhaarName': aadhaarNameController.text.isEmpty ? null : aadhaarNameController.text,
      'address': addressController.text.isEmpty ? null : addressController.text,
      'pincode': pincodeController.text.isEmpty ? null : pincodeController.text,
      'alternateMobile': alternateMobileController.text.isEmpty ? null : alternateMobileController.text,
      'email': emailController.text.isEmpty ? null : emailController.text,
      'motherTongue': motherTongueController.text.isEmpty ? null : motherTongueController.text,
      'socialCategory': selectedSocialCategory,
      'minorityGroup': selectedMinorityGroup,
      'bpl': selectedBpl,
      'aay': selectedAay,
      'ews': selectedEws,
      'cwsn': selectedCwsn,
      'indian': selectedIndian,
      'outOfSchool': selectedOutOfSchool,
      'bloodGroup': bloodGroupController.text.isEmpty ? null : bloodGroupController.text,
    };

    final nonMandatoryData = {
      'facilitiesProvided': selectedFacilitiesProvided,
      'screenedForSLD': selectedScreenedForSLD,
      'isGiftedOrTalented': selectedIsGiftedOrTalented,
      'canHandleDigitalDevices': selectedCanHandleDigitalDevices,
      'heightInCm': heightController.text.isEmpty ? null : heightController.text,
      'weightInKg': weightController.text.isEmpty ? null : weightController.text,
      'distanceToSchool': distanceToSchoolController.text.isEmpty ? null : distanceToSchoolController.text,
      'parentEducationLevel': selectedParentEducationLevel,
      'admissionNumber': admissionNumberController.text.isEmpty ? null : admissionNumberController.text,
      'rollNumber': rollNumberController.text.isEmpty ? null : rollNumberController.text,
      'mediumOfInstruction': mediumOfInstructionController.text.isEmpty ? null : mediumOfInstructionController.text,
      'languagesStudied': languagesStudiedController.text.isEmpty ? null : languagesStudiedController.text,
      'academicStream': selectedAcademicStream,
      'marksObtainedPercentage': marksObtainedPercentageController.text.isEmpty ? null : marksObtainedPercentageController.text,
      'daysAttendedLastYear': daysAttendedLastYearController.text.isEmpty ? null : daysAttendedLastYearController.text,
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
      
      // WORKAROUND: If creation was successful but class/section weren't saved,
      // try to update the student with class/section info
      if (success) {
        
        // Get the latest students to find the newly created student
        await controller.getAllStudents(schoolId: widget.schoolId);
        
        // Find the student we just created (by name and school)
        final createdStudent = controller.students.firstWhereOrNull(
          (s) => s.name == nameController.text && s.schoolId == widget.schoolId
        );
        
        if (createdStudent != null && (createdStudent.classId == null || createdStudent.sectionId == null)) {
          
          final updateData = {
            'currentClassId': selectedClassId,
            'currentSectionId': selectedSectionId,
          };
          await controller.updateStudent(createdStudent.id, updateData);
        }
      }
    }

    isLoading.value = false;

    if (success) {
      Get.back();
      controller.getAllStudents(schoolId: widget.schoolId);
    }
  }

  @override
  void dispose() {
    // Mandatory field controllers
    nameController.dispose();
    fatherNameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    educationNumberController.dispose();
    motherNameController.dispose();
    guardianNameController.dispose();
    aadhaarNumberController.dispose();
    aadhaarNameController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    alternateMobileController.dispose();
    emailController.dispose();
    motherTongueController.dispose();
    bloodGroupController.dispose();

    // Non-mandatory field controllers
    heightController.dispose();
    weightController.dispose();
    distanceToSchoolController.dispose();
    admissionNumberController.dispose();
    admissionDateController.dispose();
    rollNumberController.dispose();
    mediumOfInstructionController.dispose();
    languagesStudiedController.dispose();
    subjectsStudiedController.dispose();
    gradeStudiedLastYearController.dispose();
    marksObtainedPercentageController.dispose();
    daysAttendedLastYearController.dispose();
    mainstreamedDateController.dispose();
    disabilityPercentController.dispose();

    super.dispose();
  }
}
