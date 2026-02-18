import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditSchoolView extends StatefulWidget {
  final Map<String, dynamic> schoolData;

  const EditSchoolView({Key? key, required this.schoolData}) : super(key: key);

  @override
  State<EditSchoolView> createState() => _EditSchoolViewState();
}

class _EditSchoolViewState extends State<EditSchoolView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _academicYearController;
  late TextEditingController _logoController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.schoolData['name'] ?? '');
    _emailController = TextEditingController(text: widget.schoolData['email'] ?? '');
    _phoneController = TextEditingController(text: widget.schoolData['phoneNo']?.toString() ?? '');
    _addressController = TextEditingController(text: widget.schoolData['address'] ?? '');
    _academicYearController = TextEditingController(text: widget.schoolData['currentAcademicYear'] ?? '');
    _logoController = TextEditingController(text: widget.schoolData['logo'] ?? '');
    _isActive = widget.schoolData['isActive'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _academicYearController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit School'),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'School Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty == true) return 'Email is required';
                if (!GetUtils.isEmail(value!)) return 'Invalid email format';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty == true ? 'Phone number is required' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty == true ? 'Address is required' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _academicYearController,
              decoration: const InputDecoration(
                labelText: 'Current Academic Year',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _logoController,
              decoration: const InputDecoration(
                labelText: 'Logo URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Active Status'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 24),
            
            const Text('Read-only Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: widget.schoolData['schoolCode'] ?? '',
              decoration: InputDecoration(
                labelText: 'School Code',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey,
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: widget.schoolData['createdAt'] ?? '',
              decoration: InputDecoration(
                labelText: 'Created At',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey,
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: widget.schoolData['updatedAt'] ?? '',
              decoration: const InputDecoration(
                labelText: 'Updated At',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey,
              ),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phoneNo': _phoneController.text,
        'address': _addressController.text,
        'currentAcademicYear': _academicYearController.text.isEmpty ? null : _academicYearController.text,
        'logo': _logoController.text.isEmpty ? null : _logoController.text,
        'isActive': _isActive,
      };
      
      Get.back(result: updatedData);
      Get.snackbar('Success', 'School information updated');
    }
  }
}