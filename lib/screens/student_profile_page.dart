import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
// import 'student_information_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/my_children_controller.dart';
import '../controllers/school_controller.dart';
import '../constants/api_constants.dart';
import '../models/student_model.dart' show Student;

class ProfilePage extends StatefulWidget {
  final Student? student;
  final String schoolId;


  const ProfilePage({
    super.key,
    this.student,
    required this.schoolId,

  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final schoolController = Get.find<SchoolController>();

  // ── Which field is currently being edited (key = field label) ──
  final Map<String, TextEditingController> _editControllers = {};
  final Set<String> _editingFields = {};
  final Set<String> _savingFields = {};

  // ── Displayed values (what we show on screen) ──
  Map<String, String> _fieldValues = {};

  // ── Gender dropdown ──
  String? selectedGender;

  // ── Student id ──
  String _studentId = '';

  bool _isLoading = true;


  // ---------------------------------------- INIT STATE () --------------------------------------------


  @override
  void initState() {
    super.initState();
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black,
    //   statusBarIconBrightness: Brightness.light,
    // ));
    _load();
  }


  // ---------------------------------------- Cache helpers ------------------------------------------------


  String get _cacheKey => 'student_profile_$_studentId';

  Future<void> _saveToCache(Map<String, String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(values));
  }

  Future<Map<String, String>?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  // ── Load: show cache instantly, then silently refresh from API ───
  Future<void> _load() async {
    // Resolve student id first (needed for cache key)
    final childController = Get.find<MyChildrenController>();
    _studentId = childController.selectedChild['_id'] ?? '';
    print(_studentId);

    // 1. Load cache immediately — no spinner if we have data
    final cached = await _loadFromCache();
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _fieldValues = cached;
        selectedGender = cached['Gender']?.isNotEmpty == true ? cached['Gender'] : null;
        _isLoading = false;
      });
      // 2. Silently refresh from API in background
      _fetchStudentProfile(silent: true);
    } else {
      // No cache yet — show spinner until API responds
      setState(() => _isLoading = true);
      await _fetchStudentProfile(silent: false);
      setState(() => _isLoading = false);
    }

    // if (widget.isEdit && widget.student != null) _populateFromStudent(widget.student!);
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   schoolController.getAllClasses(widget.schoolId);
    // });
    if ( widget.student != null) _populateFromStudent(widget.student!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      schoolController.getAllClasses(widget.schoolId);
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  Future<void> _fetchStudentProfile({bool silent = false}) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/student/get/$_studentId');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map ? decoded['data'] : null;
        if (data is Map<String, dynamic>) {
          _mapResponseToFields(data);
          // Persist full profile to cache
          await _saveToCache(_fieldValues);
          if (silent) setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
    }
  }

  // Flatten the nested API response into our flat [_fieldValues] map.
  void _mapResponseToFields(Map<String, dynamic> data) {
    final m = data['mandatory'] as Map<String, dynamic>? ?? {};
    final n = data['nonMandatory'] as Map<String, dynamic>? ?? {};

    _fieldValues = {
      // ── Mandatory ──
      'Gender': m['gender'] ?? data['gender'] ?? '',
      'Father Name': m['fatherName'] ?? data['fatherName'] ?? '',
      'Mother Name': m['motherName'] ?? data['motherName'] ?? '',
      'Guardian Name': m['guardianName'] ?? data['guardianName'] ?? '',
      'Mobile Number': m['mobileNumber'] ?? data['mobileNumber'] ?? '',
      'Alternate Mobile': m['Alternate Mobile'] ?? data['alternateMobile'] ?? '',
      'Email': m['email'] ?? data['email'] ?? '',
      'Date of Birth': m['dob'] ?? data['dob'] ?? '',
      'Aadhaar Number': m['aadhaarNumber'] ?? data['aadhaarNumber'] ?? '',
      'Aadhaar Name': m['aadhaarName'] ?? data['aadhaarName'] ?? '',
      'Education Number': m['Education Number'] ?? data['educationNumber'] ?? '',
      'Address': m['address'] ?? data['address'] ?? '',
      'Pincode': m['pincode'] ?? data['pincode'] ?? '',
      'Mother Tongue': m['Mother Tongue'] ?? data['motherTongue'] ?? '',
      'Social Category': m['Social Category'] ?? data['socialCategory'] ?? '',
      'Minority Group': m['Minority Group'] ?? data['minorityGroup'] ?? '',
      'BPL': m['BPL'] ?? data['bpl'] ?? '',
      'AAY': m['AAY'] ?? data['aay'] ?? '',
      'EWS': m['EWS'] ?? data['ews'] ?? '',
      'CWSN': m['CWSN'] ?? data['cwsn'] ?? '',
      'Impairments': m['Impairments'] ?? data['impairments'] ?? '',
      'Indian': m['Indian'] ?? data['indian'] ?? '',
      'Out Of School': m['Out Of School'] ?? data['outOfSchool'] ?? '',
      'Mainstreamed Date': m['Mainstreamed Date'] ?? data['mainstreamedDate'] ?? '',
      'Disability Certificate': m['Disability Certificate'] ?? data['disabilityCert'] ?? '',
      'Disability Percent': m['Disability Percent'] ?? data['disabilityPercent'] ?? '',
      'Blood Group': m['bloodGroup'] ?? data['bloodGroup'] ?? '',

      // ── UDISE / Non-mandatory ──
      'Facilities Provided': n['Facilities Provided'] ?? '',
      'Facilities For CWSN': n['Facilities For CWSN'] ?? '',
      'Screened For SLD': n['Screened For SLD'] ?? '',
      'SLD Type': n['SLD Type'] ?? '',
      'Screened for ASD': n['Screened for ASD'] ?? '',
      'Screened for ADHD': n['Screened for ADHD'] ?? '',
      'Gifted Talented': n['Gifted Talented'] ?? '',
      'Participated in Competitions': n['Participated in Competitions'] ?? '',
      'Participated in Activities': n['Participated in Activities'] ?? '',
      'Can Handle Digital Devices': n['Can Handle Digital Devices'] ?? '',
      'Height (cm)': n['heightInCm'] ?? '',
      'Weight (Kg)': n['weightInKg'] ?? '',
      'Distance to School': n['Distance to School'] ?? '',
      'Parent Education Level': n['Parent Education Level'] ?? '',
      'Admission Number': n['admissionNumber'] ?? '',
      'Admission Date': n['Admission Date'] ?? '',
      'Roll Number': n['Roll Number'] ?? '',
      'Medium of Instruction': n['Medium of Instruction'] ?? '',
      'Languages Studied': n['Languages Studied'] ?? '',
      'Academic Stream': n['Academic Stream'] ?? '',
      'Subjects Studied': n['Subject Studied'] ?? '',
      'Status in Previous Year': n['Status in Previous Year'] ?? '',
      'Grade Studied Last Year': n['Grade Studied Last Year'] ?? '',
      'Enrolled Under': n['Enrolled Under'] ?? '',
      'Previous Result': n['Previous Result'] ?? '',
      'Marks List': n['Marks List'] ?? '',
      'Days Attended Last Year': n['Days Attended Last Year'] ?? '',
    };

    selectedGender = _fieldValues['Gender']!.isNotEmpty ? _fieldValues['Gender'] : null;
  }

  void _populateFromStudent(Student student) {
    // Called when student object is passed directly (offline / cached)
    _fieldValues['Gender'] = student.gender ?? '';
    _fieldValues['Father Name'] = student.fatherName ?? '';
    _fieldValues['Mother Name'] = student.motherName ?? '';
    _fieldValues['Guardian Name'] = student.guardianName ?? '';
    _fieldValues['Mobile Number'] = student.mobileNumber ?? '';
    _fieldValues['Alternate Mobile'] = student.alternateMobile ?? '';
    _fieldValues['Email'] = student.email ?? '';
    _fieldValues['Date of Birth'] = student.dob ?? '';
    _fieldValues['Aadhaar Number'] = student.aadhaarNumber ?? '';
    _fieldValues['Aadhaar Name'] = student.aadhaarName ?? '';
    _fieldValues['Education Number'] = student.educationNumber ?? '';
    _fieldValues['Address'] = student.address ?? '';
    _fieldValues['Pincode'] = student.pincode ?? '';
    _fieldValues['Mother Tongue'] = student.motherTongue ?? '';
    _fieldValues['Social Category'] = student.socialCategory ?? '';
    _fieldValues['Minority Group'] = student.minorityGroup ?? '';
    _fieldValues['BPL'] = student.bpl ?? '';
    _fieldValues['AAY'] = student.aay ?? '';
    _fieldValues['EWS'] = student.ews ?? '';
    _fieldValues['CWSN'] = student.cwsn ?? '';
    _fieldValues['Impairments'] = student.impairments ?? '';
    _fieldValues['Indian'] = student.indian ?? '';
    _fieldValues['Out Of School'] = student.outOfSchool ?? '';
    _fieldValues['Mainstreamed Date'] = student.mainstreamedDate ?? '';
    _fieldValues['Disability Certificate'] = student.disabilityCert ?? '';
    _fieldValues['Disability Percent'] = student.disabilityPercent ?? '';
    _fieldValues['Blood Group'] = student.bloodGroup ?? '';
    selectedGender = student.gender;
  }

  // ── Per-field save ───────────────────────────────────────────────
  Future<void> _saveField(String label, String newValue) async {
    setState(() => _savingFields.add(label));

    final token = await _getToken();
    final url = Uri.parse('https://bmbbackend.com/api/student/update/$_studentId');

    // Map label → API key & section
    final apiKey = _labelToApiKey(label);
    final section = _mandatoryLabels.contains(label) ? 'mandatory' : 'nonMandatory';

    final body = {section: {apiKey: newValue}};

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        setState(() {
          _fieldValues[label] = newValue;
          if (label == 'Gender') selectedGender = newValue;
          _editingFields.remove(label);
          _editControllers[label]?.dispose();
          _editControllers.remove(label);
        });
        // Persist the full updated map to cache
        await _saveToCache(_fieldValues);
        _showSnack('✓ $label updated', Colors.green);
      }
      else {
        _showSnack('Failed to update $label', Colors.red);
      }
    } catch (e) {
      _showSnack('Connection error', Colors.red);
    } finally {
      setState(() => _savingFields.remove(label));
    }
  }

  void _showSnack(String msg, Color color) {
    if (color == Colors.red) return;
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      '',
      msg,
      titleText: const SizedBox.shrink(),
      messageText: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  // ── Label → API key mapping ──────────────────────────────────────
  static const Set<String> _mandatoryLabels = {
    'Gender', 'Father Name', 'Mother Name', 'Guardian Name', 'Mobile Number',
    'Alternate Mobile', 'Email', 'Date of Birth', 'Aadhaar Number', 'Aadhaar Name',
    'Education Number', 'Address', 'Pincode', 'Mother Tongue', 'Social Category',
    'Minority Group', 'BPL', 'AAY', 'EWS', 'CWSN', 'Impairments', 'Indian',
    'Out Of School', 'Mainstreamed Date', 'Disability Certificate',
    'Disability Percent', 'Blood Group',
  };

  String _labelToApiKey(String label) {
    const map = {
      'Gender': 'gender',
      'Father Name': 'fatherName',
      'Mother Name': 'motherName',
      'Guardian Name': 'guardianName',
      'Mobile Number': 'mobileNumber',
      'Alternate Mobile': 'Alternate Mobile',
      'Email': 'email',
      'Date of Birth': 'dob',
      'Aadhaar Number': 'aadhaarNumber',
      'Aadhaar Name': 'aadhaarName',
      'Education Number': 'Education Number',
      'Address': 'address',
      'Pincode': 'pincode',
      'Mother Tongue': 'Mother Tongue',
      'Social Category': 'Social Category',
      'Minority Group': 'Minority Group',
      'BPL': 'BPL',
      'AAY': 'AAY',
      'EWS': 'EWS',
      'CWSN': 'CWSN',
      'Impairments': 'Impairments',
      'Indian': 'Indian',
      'Out Of School': 'Out Of School',
      'Mainstreamed Date': 'Mainstreamed Date',
      'Disability Certificate': 'Disability Certificate',
      'Disability Percent': 'Disability Percent',
      'Blood Group': 'bloodGroup',
      'Facilities Provided': 'Facilities Provided',
      'Facilities For CWSN': 'Facilities For CWSN',
      'Screened For SLD': 'Screened For SLD',
      'SLD Type': 'SLD Type',
      'Screened for ASD': 'Screened for ASD',
      'Screened for ADHD': 'Screened for ADHD',
      'Gifted Talented': 'Gifted Talented',
      'Participated in Competitions': 'Participated in Competitions',
      'Participated in Activities': 'Participated in Activities',
      'Can Handle Digital Devices': 'Can Handle Digital Devices',
      'Height (cm)': 'heightInCm',
      'Weight (Kg)': 'weightInKg',
      'Distance to School': 'Distance to School',
      'Parent Education Level': 'Parent Education Level',
      'Admission Number': 'admissionNumber',
      'Admission Date': 'Admission Date',
      'Roll Number': 'Roll Number',
      'Medium of Instruction': 'Medium of Instruction',
      'Languages Studied': 'Languages Studied',
      'Academic Stream': 'Academic Stream',
      'Subjects Studied': 'Subject Studied',
      'Status in Previous Year': 'Status in Previous Year',
      'Grade Studied Last Year': 'Grade Studied Last Year',
      'Enrolled Under': 'Enrolled Under',
      'Previous Result': 'Previous Result',
      'Marks List': 'Marks List',
      'Days Attended Last Year': 'Days Attended Last Year',
    };
    return map[label] ?? label;
  }


  // ------------------------------------------------ BUILD METHOD ---------------------------------------


  @override
  Widget build(BuildContext context) {
    final childController = Get.find<MyChildrenController>();
    final String studentName = childController.selectedChild['studentName'] ?? 'Student';
    final String studentImageUrl =
        childController.selectedChild['studentImage']?['url'] ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
        Get.back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // white icons
          statusBarBrightness: Brightness.dark,       // iOS
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFEEF3FB),
          body: Stack(
            children: [


                    // ------------------------------------------ FOOTER IMAGE --------------------------------------------


              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Image.asset(
                  'assets/images/Blue science and education collection footer.png',
                  fit: BoxFit.cover,
                ),
              ),

              Positioned.fill(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SafeArea(
                        top: false,
                        bottom: true,
                        child: SingleChildScrollView(
                                        child: Column(
                      children: [
                        // ── Header ──
                        _buildHeader(studentName, studentImageUrl),

                        const SizedBox(height: 75),

                        Text(
                          '$studentName Profile',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Divider
                        Container(
                          width: 120,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.shade400,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),


                       // ---------------------------------- MANDATORY SECTION --------------------------------------------


                        _buildSection(
                          title: 'Mandatory Information',
                          icon: Icons.info_outline,
                          labels: [
                            'Gender',
                            'Father Name',
                            'Mother Name',
                            'Guardian Name',
                            'Mobile Number',
                            'Alternate Mobile',
                            'Email',
                            'Date of Birth',
                            'Aadhaar Number',
                            'Aadhaar Name',
                            'Education Number',
                            'Address',
                            'Pincode',
                            'Mother Tongue',
                            'Social Category',
                            'Minority Group',
                            'BPL',
                            'AAY',
                            'EWS',
                            'CWSN',
                            'Impairments',
                            'Indian',
                            'Out Of School',
                            'Mainstreamed Date',
                            'Disability Certificate',
                            'Disability Percent',
                            'Blood Group',
                          ],
                        ),


                      // ------------------------------------ UDISE SECTION ---------------------------------------------


                        _buildSection(
                          title: 'UDISE',
                          icon: Icons.description_outlined,
                          labels: [
                            'Facilities Provided',
                            'Facilities For CWSN',
                            'Screened For SLD',
                            'SLD Type',
                            'Screened for ASD',
                            'Screened for ADHD',
                            'Gifted Talented',
                            'Participated in Competitions',
                            'Participated in Activities',
                            'Can Handle Digital Devices',
                            'Height (cm)',
                            'Weight (Kg)',
                            'Distance to School',
                            'Parent Education Level',
                            'Admission Number',
                            'Admission Date',
                            'Roll Number',
                            'Medium of Instruction',
                            'Languages Studied',
                            'Academic Stream',
                            'Subjects Studied',
                            'Status in Previous Year',
                            'Grade Studied Last Year',
                            'Enrolled Under',
                            'Previous Result',
                            'Marks List',
                            'Days Attended Last Year',
                          ],
                        ),
                        SizedBox(height: 30,),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xff4A90E2), Color(0xff6FD3F7)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent, // Remove shadow if you want a flat look
                            ),
                            onPressed: () {
                              _showSnack("You're child Form is submitted for verification ", Colors.green);
                            }, child: Text('Submit For Verification',style: TextStyle(color: Colors.white),),
                           ),
                        ),

                        const SizedBox(height: 40),
                      ],
                                        ),
                                      ),
                    ),
              ),
            ],
          ),
        ),
      ), // Scaffold
    ); // PopScope
  }


  // ------------------------------------------------ BUILD HEADER METHOD ---------------------------------


  Widget _buildHeader(String studentName, String imageUrl) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: HeaderClipper(),
          child: Container(
            height: 250,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff4A90E2), Color(0xff6FD3F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Image.asset(
            'assets/images/Scientific UI background design header.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // ------------------------------------ SECTION CARD -------------------------------------------


  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> labels,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: ExpansionTile(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: const Color(0xFF4F6DB8),size: 15,),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.black, fontSize: 13),
          ),
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          children: labels.map((label) => _buildFieldRow(label)).toList(),
        ),
      ),
    );
  }

  // ── Field row: read-only OR editable ────────────────────────────
  Widget _buildFieldRow(String label) {
    final isEditing = _editingFields.contains(label);
    final isSaving = _savingFields.contains(label);
    final value = _fieldValues[label] ?? '';

    // Special: Gender dropdown
    if (label == 'Gender') {
      return _buildGenderRow(isSaving);
    }

    // Special: Date of Birth
    if (label == 'Date of Birth') {
      return _buildDateRow(label, value, isEditing, isSaving);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isEditing ? const Color(0xffF0F6FF) : const Color(0xffF1F4F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEditing ? const Color(0xff4A90E2) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: isEditing
                    ? TextField(
                  controller: _editControllers[label],
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(
                      color: Color(0xff4A90E2),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 15),
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.isNotEmpty ? value : '—',
                      style: TextStyle(
                        fontSize: 15,
                        color: value.isNotEmpty
                            ? Colors.black87
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ── Action button ──
              if (isSaving)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isEditing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cancel
                    GestureDetector(
                      onTap: () => setState(() {
                        _editingFields.remove(label);
                        _editControllers[label]?.dispose();
                        _editControllers.remove(label);
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Save
                    GestureDetector(
                      onTap: () => _saveField(
                        label,
                        _editControllers[label]?.text ?? '',
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xff4A90E2), Color(0xff6FD3F7)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                )
              else
              // Edit pencil
                GestureDetector(
                  onTap: () {
                    final tc = TextEditingController(text: value);
                    setState(() {
                      _editControllers[label] = tc;
                      _editingFields.add(label);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xff4A90E2).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Color(0xff4A90E2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gender field row ─────────────────────────────────────────────
  Widget _buildGenderRow(bool isSaving) {
    final isEditing = _editingFields.contains('Gender');
    final value = _fieldValues['Gender'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isEditing ? const Color(0xffF0F6FF) : const Color(0xffF1F4F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEditing ? const Color(0xff4A90E2) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: isEditing
                    ? DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedGender,
                    isExpanded: true,
                    hint: const Text('Select Gender'),
                    items: ['Male', 'Female', 'Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedGender = v),
                  ),
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.isNotEmpty ? value : '—',
                      style: TextStyle(
                        fontSize: 15,
                        color: value.isNotEmpty
                            ? Colors.black87
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSaving)
                const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isEditing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        _editingFields.remove('Gender');
                        selectedGender = _fieldValues['Gender'];
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _saveField('Gender', selectedGender ?? ''),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xff4A90E2), Color(0xff6FD3F7)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: () => setState(() => _editingFields.add('Gender')),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xff4A90E2).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Color(0xff4A90E2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Date of Birth row ────────────────────────────────────────────
  Widget _buildDateRow(String label, String value, bool isEditing, bool isSaving) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isEditing ? const Color(0xffF0F6FF) : const Color(0xffF1F4F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEditing ? const Color(0xff4A90E2) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.isNotEmpty ? value : '—',
                      style: TextStyle(
                        fontSize: 15,
                        color: value.isNotEmpty ? Colors.black87 : Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSaving)
                const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      final formatted =
                          '${picked.day}/${picked.month}/${picked.year}';
                      await _saveField(label, formatted);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xff4A90E2).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Color(0xff4A90E2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  // ------------------------------------------- DISPOSE METHOD ---------------------------------------------



  @override
  void dispose() {
    for (final tc in _editControllers.values) {
      tc.dispose();
    }
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────
//  HeaderClipper
// ─────────────────────────────────────────────────────────────────
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}