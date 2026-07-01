import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../controllers/marks_controller.dart';
import '../controllers/student_record_controller.dart';
import '../core/utils/academic_year_utils.dart';
import '../core/utils/class_utils.dart';
import '../constants/api_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/school_controller.dart';
import '../controllers/student_controller.dart'hide Student;
import '../models/school_models.dart';
import '../services/api_service.dart';
import '../models/student_model.dart' ;
import 'package:school_app/controllers/bill_admission_controller.dart';


// Make sure these match your actual import paths for your project controllers!
// import 'package:your_app/controllers/auth_controller.dart';
// import 'package:your_app/controllers/school_controller.dart';
// import 'package:your_app/services/api_service.dart';

// ─── Design System Bridge ───────────────────────────────────────────────────
class _DS {
  static const primary = Color(0xFF2563EB);
  static const accent = Color(0xFF2563EB);
  static const accentSoft = Color(0xFFE0F2FE);
  static const primaryDark = Color(0xFF0284C7);
  static const primarySoft = Color(0xFFE0F2FE);
  static const bg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const border = Color(0xFFE2E8F0);

  static const radius = 16.0;
  static const radiusSm = 10.0;
  static const radiusLg = 24.0;

  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 24.0;
}

class _Responsive {
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 900;
  static double padding(BuildContext context) => isTablet(context) ? _DS.spacingXl : _DS.spacingLg;
}



class AppTheme {
  static const errorRed = _DS.danger;
}

// ─── MAIN STUDENT PROFILE VIEW ──────────────────────────────────────────────
class StudentDetailView extends StatefulWidget {
  const StudentDetailView({Key? key}) : super(key: key);

  @override
  State<StudentDetailView> createState() => _StudentDetailViewState();
}

class _StudentDetailViewState extends State<StudentDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final MarksController _marksController = Get.find<MarksController>();

  final StudentRecordController _studentRecordController = Get.find<StudentRecordController>();

  List<Map<String, dynamic>> _studentDocuments = [];
  String? _profileImageUrl;
  bool _isLoadingDocuments = false;
  bool _documentsFetched = false;
  List<Map<String, dynamic>> _examPerformance = []; // {examName, percentage, grade, isAbsent}
  bool _isLoadingAcademics = false;
  bool _academicsFetched = false;
  // ─── CRITICAL FIX: Explicit typed lookups replace find<dynamic>() ───────────
  final AuthController _authController = Get.find<AuthController>();
  final SchoolController _schoolController = Get.find<SchoolController>();
  final BillAdmissionController _admissionController = Get.find<BillAdmissionController>();

  Map<String, dynamic>? _admissionFormData;
  bool _isLoadingAdmission = false;
  bool _admissionFetched = false;
  final ApiService _apiService = Get.find<ApiService>();
  final selectedClass = Rxn<SchoolClass>();
  final selectedSection = Rxn<Section>();
  final selectedStudent = Rxn<Student>();

// Flag tracking if the workflow has progressed to a completed student selection
  bool get _hasSearched => selectedStudent.value != null;
  String _studentId = '';
  String? _resolvedSchoolId;
  bool _isLoadingProfile = false;
  bool _hasSearched1 = false;
  final Map<String, String> _fieldValues = {};

  bool _isLoadingFee = false;
  Map<String, int> _feeStructure = {};
  Map<String, int> _feePaid = {};
  Map<String, int> _feeDues = {};
  bool _feeFetched = false;

  // Dynamic Class List States
  final RxBool isLoadingClasses = false.obs;
  final RxList<SchoolClass> classes = <SchoolClass>[].obs;
  final RxBool isLoading = false.obs; // Maps to your response parser line requirements
  int _selectedFilterIndex = 0;
  String _currentSelectedClassName = 'Not Assigned';

  final List<Map<String, String>> _recentSearches = [
    {'id': '24012', 'name': 'Sai Arjun', 'class': 'Class 10'},
    {'id': '23891', 'name': 'Priya Sharma', 'class': 'Class 9'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Auto-fetch target school details on init context
    _resolveAndFetchSchoolClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resolveAndFetchSchoolClasses() {
    final role = _authController.user.value?.role?.toLowerCase() ?? '';
    String? schoolId;

    if (role == 'correspondent') {
      schoolId = _schoolController.selectedSchool.value?.id;
    } else {
      schoolId = _authController.user.value?.schoolId;
    }

    _resolvedSchoolId = schoolId;   // ← store it

    if (schoolId != null && schoolId.isNotEmpty) {
      getAllClasses(schoolId);
    } else {
      _showSnackbar('Configuration Error', 'Unable to resolve school operational workspace Context.', _DS.warning);
    }
  }



  // ─── YOUR REFACTORED API INTEGRATION ROUTINE ──────────────────────────────
  Future<void> getAllClasses(String schoolId) async {
    try {
      isLoading.value = true;
      isLoadingClasses.value = true;

      final response = await _apiService.get('${ApiConstants.getAllClasses}/$schoolId');

      if (response.data['ok'] == true) {
        final classList = response.data['data'] as List;

        final uniqueClasses = <SchoolClass>[];
        final seenIds = <String>{};

        for (var json in classList) {
          final schoolClass = SchoolClass.fromJson(json);
          if (!seenIds.contains(schoolClass.id)) {
            seenIds.add(schoolClass.id);
            uniqueClasses.add(schoolClass);
          }
        }

        uniqueClasses.sort((a, b) => _compareClassNames(a.name, b.name));
        classes.value = uniqueClasses;
        update();
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load classes', AppTheme.errorRed);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        classes.value = [];
        String errorMessage = 'You do not have permission to access classes';
        if (e.response?.data != null && e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? errorMessage;
        }
        _showSnackbar('Access Denied', errorMessage, AppTheme.errorRed);
        return;
      }
      _showSnackbar('Error', 'An error occurred while loading classes.', AppTheme.errorRed);
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while loading classes.', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
      isLoadingClasses.value = false;
    }
  }

  int _compareClassNames(String a, String b) {
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  void _showSnackbar(String title, String message, Color color) {
    Get.snackbar(title, message, backgroundColor: color.withOpacity(0.1), colorText: color);
  }

  void update() {
    if (mounted) setState(() {});
  }

  String? _getToken() => _authController.storage.read('token');
  Future<void> _fetchStudentProfile({String? fallbackQuery}) async {
    final query = fallbackQuery ?? _studentId.trim();
    print('studentid: $_studentId');
    if (query.isEmpty) {
      _showSnackbar('Empty Input', 'Please enter a value parameter to search.', _DS.warning);
      return;
    }

    setState(() {
      _isLoadingProfile = true;
      if (fallbackQuery != null) _searchController.text = fallbackQuery;
    });

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/student/get/$query');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer ${_getToken()}',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('response: ${response.body}');
        _showSnackbar('Query Issue', 'No verified student profile matches criteria.', _DS.danger);

        // 🚀 Safely clear fields to avoid showing previous student's info on error
        _clearFieldsToEmpty();
        return;
      }

      final decoded = jsonDecode(response.body);
      Map<String, dynamic> doc = decoded['data'] ?? decoded['student'] ?? decoded;
      final Map<String, dynamic> m = doc['mandatory'] ?? {};
      final Map<String, dynamic> n = doc['nonMandatory'] ?? {};

      final rawDocs = (doc['documents'] as List?) ?? [];
      final parsedDocs = rawDocs
          .whereType<Map>()
          .map((d) => Map<String, dynamic>.from(d))
          .toList();

      final studentImageMap = doc['studentImage'] as Map<String, dynamic>?;
      final profileImageUrl = studentImageMap?['url']?.toString();
      // Helper to read nested values safely without catching null or string 'null' literals
      String v(String key) {
        for (final src in [m, n, doc]) {
          if (src[key] != null && src[key].toString().isNotEmpty && src[key].toString() != 'null') {
            return src[key].toString();
          }
        }
        return '';
      }

      if (mounted) {
        setState(() {
          _hasSearched1 = true;
          _studentDocuments = parsedDocs;
          _profileImageUrl = profileImageUrl;
          // ─── MANDATORY CORES ─────────────────────────────────────────────────
          // Name defaults to 'Unknown Student' if missing entirely
          final rawName = v('studentName').isNotEmpty ? v('studentName') : v('aadhaarName');
          _fieldValues['Student Name'] = rawName.isNotEmpty ? rawName : 'Unknown Student';
          _fieldValues['Aadhaar Name'] = v('aadhaarName');
          _fieldValues['Admission Number'] = v('admissionNumber');
          _fieldValues['Aadhaar Number'] = v('aadhaarNumber');
          _fieldValues['Roll Number'] = v('rollNumber');
          _fieldValues['Date of Birth'] = v('dob');
          _fieldValues['Gender'] = v('gender');
          _fieldValues['Blood Group'] = v('bloodGroup');
          _fieldValues['Mother Tongue'] = v('motherTongue');
          _fieldValues['Religion'] = v('religion');
          _fieldValues['Caste'] = v('caste');
          _fieldValues['Subcaste'] = v('subcaste');

          // Parent Information
          _fieldValues['Father Name'] = v('fatherName');
          _fieldValues['Mother Name'] = v('motherName');
          _fieldValues['Guardian Name'] = v('guardianName');
          _fieldValues['Mobile Number'] = v('mobileNumber');
          _fieldValues['Alternative Mobile'] = v('alternativeMobile');

          // Address Setup
          _fieldValues['Address'] = v('address');
          _fieldValues['Pincode'] = v('pincode');

          // ─── NON-MANDATORY (UDISE COMPLIANT FIELDS) ──────────────────────────
          _fieldValues['UDISE Number'] = v('udiseNumber');
          _fieldValues['PEN Number'] = v('penNumber'); // Permanent Education Number
          _fieldValues['Height (cm)'] = v('height');
          _fieldValues['Weight (kg)'] = v('weight');
          _fieldValues['Bank Account No'] = v('bankAccountNo');
          _fieldValues['Bank IFSC'] = v('ifscCode');
          _fieldValues['Ration Card Type'] = v('rationCardType');
          _fieldValues['Ration Card No'] = v('rationCardNumber');
          _fieldValues['Belongs to BPL'] = v('bplStatus');
          _fieldValues['Disability Type'] = v('disabilityType');

          // Context structural UI updates
          _currentSelectedClassName = v('className').isNotEmpty ? v('className') : 'Not Assigned';
        });
      }
    } catch (e) {
      print("Error mapping profile properties: $e");
      _clearFieldsToEmpty();
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }
  String _gradeLabel(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 75) return 'A';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 35) return 'D';
    return 'F';
  }

  Future<void> _fetchAcademicPerformance() async {
    if (selectedStudent.value == null || _resolvedSchoolId == null) return;
    setState(() => _isLoadingAcademics = true);

    try {
      final reports = await _marksController.getAllMarkReports(
        schoolId: _resolvedSchoolId!,
        classId: selectedClass.value?.id ?? '',
        sectionId: selectedSection.value?.id,
        studentId: selectedStudent.value!.id,
      );

      final List<Map<String, dynamic>> performance = [];

      for (final doc in reports) {
        final examRecords = (doc['examRecords'] as List?) ?? [];
        for (final raw in examRecords) {
          final exam = raw as Map<String, dynamic>;
          final subjects = (exam['subjects'] as List?) ?? [];
          final isAbsent = exam['isAbsent'] as bool? ?? false;

          int scored = 0, max = 0;
          for (final s in subjects) {
            final sub = s as Map<String, dynamic>;
            scored += ((sub['marksObtained'] as num?) ?? 0).toInt();
            max += ((sub['maxMarks'] as num?) ?? 100).toInt();
          }
          final pct = (max > 0 && !isAbsent) ? (scored / max * 100) : 0.0;

          performance.add({
            'examName': exam['examName']?.toString() ?? 'Exam',
            'percentage': pct,
            'grade': isAbsent ? '-' : _gradeLabel(pct),
            'isAbsent': isAbsent,
          });
        }
      }

      if (mounted) {
        setState(() {
          _examPerformance = performance;
          _academicsFetched = true;
        });
      }
    } catch (e) {
      debugPrint('Academic performance fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAcademics = false);
    }
  }
  Future<void> _fetchFeeDetails() async {
    if (selectedStudent.value == null) return;
    setState(() => _isLoadingFee = true);

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/api/studentrecord/v1/getrecord/$_resolvedSchoolId/${selectedStudent.value!.id}',
    );

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer ${_getToken()}',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        if (data != null) {
          Map<String, int> toIntMap(Map<String, dynamic>? raw) {
            if (raw == null) return {};
            return raw.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
          }
          setState(() {
            _feeStructure = toIntMap(data['feeStructurev1'] ?? data['feeStructure']);
            _feePaid = toIntMap(data['feePaidv1'] ?? data['feePaid']);
            _feeDues = toIntMap(data['duesv1'] ?? data['dues']);
            _feeFetched = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Fee fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFee = false);
    }
  }
// ─── HELPER TO SAFELY ZERO OUT WORKSPACE ON EXCEPTION/EMPTY STATES ───────────
  void _clearFieldsToEmpty() {
    if (!mounted) return;
    setState(() {
      _hasSearched1 = true;
      _fieldValues['Student Name'] = 'Unknown Student';
      _currentSelectedClassName = 'Not Assigned';

      // Clear all other map elements to empty strings
      final keysToClear = [
        'Aadhaar Name', 'Admission Number', 'Aadhaar Number', 'Roll Number',
        'Date of Birth', 'Gender', 'Blood Group', 'Mother Tongue', 'Religion',
        'Caste', 'Subcaste', 'Father Name', 'Mother Name', 'Guardian Name',
        'Mobile Number', 'Alternative Mobile', 'Address', 'Pincode',
        'UDISE Number', 'PEN Number', 'Height (cm)', 'Weight (kg)',
        'Bank Account No', 'Bank IFSC', 'Ration Card Type', 'Ration Card No',
        'Belongs to BPL', 'Disability Type'
      ];

      for (var key in keysToClear) {
        _fieldValues[key] = '';
      }
    });
  }
  Future<void> _fetchAdmissionForm() async {
    if (selectedStudent.value == null) return;
    setState(() {
      _isLoadingAdmission = true;
      _admissionFetched = false;
    });

    final data = await _admissionController.getSingleAdmissionForm(
      studentId:'$_studentId',
    );
    print('stuentiddd:$_studentId');

    if (mounted) {
      setState(() {
        _admissionFormData = data;
        _isLoadingAdmission = false;
        _admissionFetched = true;
      });
    }
  }
  Future<void> _fetchStudentDocuments() async {
    if (selectedStudent.value == null || _resolvedSchoolId == null) return;
    setState(() => _isLoadingDocuments = true);

    try {
      final data = await _studentRecordController.getStudentRecord(
        _resolvedSchoolId!,
        selectedStudent.value!.id,
        academicYear: AcademicYearUtils.getCurrentAcademicYear(),
      );

      print('📄 getStudentRecord raw response: $data');   // ← add this

      if (data != null && mounted) {
        final rawDocs = (data['documents'] as List?) ?? (data['files'] as List?) ?? [];
        final jsonStr = data.toString();
        const chunkSize = 800;
        for (var i = 0; i < jsonStr.length; i += chunkSize) {
          print('📄 CHUNK: ${jsonStr.substring(i, i + chunkSize > jsonStr.length ? jsonStr.length : i + chunkSize)}');
        }        setState(() {
          _studentDocuments = rawDocs.map((d) => d as Map<String, dynamic>).toList();
          final studentObj = data['studentId'] as Map<String, dynamic>?;
          final studentImage = studentObj?['studentImage'] as Map<String, dynamic>?;
          _profileImageUrl = studentImage?['url']?.toString();
          _documentsFetched = true;
        });
        final studentImage = data['studentImage'] as Map<String, dynamic>?;
        setState(() {
          _profileImageUrl = studentImage?['url']?.toString();
          _studentDocuments = []; // confirmed: this endpoint has no documents array
          _documentsFetched = true;
        });
      } else if (mounted) {
        print('📄 getStudentRecord returned null');   // ← add this
        setState(() => _documentsFetched = true);
      }
    } catch (e) {
      debugPrint('Document fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDocuments = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final isTablet = _Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: _DS.bg,
      body: SafeArea(
        child: Obx(() {
          final showMasterProgress = _isLoadingProfile || isLoadingClasses.value;
          return Column(
            children: [
              // ── TOP WORKFLOW FILTER BAR (Designed exactly like SchoolManagementView) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    // 1. Class Selection Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showClassFilterSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedClass.value != null ? _DS.accentSoft : _DS.surface,
                            borderRadius: BorderRadius.circular(_DS.radiusSm),
                            border: Border.all(
                              color: selectedClass.value != null ? _DS.accent : _DS.border,
                              width: selectedClass.value != null ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.class_rounded, size: 16, color: selectedClass.value != null ? _DS.accent : _DS.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedClass.value?.name ?? 'Select Class',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selectedClass.value != null ? _DS.textPrimary : _DS.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, color: _DS.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 2. Section Selection Button (Only enabled if Class is selected)
                    Expanded(
                      child: GestureDetector(
                        onTap: selectedClass.value == null ? null : () => _showSectionFilterSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedSection.value != null ? _DS.accentSoft : (selectedClass.value == null ? _DS.surfaceAlt : _DS.surface),
                            borderRadius: BorderRadius.circular(_DS.radiusSm),
                            border: Border.all(
                              color: selectedSection.value != null ? _DS.accent : _DS.border,
                              width: selectedSection.value != null ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.group_rounded, size: 16, color: selectedSection.value != null ? _DS.accent : _DS.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedSection.value?.name ?? 'Select Section',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selectedSection.value != null
                                        ? _DS.textPrimary
                                        : (selectedClass.value == null ? _DS.textMuted : _DS.textSecondary),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, color: _DS.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (showMasterProgress)
                const LinearProgressIndicator(backgroundColor: _DS.primarySoft, color: _DS.primary, minHeight: 3),

              // ── STEP DRIVEN BODY CONTENT ──
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (_schoolController.selectedSchool.value != null) {
                      await _schoolController.getAllClasses(_schoolController.selectedSchool.value!.id);
                    }
                  },
                  color: _DS.accent,
                  child: Obx(() {
                    if (!_hasSearched) {
                      // Display either the list of students if a section is picked, or a selection prompt
                      return _buildSelectionPromptOrStudentList(context);
                    }

                    // Student selected -> Load Tab Layout Details Page
                    return Column(
                      children: [
                        _buildProfileHeroHeader(context, isTablet),
                        Container(
                          width: double.infinity,
                          color: _DS.surface,
                          padding: EdgeInsets.symmetric(
                            vertical: _DS.spacingSm,
                            horizontal: _Responsive.padding(context),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildTabBar(context),
                          ),
                        ),
                        const Divider(height: 1, color: _DS.border),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildBioTab(context),
                              _buildFeeDetailsTab(context),
                              _buildAdmissionFormTab(context),
                              _buildDocumentsTab(context),
                              _buildAcademicsTab(context),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─── ADMIN SEARCH BAR & CHIPS ──────────────────────────────────────────────
  Widget _buildAdminSearchBarAndFilterSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(_Responsive.padding(context), _DS.spacingLg, _Responsive.padding(context), _DS.spacingSm),
      decoration: BoxDecoration(
      border: const Border(bottom: BorderSide(color: _DS.border)),color: _DS.surface,),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Student Directory Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _DS.textPrimary, letterSpacing: -0.4)),
              if (_hasSearched)
                TextButton.icon(
                  onPressed: () => setState(() { _hasSearched1 = false; _searchController.clear(); _fieldValues.clear(); }),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: _DS.textSecondary),
                )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(color: _DS.surfaceAlt, borderRadius: BorderRadius.circular(_DS.radiusSm)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _studentId = val,
                    onSubmitted: (_) => _fetchStudentProfile(),
                    style: const TextStyle(fontSize: 14, color: _DS.textPrimary, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, color: _DS.textSecondary, size: 20),
                      hintText: 'Enter student ID or name query...',
                      hintStyle: TextStyle(fontSize: 13, color: _DS.textMuted, fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DS.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusSm)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: () => _fetchStudentProfile(),
                  child: const Text('Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: classes.length + 1,
              itemBuilder: (context, index) {
                final isAllChip = index == 0;
                final isSelected = _selectedFilterIndex == index;
                final labelText = isAllChip ? 'All Classes' : classes[index - 1].name;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(labelText),
                    selected: isSelected,
                    selectedColor: _DS.primary,
                    backgroundColor: _DS.surfaceAlt,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : _DS.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(color: isSelected ? _DS.primary : Colors.transparent),
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                      if (!isAllChip) {
                        debugPrint('Filter selected class ID: ${classes[index - 1].id}');
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── HERO HEADER COMPONENT ────────────────────────────────────────────────
  Widget _buildProfileHeroHeader(BuildContext context, bool isTablet) {
    final displayName = _fieldValues['Student Name'] ?? 'Unknown Student';
    final displayRoll = _fieldValues['Roll Number'] ?? _fieldValues['Admission Number'] ?? _studentId;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_DS.primary, _DS.primaryDark],
        ),
      ),
      padding: EdgeInsets.all(_Responsive.padding(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: _DS.surface,
              child: Text(
                displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'S',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _DS.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: _DS.successSoft, borderRadius: BorderRadius.circular(100)),
                      child: const Text('Active', style: TextStyle(color: _DS.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('ID / Roll No: #$displayRoll  |  Directory Profile Verified', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _headerBadge(Icons.class_rounded, _currentSelectedClassName),
                    const SizedBox(width: 6),
                    _headerBadge(Icons.room_rounded, selectedSection.value?.name ?? 'General'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(_DS.radiusSm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      tabAlignment: TabAlignment.start,
      indicator: BoxDecoration(color: _DS.primarySoft, borderRadius: BorderRadius.circular(100)),
      labelColor: _DS.primary,
      unselectedLabelColor: _DS.textSecondary,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      tabs: const [
        Tab(text: 'Bio Profile'),
        Tab(text: 'Fee Details'),
        Tab(text: 'Admission Form'),
        Tab(text: 'Documents'),
        Tab(text: 'Academics'),
      ],
    );
  }

  Widget _buildBioTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_Responsive.padding(context)),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Personal Details',
            icon: Icons.person_outline_rounded,
            items: {
              'Student Name': _fieldValues['Student Name'] ?? '',
              'Aadhaar Name': _fieldValues['Aadhaar Name'] ?? '',
              'Roll Number': _fieldValues['Roll Number'] ?? '',
              'Admission Number': _fieldValues['Admission Number'] ?? '',
              'Date of Birth': _fieldValues['Date of Birth'] ?? '',
              'Gender': _fieldValues['Gender'] ?? '',
              'Blood Group': _fieldValues['Blood Group'] ?? '',
              'Mother Tongue': _fieldValues['Mother Tongue'] ?? '',
              'Religion': _fieldValues['Religion'] ?? '',
              'Caste': _fieldValues['Caste'] ?? '',
              'Subcaste': _fieldValues['Subcaste'] ?? '',
            },
          ),
          _buildInfoCard(
            title: 'Identity Documents',
            icon: Icons.badge_outlined,
            items: {
              'Aadhaar Number': _fieldValues['Aadhaar Number'] ?? '',
              'UDISE Number': _fieldValues['UDISE Number'] ?? '',
              'PEN Number': _fieldValues['PEN Number'] ?? '',
            },
          ),
          _buildInfoCard(
            title: 'Parent & Guardian Details',
            icon: Icons.family_restroom_rounded,
            items: {
              'Father Name': _fieldValues['Father Name'] ?? '',
              'Mother Name': _fieldValues['Mother Name'] ?? '',
              'Guardian Name': _fieldValues['Guardian Name'] ?? '',
              'Mobile Number': _fieldValues['Mobile Number'] ?? '',
              'Alternative Mobile': _fieldValues['Alternative Mobile'] ?? '',
            },
          ),
          _buildInfoCard(
            title: 'Contact Address',
            icon: Icons.home_outlined,
            items: {
              'Address': _fieldValues['Address'] ?? '',
              'Pincode': _fieldValues['Pincode'] ?? '',
            },
          ),
          _buildInfoCard(
            title: 'Physical & Other Details',
            icon: Icons.health_and_safety_outlined,
            items: {
              'Height (cm)': _fieldValues['Height (cm)'] ?? '',
              'Weight (kg)': _fieldValues['Weight (kg)'] ?? '',
              'Disability Type': _fieldValues['Disability Type'] ?? '',
              'Belongs to BPL': _fieldValues['Belongs to BPL'] ?? '',
            },
          ),
          _buildInfoCard(
            title: 'Bank Details',
            icon: Icons.account_balance_outlined,
            items: {
              'Bank Account No': _fieldValues['Bank Account No'] ?? '',
              'Bank IFSC': _fieldValues['Bank IFSC'] ?? '',
            },
          ),
          _buildInfoCard(
            title: 'Ration Card',
            icon: Icons.receipt_long_outlined,
            items: {
              'Ration Card Type': _fieldValues['Ration Card Type'] ?? '',
              'Ration Card No': _fieldValues['Ration Card No'] ?? '',
            },
          ),
        ],
      ),
    );
  }
  Widget _buildSelectionPromptOrStudentList(BuildContext context) {
   return Obx(() {
      // 1. Check if structural data is loading
      if (_schoolController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // 2. Fallback check: prompt to select a class
      if (selectedClass.value == null) {
        return _emptyState(
          icon: Icons.filter_alt_outlined,
          title: 'Begin Student Search',
          subtitle: 'Please select a Class using the navigation filters above.',
        );
      }

      // 3. Fallback check: prompt to select a section
      if (classHasSections.value && selectedSection.value == null) {
        return _emptyState(
          icon: Icons.group_add_outlined,
          title: 'Refine Filter Options',
          subtitle: 'Choose a Section to list corresponding students.',
        );
      }

      // 4. Perform type-safe filtering
      final filteredStudents = _schoolController.students.where((st) {
        if (!classHasSections.value) {
          return st.classId?.toString() == selectedClass.value?.id?.toString();
        }
        return st.sectionId?.toString() == selectedSection.value?.id?.toString();
      }).toList();

      // 5. If no matches pass the filter condition
      if (filteredStudents.isEmpty) {
        return _emptyState(
          icon: Icons.badge_outlined,
          title: 'No Registered Students',
          subtitle: 'There are currently no active profiles matching this section roster.',
        );
      }

      // 6. Return the matching student view rows
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredStudents.length,
        itemBuilder: (context, index) {
          final student = filteredStudents[index];
          return Card(
              color: _DS.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_DS.radiusSm),
    side: const BorderSide(color: _DS.border),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
    leading: CircleAvatar(
      backgroundColor: _DS.accentSoft,
      child: Text(
        student.name!.substring(0, 1).toUpperCase(),
        style: const TextStyle(color: _DS.accent, fontWeight: FontWeight.w700),
      ),
    ),
    title: Text('${student.name}', style: const TextStyle(fontWeight: FontWeight.w700, color: _DS.textPrimary)),
    subtitle: Text('Roll No: ${student.rollNumber ?? "N/A"} • ID: ${student.id}'),
    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _DS.textMuted),
    onTap: () {
      // Assign selection to load active sub-tab structures instantly
      selectedStudent.value = student;
      // Map parameters or perform API calls for profiles if needed
      _studentId = student.id;
      print("StudentId:$_studentId");
      _fetchStudentProfile();
      _fetchFeeDetails();
      _fetchAdmissionForm();
      _fetchAcademicPerformance();
      //_fetchStudentDocuments();
    },
              ),
          );
        },
      );
    });
  }
  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: _DS.primarySoft, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: _DS.primary),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _DS.textPrimary)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _DS.textSecondary)),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyDirectoryPlaceholder(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_Responsive.padding(context)),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: _DS.primarySoft, shape: BoxShape.circle),
                  child: const Icon(Icons.person_search_rounded, size: 40, color: _DS.primary),
                ),
                const SizedBox(height: 14),
                const Text('No Student Active Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _DS.textPrimary)),
                const SizedBox(height: 6),
                const Text('Search via unique context variables above or look up categories.', style: TextStyle(fontSize: 12, color: _DS.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ..._recentSearches.map((item) => Card(
            color: _DS.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusSm), side: const BorderSide(color: _DS.border)),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.history_toggle_off_rounded, color: _DS.textSecondary),
              title: Text('${item['name']} (${item['id']})', style: const TextStyle(fontWeight: FontWeight.w700, color: _DS.textPrimary)),
              subtitle: Text(item['class']!, style: const TextStyle(fontSize: 11)),
              onTap: () => _fetchStudentProfile(fallbackQuery: item['id']),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFeeDetailsTab(BuildContext context) {
    if (_isLoadingFee) return const Center(child: CircularProgressIndicator());
    if (!_feeFetched) {
      return _emptyState(icon: Icons.receipt_long_outlined, title: 'No Fee Record', subtitle: 'Fee details are not available for this student.');
    }
    final totalStructure = _feeStructure.values.fold(0, (a, b) => a + b);
    final totalPaid = _feePaid.values.fold(0, (a, b) => a + b);
    final totalDues = _feeDues.values.fold(0, (a, b) => a + b);

    return SingleChildScrollView(
      padding: EdgeInsets.all(_Responsive.padding(context)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _feeSummaryCard('Total Fee', totalStructure, _DS.primary)),
              const SizedBox(width: 10),
              Expanded(child: _feeSummaryCard('Paid', totalPaid, _DS.success)),
              const SizedBox(width: 10),
              Expanded(child: _feeSummaryCard('Dues', totalDues, _DS.danger)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Fee Structure',
            icon: Icons.receipt_long_outlined,
            items: _feeStructure.map((k, v) => MapEntry(k, '₹ $v')),
          ),
          _buildInfoCard(
            title: 'Amount Paid',
            icon: Icons.check_circle_outline_rounded,
            items: _feePaid.map((k, v) => MapEntry(k, '₹ $v')),
          ),
          _buildInfoCard(
            title: 'Outstanding Dues',
            icon: Icons.warning_amber_rounded,
            items: _feeDues.map((k, v) => MapEntry(k, '₹ $v')),
          ),
        ],
      ),
    );
  }

  Widget _feeSummaryCard(String label, int amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(_DS.radiusSm)),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('₹ $amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
  Widget _buildAdmissionFormTab(BuildContext context) {
    if (_isLoadingAdmission) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_admissionFetched || _admissionFormData == null) {
      return _emptyState(
        icon: Icons.description_outlined,
        title: 'No Admission Form',
        subtitle: 'No admission form is linked to this student.',
      );
    }

    final d = _admissionFormData!;

    String field(String key) => d[key]?.toString() ?? '';

    return SingleChildScrollView(
      padding: EdgeInsets.all(_Responsive.padding(context)),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Student Details',
            icon: Icons.person_outline_rounded,
            items: {
              'Student Name': field('studentName'),
              'Date of Birth': field('dob'),
              'Age': field('age'),
              'Gender': field('gender'),
              'Mother Tongue': field('motherTongue'),
              'Religion': field('religion'),
              'Community': field('community'),
              'EMIS Number': field('emisNumber'),
            },
          ),
          _buildInfoCard(
            title: 'Academic & Contact',
            icon: Icons.school_outlined,
            items: {
              'Academic Year': field('academicYear'),
              'Admission Sought For': field('admissionSoughtFor'),
              'Previous Exam / Last Class Passed': field('examinationPassed'),
              'Mobile Number': field('mobileNumber'),
              'Current Address': field('currentAddress'),
              'Permanent Address': field('permanentAddress'),
            },
          ),
          _buildInfoCard(
            title: 'Parent Information',
            icon: Icons.family_restroom_rounded,
            items: {
              "Father's Name": field('fatherName'),
              "Father's Education": field('fatherEducation'),
              "Father's Occupation": field('fatherOccupation'),
              "Mother's Name": field('motherName'),
              "Mother's Education": field('motherEducation'),
              "Mother's Occupation": field('motherOccupation'),
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColorForAdmission(field('status')).withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              field('status').isEmpty ? 'Pending' : field('status'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _statusColorForAdmission(field('status')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColorForAdmission(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return _DS.success;
      case 'rejected':
        return _DS.danger;
      case 'pending':
      default:
        return _DS.warning;
    }
  }
  Widget _buildDocumentsTab(BuildContext context) {
    if (_isLoadingProfile) return const Center(child: CircularProgressIndicator());

    final hasImage = _profileImageUrl != null && _profileImageUrl!.isNotEmpty;
    final hasDocs = _studentDocuments.isNotEmpty;

    if (!_hasSearched1 || (!hasImage && !hasDocs)) {
      return _emptyState(
        icon: Icons.folder_off_outlined,
        title: 'No Documents',
        subtitle: 'No photo or documents have been uploaded for this student yet.',
      );
    }

    return ListView(
      padding: EdgeInsets.all(_Responsive.padding(context)),
      children: [
        if (hasImage) ...[
          const Text('Student Photo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _DS.textPrimary)),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border.all(color: _DS.border),
              borderRadius: BorderRadius.circular(_DS.radius),
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                _profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ],
        if (hasDocs) ...[
          const Text('Uploaded Documents',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _DS.textPrimary)),
          const SizedBox(height: 10),
          ..._studentDocuments.map((doc) {
            final name = doc['originalName']?.toString() ?? doc['name']?.toString() ?? 'Document';
            final url = doc['url']?.toString() ?? '';
            final type = doc['type']?.toString() ?? '';
            final isImage = type == 'image';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _DS.surface,
                border: Border.all(color: _DS.border),
                borderRadius: BorderRadius.circular(_DS.radius),
              ),
              child: ListTile(
                leading: Icon(
                  isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                  color: _DS.primary,
                ),
                title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: _DS.textMuted),
                onTap: url.isEmpty ? null : () => _openDocument(url),
              ),
            );
          }),
        ],
      ],
    );
  }
  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }  Widget _buildAcademicsTab(BuildContext context) {
    if (_isLoadingAcademics) return const Center(child: CircularProgressIndicator());

    if (!_academicsFetched || _examPerformance.isEmpty) {
      return _emptyState(
        icon: Icons.school_outlined,
        title: 'No Academic Records',
        subtitle: 'No exam results are available for this student yet.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(_Responsive.padding(context)),
      itemCount: _examPerformance.length,
      itemBuilder: (context, index) {
        final exam = _examPerformance[index];
        final pct = exam['percentage'] as double;
        final grade = exam['grade'] as String;
        final isAbsent = exam['isAbsent'] as bool;
        final color = isAbsent
            ? _DS.textMuted
            : pct >= 75
            ? _DS.success
            : pct >= 35
            ? _DS.warning
            : _DS.danger;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _DS.surface,
            border: Border.all(color: _DS.border),
            borderRadius: BorderRadius.circular(_DS.radius),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isAbsent ? 'AB' : grade,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam['examName'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _DS.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      isAbsent ? 'Absent' : '${pct.toStringAsFixed(1)}% scored',
                      style: const TextStyle(fontSize: 12, color: _DS.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!isAbsent)
                Text('${pct.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        );
      },
    );
  }
  Widget _buildInfoCard({required String title, required IconData icon, required Map<String, String> items}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(color: _DS.surface, border: Border.all(color: _DS.border), borderRadius: BorderRadius.circular(_DS.radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: _DS.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _DS.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: _DS.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: items.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 130, child: Text(entry.key, style: const TextStyle(fontSize: 12, color: _DS.textSecondary, fontWeight: FontWeight.w500))),
                      Expanded(child: Text(entry.value.isEmpty ? '—' :entry.value, style: const TextStyle(fontSize: 12, color: _DS.textPrimary, fontWeight: FontWeight.w600))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  final classHasSections = true.obs;

  void _showClassFilterSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(_DS.radiusLg)),
        ),
        // Prevent sheet from taking full screen but allow proper constraints
        constraints: BoxConstraints(maxHeight: Get.height * 0.6),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: _DS.border, borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Select Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _DS.textPrimary)),
              const Divider(color: _DS.border),
              Expanded(
                // Wrap with Obx so the list properly listens to controller state changes
                child: Obx(() {
                  final sortedClasses = List<SchoolClass>.from(classes)
                    ..sort((a, b) => _compareClassNames(a.name, b.name));
                  if (sortedClasses.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No classes found', style: TextStyle(color: _DS.textSecondary)),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: sortedClasses.length,
                    itemBuilder: (context, index) {
                      final c = sortedClasses[index];
                      final isSelected = selectedClass.value?.id == c.id;
                      return ListTile(
                        title: Text(c.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: _DS.textPrimary)),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: _DS.accent) : null,
                        onTap: () async {
                          selectedClass.value = c;
                          selectedSection.value = null; // Reset subordinate selection
                          selectedStudent.value = null;
                          Get.back();
                          await _schoolController.getAllSections(
                            classId: c.id,
                            schoolId: _resolvedSchoolId,
                          );
                          // 2. Check if this class actually contains any sections
                          final classSections = _schoolController.sections.where((s) => s.classId == c.id).toList();
                          classHasSections.value = classSections.isNotEmpty;

                          if (classSections.isEmpty) {
                            // 🚀 NO SECTIONS: Instantly call students API at class level
                            await _schoolController.getAllStudents(
                              schoolId: _resolvedSchoolId,
                              classId: c.id,
                              sectionId: null,
                            );
                          } else {
                            // SECTIONS EXIST: Prompt the user to choose a section
                            _showSectionFilterSheet(context);
                          }
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true, // 👈 CRITICAL: This fixes the empty sheet issue
      backgroundColor: Colors.transparent,
    );
  }

  void _showSectionFilterSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(_DS.radiusLg)),
        ),
        constraints: BoxConstraints(maxHeight: Get.height * 0.6),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: _DS.border, borderRadius: BorderRadius.circular(2)),
              ),
              Obx(() => Text(
                  'Select Section for ${selectedClass.value?.name ?? ""}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _DS.textPrimary)
              )),
              const Divider(color: _DS.border),
              Expanded(
                child: Obx(() {
                  if (_schoolController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final classSections = _schoolController.sections.where((s) => s.classId == selectedClass.value?.id).toList();

                  if (classSections.isEmpty) {
                    return _emptyState(
                        icon: Icons.group_outlined,
                        title: 'No Sections Found',
                        subtitle: 'No active divisions configured for this class.'
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: classSections.length,
                    itemBuilder: (context, index) {
                      final sec = classSections[index];
                      final isSelected = selectedSection.value?.id == sec.id;
                      return ListTile(
                        title: Text(sec.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: _DS.textPrimary)),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: _DS.accent) : null,
                        onTap: () async{
                          selectedSection.value = sec;
                          selectedStudent.value = null;
                          Get.back();

                          await _schoolController.getAllStudents(
                            schoolId: _resolvedSchoolId,
                            classId: selectedClass.value?.id,
                            sectionId: sec.id,
                          );
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true, // 👈 CRITICAL: This fixes the empty sheet issue
      backgroundColor: Colors.transparent,
    );
  }

}

