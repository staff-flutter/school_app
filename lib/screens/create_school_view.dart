import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:school_app/controllers/auth_controller.dart';

class CreateSchoolView extends GetView<AuthController> {
  CreateSchoolView({super.key});

  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _academicYearController = TextEditingController(text: '2024-2025');
  final selectedLogo = Rxn<File>();

  // App color constants
  static const Color _bgColor = Color(0xFFEEF0F8);
  static const Color _cardColor = Colors.white;
  static const Color _primaryBlue = Color(0xFF3D5AFE);
  static const Color _iconBg = Color(0xFFE8EAFF);
  static const Color _fieldBg = Color(0xFFEEF0F8);
  static const Color _hintColor = Color(0xFF9E9E9E);
  static const Color _labelColor = Color(0xFF424242);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87,size: 18,),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Create School',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                _buildHeaderCard(
                  title: 'Create New School',
                  subtitle: 'Fill in the details to set up your school',
                ),
                const SizedBox(height: 16),

                // School Info Section
                _buildSectionCard(
                  icon: Icons.school_rounded,
                  sectionTitle: 'School Information',
                  children: [
                    _buildTextField(
                      controller: _schoolNameController,
                      icon: Icons.account_balance_rounded,
                      hint: 'School Name *',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter school name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _emailController,
                      icon: Icons.email_rounded,
                      hint: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      icon: Icons.phone_rounded,
                      hint: 'Phone Number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      icon: Icons.location_on_rounded,
                      hint: 'Address',
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Academic Year Section
                _buildSectionCard(
                  icon: Icons.calendar_month_rounded,
                  sectionTitle: 'Academic Year',
                  children: [
                    _buildTextField(
                      controller: _academicYearController,
                      icon: Icons.date_range_rounded,
                      hint: 'Current Academic Year',
                      helperText: 'Format: 2024-2025',
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final regex = RegExp(r'^\d{4}-\d{4}$');
                          if (!regex.hasMatch(value)) {
                            return 'Format should be YYYY-YYYY (e.g., 2024-2025)';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Logo Section
                _buildSectionCard(
                  icon: Icons.image_rounded,
                  sectionTitle: 'School Logo',
                  children: [
                    Obx(() => selectedLogo.value != null
                        ? _buildLogoPreview()
                        : _buildLogoPickerField()),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                Obx(() => SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : _createSchool,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _primaryBlue.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Create School',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────

  Widget _buildHeaderCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: _hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String sectionTitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                sectionTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: _labelColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
        helperText: helperText,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _primaryBlue, size: 18),
          ),
        ),
        filled: true,
        fillColor: _fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildLogoPickerField() {
    return GestureDetector(
      onTap: _pickLogo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_photo_alternate_rounded,
                  color: _primaryBlue, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Select Logo (Optional)',
              style: TextStyle(color: _hintColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPreview() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            selectedLogo.value!,
            height: 64,
            width: 64,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Logo selected',
            style: TextStyle(
              color: _primaryBlue,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        TextButton(
          onPressed: () => selectedLogo.value = null,
          child: const Text(
            'Remove',
            style: TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ── Logic (unchanged) ─────────────────────────────────────

  void _createSchool() {
    if (_formKey.currentState!.validate()) {
      controller.createSchool(
        _schoolNameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
        _addressController.text.trim(),
        _academicYearController.text.trim(),
        selectedLogo.value,
      );
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedLogo.value = File(pickedFile.path);
    }
  }
}