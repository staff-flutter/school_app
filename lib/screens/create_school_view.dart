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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create School'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Text(
                  'Create New School',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                TextFormField(
                  controller: _schoolNameController,
                  decoration: const InputDecoration(
                    labelText: 'School Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter school name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _academicYearController,
                  decoration: const InputDecoration(
                    labelText: 'Current Academic Year',
                    border: OutlineInputBorder(),
                    helperText: 'Format: 2024-2025',
                  ),
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
                const SizedBox(height: 16),
                
                // Logo upload section
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('School Logo (Optional)'),
                      const SizedBox(height: 8),
                      Obx(() => selectedLogo.value != null
                          ? Column(
                              children: [
                                Image.file(
                                  selectedLogo.value!,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => selectedLogo.value = null,
                                  child: const Text('Remove Logo'),
                                ),
                              ],
                            )
                          : ElevatedButton.icon(
                              onPressed: _pickLogo,
                              icon: const Icon(Icons.image),
                              label: const Text('Select Logo'),
                            )),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : _createSchool,
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : const Text('Create School'),
                )),
                const SizedBox(height: 20), // Extra bottom padding
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

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
