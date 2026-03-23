import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:school_app/controllers/teacher_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/user_management_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

class TeacherAssignmentView extends StatefulWidget {
  const TeacherAssignmentView({super.key});

  @override
  State<TeacherAssignmentView> createState() =>
      _TeacherAssignmentViewState();
}

class _TeacherAssignmentViewState extends State<TeacherAssignmentView> {
  final TeacherController teacherController = Get.put(TeacherController());
  final SchoolController schoolController = Get.find<SchoolController>();
  final UserManagementController userController =
  Get.find<UserManagementController>();

  String? selectedTeacherId;

  /// Current UI selections (what should be assigned)
  final RxList<Map<String, dynamic>> selectedAssignments =
      <Map<String, dynamic>>[].obs;

  /// Original assignments when teacher was loaded
  final RxList<Map<String, dynamic>> originalAssignments =
      <Map<String, dynamic>>[].obs;

  /// Master data
  List<Map<String, dynamic>> classSectionData = [];

  bool _initialized = false;

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    
    
    
    
    if (_initialized || schoolController.selectedSchool.value == null) {
      
      return;
    }

    _initialized = true;
    final schoolId = schoolController.selectedSchool.value!.id;
    

    await userController.loadUsers(
      schoolId: schoolId,
      role: 'teacher',
    );
    

    if (!mounted) return;
    await _loadClassSectionAssignments();
  }

  // ================= API =================

  Future<void> _loadClassSectionAssignments() async {
    final schoolId = schoolController.selectedSchool.value!.id;
    

    final response =
    await teacherController.getAllClassSectionAssignments(
      schoolId,
    );
    

    if (!mounted) return;
    setState(() {
      classSectionData = response;
    });
    
  }

  /// Prefill from teacher assignments API
  void _prefillFromTeacherAssignments(List assignments) {
    

    // Store original assignments for comparison
    originalAssignments.clear();
    selectedAssignments.clear();

    for (final a in assignments) {
      final classObj = a['classId'];
      final sectionObj = a['sectionId'];

      final String classId =
      classObj is Map ? classObj['_id'] : classObj?.toString() ?? '';

      final String? sectionId = sectionObj == null
          ? null
          : (sectionObj is Map ? sectionObj['_id'] : sectionObj?.toString());

      final assignment = {
        'classId': classId,
        'sectionId': sectionId,
      };

      originalAssignments.add(assignment);
      selectedAssignments.add(assignment);
      
    }
    

  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (schoolController.selectedSchool.value == null) {
      return const Center(child: Text('No school selected'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Assignments'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTeacherDropdown(),
                  const SizedBox(height: 12),
                  _buildCurrentAssignments(),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildClassSectionList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSaveButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TEACHER DROPDOWN =================

  Widget _buildTeacherDropdown() {
    return GetBuilder<UserManagementController>(
      builder: (controller) {
        return DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Choose Teacher',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person, color: AppTheme.primaryBlue, size: 20),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          dropdownColor: Colors.white,
          menuMaxHeight: 300,
          borderRadius: BorderRadius.circular(12),
          icon: Container(
            margin: const EdgeInsets.only(right: 12),
            child: Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryBlue),
          ),
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          value: selectedTeacherId,
          selectedItemBuilder: (context) {
            return controller.users.map((teacher) {
              return Text(
                teacher['userName'] ?? 'Unknown',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              );
            }).toList();
          },
          items: controller.users
              .map<DropdownMenuItem<String>>((teacher) {
            return DropdownMenuItem<String>(
              value: teacher['_id'],
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.person, color: AppTheme.primaryBlue, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        teacher['userName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) return;

            /// 🔥 HARD RESET (CRITICAL FIX)
            selectedAssignments.clear();
            originalAssignments.clear();

            if (!mounted) return;
            setState(() => selectedTeacherId = value);

            final teacher =
            await userController.getTeacherById(value);

            if (!mounted) return;
            if (teacher != null &&
                teacher['assignments'] != null) {
              _prefillFromTeacherAssignments(
                teacher['assignments'],
              );
              if (mounted) {
                setState(() {});
              }
            }
          },
        );
      },
    );
  }

  // ================= CURRENT ASSIGNMENTS =================

  Widget _buildCurrentAssignments() {
    if (selectedTeacherId == null) return const SizedBox();

    return Obx(() {
      if (selectedAssignments.isEmpty) return const SizedBox();

      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: selectedAssignments.map((a) {
                final className = _getClassName(a['classId']);
                final sectionName = a['sectionId'] != null
                    ? _getSectionName(a['sectionId'])
                    : 'All Sections';
            
                final isAll = a['sectionId'] == null;
            
                return Chip(
                  avatar: Icon(
                    isAll ? Icons.school : Icons.layers,
                    size: 18,
                    color:
                    isAll ? AppTheme.primaryBlue : Colors.green,
                  ),
                  label: Text('$className - $sectionName'),
                  backgroundColor: isAll
                      ? AppTheme.primaryBlue.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
                );
              }).toList(),
            ),
          ),
        ),
      );
    });
  }

  // ================= CLASS / SECTION LIST =================

  Widget _buildClassSectionList() {
    if (classSectionData.isEmpty) {
      return const Center(child: Text('No class data available'));
    }

    return ListView.builder(
      itemCount: classSectionData.length,
      itemBuilder: (context, index) {
        final cls = classSectionData[index];
        final classId = cls['_id'];
        final className = cls['name'] ?? 'Unknown Class';
        final sections = cls['sections'] ?? [];

        final hasAllAssigned = selectedAssignments.any(
              (a) => a['classId'] == classId && a['sectionId'] == null,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text('Class $className'),
            subtitle: hasAllAssigned
                ? const Text('All sections assigned')
                : null,
            children: [
              // "All Sections" checkbox
              CheckboxListTile(
                title: const Text('All Sections'),
                subtitle: const Text('Assign to entire class'),
                value: hasAllAssigned,
                onChanged: selectedTeacherId == null
                    ? null
                    : (checked) {
                        // For toggle API: send classId only (no sectionId) to toggle entire class
                        final classToggle = {'classId': classId};

                        if (checked == true) {
                          // Assign all sections: remove individual section assignments for this class
                          selectedAssignments.removeWhere((a) => a['classId'] == classId);
                          // Add the "all sections" assignment
                          selectedAssignments.add({'classId': classId, 'sectionId': null});
                          
                        } else {
                          // Remove all assignments for this class
                          selectedAssignments.removeWhere((a) => a['classId'] == classId);
                          
                        }
                        setState(() {});
                      },
              ),

              // Individual sections (show if "all sections" is not selected, or allow switching)
              const Divider(),
              if (sections.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No sections available'),
                )
              else
                ...sections.map<Widget>((section) {
                  final sectionId = section['_id'];
                  final sectionName = section['name'] ?? 'Unknown Section';

                  final checked = selectedAssignments.any((a) =>
                      a['classId'] == classId && a['sectionId'] == sectionId);

                  return CheckboxListTile(
                    title: Text('Section $sectionName'),
                    value: checked,
                    subtitle: hasAllAssigned
                        ? const Text('Uncheck "All Sections" above to select individual sections')
                        : null,
                    onChanged: selectedTeacherId == null
                        ? null
                        : (hasAllAssigned && !checked)
                            ? (_) {
                                // If "All Sections" is checked and user tries to check individual section,
                                // first uncheck "All Sections"
                                selectedAssignments.removeWhere((a) => a['classId'] == classId);
                                // Then check the individual section
                                _toggleAssignment(classId, sectionId);
                                setState(() {});
                              }
                            : hasAllAssigned && checked
                                ? null // Can't uncheck individual when "all" is selected
                                : (_) => _toggleAssignment(classId, sectionId),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // ================= SAVE =================

  Widget _buildSaveButton() {
    return Obx(() {
      final loading = teacherController.isLoading.value;

      return Column(
        children: [
          ElevatedButton(
            onPressed: selectedTeacherId == null || loading
                ? null
                : _saveAssignments,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Assignments'),
          ),

        ],
      );
    });
  }

  Future<void> _saveAssignments() async {

    // Calculate changes for toggle API
    final changesToSend = <Map<String, dynamic>>[];

    // Find assignments to REMOVE (in original but not in selected)
    for (final original in originalAssignments) {
      final stillSelected = selectedAssignments.any((selected) =>
          selected['classId'] == original['classId'] &&
          selected['sectionId'] == original['sectionId']);

      if (!stillSelected) {
        changesToSend.add(original);
        
      }
    }

    // Find assignments to ADD (in selected but not in original)
    for (final selected in selectedAssignments) {
      final wasOriginallyAssigned = originalAssignments.any((original) =>
          original['classId'] == selected['classId'] &&
          original['sectionId'] == selected['sectionId']);

      if (!wasOriginallyAssigned) {
        changesToSend.add(selected);
        
      }
    }

    if (changesToSend.isEmpty) {
      
      Get.snackbar('Info', 'No changes to save');
      return;
    }

    // Send to toggle API
    teacherController.manageTeacherAssignments(
      teacherId: selectedTeacherId!,
      updates: changesToSend,
      schoolId: schoolController.selectedSchool.value!.id,
    );

    // Update original assignments to current state (for future comparisons)
    originalAssignments.clear();
    originalAssignments.addAll(selectedAssignments);

    // Refresh UI after toggle operations
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      if (selectedTeacherId != null) {
        
        final updatedTeacher = await userController.getTeacherById(selectedTeacherId!);
        if (!mounted) return;
        if (updatedTeacher != null) {
          
          // Update UI with actual state after toggles
          selectedAssignments.clear();
          originalAssignments.clear();
          if (updatedTeacher['assignments'] != null) {
            _prefillFromTeacherAssignments(updatedTeacher['assignments']);
          }
          
          if (mounted) {
            setState(() {});
          }
        }
      }
    });
  }

  void _toggleAssignment(String classId, String sectionId) {
    final assignment = {'classId': classId, 'sectionId': sectionId};
    final index = selectedAssignments.indexWhere((a) =>
    a['classId'] == classId &&
        a['sectionId'] == sectionId);

    if (index >= 0) {
      // Unchecking: remove from selected
      selectedAssignments.removeAt(index);
      
    } else {
      // Checking: add to selected
      selectedAssignments.add(assignment);
      
    }

  }

  String _getClassName(String classId) {
    final cls =
    classSectionData.firstWhereOrNull((c) => c['_id'] == classId);
    return cls?['name'] ?? 'Unknown Class';
  }

  String _getSectionName(String sectionId) {
    for (final item in classSectionData) {
      final List sections = item['sections'] ?? [];
      for (final sec in sections) {
        if (sec['_id'] == sectionId) {
          return sec['name'] ?? 'Unknown Section';
        }
      }
    }
    return 'Unknown Section';
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../controllers/teacher_controller.dart';
// import '../controllers/school_controller.dart';
// import '../controllers/user_management_controller.dart';
// import '../core/theme/app_theme.dart';
//
// class TeacherAssignmentView extends StatefulWidget {
//   const TeacherAssignmentView({super.key});
//
//   @override
//   State<TeacherAssignmentView> createState() =>
//       _TeacherAssignmentViewState();
// }
//
// class _TeacherAssignmentViewState extends State<TeacherAssignmentView> {
//   final TeacherController teacherController = Get.put(TeacherController());
//   final SchoolController schoolController = Get.find<SchoolController>();
//   final UserManagementController userController =
//   Get.find<UserManagementController>();
//
//   String? selectedTeacherId;
//
//   final RxList<Map<String, dynamic>> selectedAssignments =
//       <Map<String, dynamic>>[].obs;
//
//   List<Map<String, dynamic>> classSectionData = [];
//
//   bool _initialized = false;
//
//   // ================= INIT =================
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
//   }
//
//   Future<void> _initialize() async {
//     if (_initialized ||
//         schoolController.selectedSchool.value == null) return;
//
//     _initialized = true;
//
//     final schoolId = schoolController.selectedSchool.value!.id;
//
//     await userController.loadUsers(
//       schoolId: schoolId,
//       role: 'teacher',
//     );
//
//     await _loadClassSectionAssignments();
//   }
//
//   // ================= API =================
//
//   Future<void> _loadClassSectionAssignments() async {
//     final schoolId = schoolController.selectedSchool.value!.id;
//
//     final response =
//     await teacherController.getAllClassSectionAssignments(
//       schoolId: schoolId,
//     );
//
//     setState(() {
//       classSectionData = response;
//     });
//   }
//
//   void _prefillFromTeacherAssignments(List assignments) {
//     selectedAssignments.clear();
//
//     for (final a in assignments) {
//       final classObj = a['classId'];
//       final sectionObj = a['sectionId'];
//
//       final String classId =
//       classObj is Map ? classObj['_id'] : classObj;
//
//       final String? sectionId = sectionObj == null
//           ? null
//           : (sectionObj is Map ? sectionObj['_id'] : sectionObj);
//
//       selectedAssignments.add({
//         'classId': classId,
//         'sectionId': sectionId,
//       });
//     }
//   }
//   final RxList<Map<String, dynamic>> removedAssignments =
//       <Map<String, dynamic>>[].obs;
//
//   // ================= UI =================
//
//   @override
//   Widget build(BuildContext context) {
//     if (schoolController.selectedSchool.value == null) {
//       return const Center(child: Text('No school selected'));
//     }
//
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isTablet = constraints.maxWidth > 700;
//
//         return Scaffold(
//           backgroundColor: const Color(0xFFF6F8FC),
//           appBar: AppBar(
//             title: const Text('Teacher Assignments'),
//             backgroundColor: Colors.brown,
//             foregroundColor: Colors.white,
//             elevation: 0,
//           ),
//           body: SafeArea(
//             child: Column(
//               children: [
//                 /// HEADER
//                 Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: isTablet ? 24 : 16,
//                     vertical: 12,
//                   ),
//                   child: Column(
//                     children: [
//                       _buildTeacherDropdown(),
//                       const SizedBox(height: 12),
//                       _buildCurrentAssignments(),
//                     ],
//                   ),
//                 ),
//
//                 /// LIST
//                 Expanded(
//                   child: Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: isTablet ? 24 : 16,
//                     ),
//                     child: _buildClassSectionList(),
//                   ),
//                 ),
//
//                 /// SAVE BUTTON
//                 Container(
//                   padding: EdgeInsets.fromLTRB(
//                     isTablet ? 24 : 16,
//                     12,
//                     isTablet ? 24 : 16,
//                     MediaQuery.of(context).padding.bottom + 12,
//                   ),
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black12,
//                         blurRadius: 10,
//                         offset: Offset(0, -2),
//                       ),
//                     ],
//                   ),
//                   child: _buildSaveButton(),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // ================= TEACHER DROPDOWN =================
//
//   Widget _buildTeacherDropdown() {
//     return GetBuilder<UserManagementController>(
//       builder: (controller) {
//         return Card(
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: DropdownButtonFormField<String>(
//               decoration: const InputDecoration(
//                 labelText: 'Select Teacher',
//                 prefixIcon: Icon(Icons.person),
//                 border: OutlineInputBorder(),
//               ),
//               value: selectedTeacherId,
//               items: controller.users
//                   .map<DropdownMenuItem<String>>((teacher) {
//                 return DropdownMenuItem<String>(
//                   value: teacher['_id'],
//                   child: Text(teacher['userName'] ?? 'Unknown'),
//                 );
//               }).toList(),
//               onChanged: (value) async {
//                 if (value == null) return;
//
//                 setState(() => selectedTeacherId = value);
//
//                 final teacher =
//                 await userController.getTeacherById(value);
//
//                 if (teacher != null &&
//                     teacher['assignments'] != null) {
//                   _prefillFromTeacherAssignments(
//                     teacher['assignments'],
//                   );
//                 }
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // ================= CURRENT ASSIGNMENTS =================
//
//   Widget _buildCurrentAssignments() {
//     if (selectedTeacherId == null) return const SizedBox();
//
//     return Obx(() {
//       if (selectedAssignments.isEmpty) {
//         return const SizedBox();
//       }
//
//       return Card(
//         elevation: 1,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: SingleChildScrollView(
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 6,
//               children: selectedAssignments.map((a) {
//                 final className = _getClassName(a['classId']);
//                 final sectionName = a['sectionId'] != null
//                     ? _getSectionName(a['sectionId'])
//                     : 'All Sections';
//            
//                 final bool isSection = a['sectionId'] != null;
//            
//                 return Chip(
//                   avatar: Icon(
//                     isSection ? Icons.layers : Icons.school,
//                     size: 18,
//                     color: isSection
//                         ? Colors.green
//                         : AppTheme.primaryBlue,
//                   ),
//                   label: Text('$className • $sectionName'),
//                   backgroundColor: isSection
//                       ? Colors.green.withOpacity(0.12)
//                       : AppTheme.primaryBlue.withOpacity(0.12),
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       );
//     });
//   }
//
//   // ================= CLASS / SECTION LIST =================
//
//   Widget _buildClassSectionList() {
//     if (classSectionData.isEmpty) {
//       return const Center(child: Text('No class data available'));
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.only(bottom: 20),
//       itemCount: classSectionData.length,
//       itemBuilder: (context, index) {
//         final cls = classSectionData[index];
//         final classId = cls['_id'];
//         final className = cls['name'] ?? 'Unknown Class';
//         final sections = cls['sections'] ?? [];
//
//         return Card(
//           elevation: 2,
//           margin: const EdgeInsets.only(bottom: 12),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: ExpansionTile(
//             leading: const Icon(Icons.school),
//             title: Text(
//               'Class $className',
//               style: const TextStyle(fontWeight: FontWeight.w600),
//             ),
//             children: sections.isEmpty
//                 ? const [
//               Padding(
//                 padding: EdgeInsets.all(12),
//                 child: Text('No sections'),
//               )
//             ]
//                 : sections.map<Widget>((section) {
//               final sectionId = section['_id'];
//               final sectionName =
//                   section['name'] ?? 'Unknown Section';
//
//               return CheckboxListTile(
//                 title: Text('Section $sectionName'),
//                 value: selectedAssignments.any((a) =>
//                 a['classId'] == classId &&
//                     a['sectionId'] == sectionId),
//                 onChanged: selectedTeacherId == null
//                     ? null
//                     : (_) {
//                   _toggleAssignment(
//                     classId,
//                     sectionId,
//                   );
//                 },
//               );
//             }).toList(),
//           ),
//         );
//       },
//     );
//   }
//
//   // ================= SAVE =================
//
//   Widget _buildSaveButton() {
//     return Obx(() {
//       final loading = teacherController.isLoading.value;
//
//       return SizedBox(
//         width: double.infinity,
//         height: 52,
//         child: ElevatedButton(
//           onPressed: selectedTeacherId == null || loading
//               ? null
//               : _saveAssignments,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppTheme.primaryBlue,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(14),
//             ),
//           ),
//           child: loading
//               ? const CircularProgressIndicator(color: Colors.white)
//               : const Text(
//             'Save Assignments',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       );
//     });
//   }
//
//   void _saveAssignments() async {
//     if (selectedTeacherId == null) return;
//
//     // 1️⃣ Fetch latest assignments from backend
//     final teacher =
//     await userController.getTeacherById(selectedTeacherId!);
//
//     final List existingAssignments =
//         teacher?['assignments'] ?? [];
//
//     // 2️⃣ Normalize existing assignments
//     final List<Map<String, dynamic>> normalizedExisting =
//     existingAssignments.map<Map<String, dynamic>>((a) {
//       final classObj = a['classId'];
//       final sectionObj = a['sectionId'];
//
//       return {
//         'classId': classObj is Map ? classObj['_id'] : classObj,
//         'sectionId': sectionObj is Map ? sectionObj['_id'] : sectionObj,
//       };
//     }).toList();
//
//     // 3️⃣ Remove ONLY explicitly removed ones
//     final filteredExisting = normalizedExisting.where((existing) {
//       return !removedAssignments.any((removed) =>
//       removed['classId'] == existing['classId'] &&
//           removed['sectionId'] == existing['sectionId']);
//     }).toList();
//
//     // 4️⃣ Merge with newly selected (avoid duplicates)
//     final finalAssignments = [
//       ...filteredExisting,
//       ...selectedAssignments.where((newItem) =>
//       !filteredExisting.any((e) =>
//       e['classId'] == newItem['classId'] &&
//           e['sectionId'] == newItem['sectionId'])),
//     ];
//
//     // 5️⃣ Send FULL FINAL STATE
//     teacherController.manageTeacherAssignments(
//       teacherId: selectedTeacherId!,
//       updates: finalAssignments,
//       schoolId: schoolController.selectedSchool.value!.id,
//     );
//
//     // 6️⃣ Clear removals after save
//     removedAssignments.clear();
//   }
//
//   // void _saveAssignments() async {
//   //   final teacher =
//   //   await userController.getTeacherById(selectedTeacherId!);
//   //
//   //   final List<Map<String, dynamic>> existingAssignments = [];
//   //
//   //   if (teacher != null && teacher['assignments'] != null) {
//   //     for (final a in teacher['assignments']) {
//   //       final classObj = a['classId'];
//   //       final sectionObj = a['sectionId'];
//   //
//   //       existingAssignments.add({
//   //         'classId': classObj is Map ? classObj['_id'] : classObj,
//   //         'sectionId': sectionObj == null
//   //             ? null
//   //             : (sectionObj is Map ? sectionObj['_id'] : sectionObj),
//   //       });
//   //     }
//   //   }
//   //
//   //   /// 🔥 Merge without duplicates
//   //   final Set<String> seen = {};
//   //   final List<Map<String, dynamic>> finalAssignments = [];
//   //
//   //   for (final a in [...existingAssignments, ...selectedAssignments]) {
//   //     final key = '${a['classId']}_${a['sectionId']}';
//   //     if (!seen.contains(key)) {
//   //       seen.add(key);
//   //       finalAssignments.add(a);
//   //     }
//   //   }
//   //
//   //   teacherController.manageTeacherAssignments(
//   //     teacherId: selectedTeacherId!,
//   //     updates: finalAssignments,
//   //     schoolId: schoolController.selectedSchool.value!.id,
//   //   );
//   // }
//
//
//   // ================= HELPERS =================
//
//   void _toggleAssignment(String classId, String sectionId) {
//     final index = selectedAssignments.indexWhere(
//           (a) => a['classId'] == classId && a['sectionId'] == sectionId,
//     );
//
//     if (index >= 0) {
//       // User explicitly removed
//       final removed = selectedAssignments.removeAt(index);
//       removedAssignments.add(removed);
//     } else {
//       // User added
//       selectedAssignments.add({
//         'classId': classId,
//         'sectionId': sectionId,
//       });
//     }
//   }
//
//
//   String _getClassName(String classId) {
//     final cls =
//     classSectionData.firstWhereOrNull((c) => c['_id'] == classId);
//     return cls?['name'] ?? 'Unknown Class';
//   }
//
//   String _getSectionName(String sectionId) {
//     for (final item in classSectionData) {
//       final List sections = item['sections'] ?? [];
//       for (final sec in sections) {
//         if (sec['_id'] == sectionId) {
//           return sec['name'] ?? 'Unknown Section';
//         }
//       }
//     }
//     return 'Unknown Section';
//   }
// }
