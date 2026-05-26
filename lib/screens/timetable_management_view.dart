import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/timetable_controller.dart';
import 'package:school_app/controllers/teacher_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/models/school_models.dart';

class TimetableManagementView extends StatefulWidget {
  @override
  State<TimetableManagementView> createState() => _TimetableManagementViewState();
}

class _TimetableManagementViewState extends State<TimetableManagementView> with TickerProviderStateMixin {
  final schoolController = Get.find<SchoolController>();
  final timetableController = Get.put(TimetableController());
  final teacherController = Get.put(TeacherController());
  final authController = Get.find<AuthController>();
  
  late TabController _tabController;
  SchoolClass? selectedClass;
  Section? selectedSection;
  String? selectedTeacherId;
  
  final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _getAvailableTabsCount(), vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      schoolController.getAllSchools().then((_) {
        if (ApiPermissions.isSchoolReadOnly(currentUserRole)) {
          final userSchoolId = authController.user.value?.schoolId;
          if (userSchoolId != null) {
            final userSchool = schoolController.schools.firstWhereOrNull(
              (s) => s.id == userSchoolId,
            );
            if (userSchool != null) {
              schoolController.selectedSchool.value = userSchool;
              schoolController.getAllClasses(userSchool.id);
              schoolController.loadTeachers();
            }
          }
        }
      });
    });
  }

  int _getAvailableTabsCount() {
    int count = 0;
    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) count++;
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/getall')) count++;
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/teacherschedule')) count++;
    return count > 0 ? count : 1;
  }

  List<Widget> _buildTabs() {
    List<Widget> tabs = [];
    
    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) {
      tabs.add(const Tab(
        child: Row(
         // mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_calendar, size: 11),
            //SizedBox(width: 8),
            Text('Manage'),
          ],
        ),
      ));
    }
    
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/getall')) {
      tabs.add(const Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_list, size: 11),
           // SizedBox(width: 8),
            Text('View'),
          ],
        ),
      ));
    }
    
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/teacherschedule')) {
      tabs.add(const Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 11),
           // SizedBox(width: 8),
            Text('Teacher'),
          ],
        ),
      ));
    }
    
    return tabs.isNotEmpty ? tabs : [const Tab(text: 'No Access')];
  }

  List<Widget> _buildTabViews(bool isTablet, bool isLandscape) {
    List<Widget> views = [];
    
    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) {
      views.add(_buildManageTab(isTablet, isLandscape));
    }
    
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/getall')) {
      views.add(_buildViewTab(isTablet, isLandscape));
    }
    
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/teacherschedule')) {
      views.add(_buildTeacherTab(isTablet, isLandscape));
    }
    
    return views.isNotEmpty ? views : [_buildNoAccessView()];
  }

  Widget _buildNoAccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No Access',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You don\'t have permission to access timetable management',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _compareClassNames(String a, String b) {
    final aLower = a.toLowerCase().trim();
    final bLower = b.toLowerCase().trim();
    
    int _getClassPriority(String className) {
      if (className == 'lkg') return 1;
      if (className == 'ukg') return 2;
      if (className.startsWith('grade ')) {
        final match = RegExp(r'grade (\d+)', caseSensitive: false).firstMatch(className);
        if (match != null) {
          final num = int.tryParse(match.group(1)!);
          if (num != null) return 2 + num;
        }
      }
      if (className.startsWith('class ')) {
        final match = RegExp(r'class (\d+)', caseSensitive: false).firstMatch(className);
        if (match != null) {
          final num = int.tryParse(match.group(1)!);
          if (num != null) return 20 + num;
        }
      }
      return 999;
    }
    
    return _getClassPriority(aLower).compareTo(_getClassPriority(bLower));
  }

  IconData _getClassIcon(String className) {
    final lower = className.toLowerCase();
    if (lower == 'lkg' || lower == 'ukg') return Icons.child_care;
    if (lower.contains('grade 1') || lower.contains('grade 2') || lower.contains('grade 3')) return Icons.looks_one;
    if (lower.contains('grade 4') || lower.contains('grade 5') || lower.contains('grade 6')) return Icons.looks_two;
    if (lower.contains('grade 7') || lower.contains('grade 8') || lower.contains('grade 9')) return Icons.looks_3;
    return Icons.looks_4;
  }

  String get currentUserRole => authController.user.value?.role?.toLowerCase() ?? '';

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            // REPLACE THE TOP CONTAINER (Header & TabBar) WITH THIS:
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                begin: Alignment.topLeft, // Start point
                end: Alignment.bottomRight, // End point
                colors: [
                  Color(0xFF60A5FA),
                  Color(0xFF2563EB),
                ],
              ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, isTablet ? 30 : 10, 20, 20),
                    child: Row(
                      children: [
                        // Refined Icon Plate
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded, // Modern grid icon
                            color: Color(0xFF2563EB), // Soft accent blue
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Academic Schedule',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 22 : 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Management Terminal',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,

                                  //letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Optional Action Button (e.g. Refresh or Settings)
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.more_vert_rounded, color: Colors.white,size: 18,),
                        )
                      ],
                    ),
                  ),

                  // Professional Pill-Style TabBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2), // Recessed track
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        dividerColor: Colors.transparent, // Removes standard line
                        indicatorSize: TabBarIndicatorSize.tab,
                        // The "Pill" effect
                        indicator: BoxDecoration(
                            color: Color(0xFF2563EB), // Solid Accent
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color:Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.4),
                        labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3
                        ),
                        unselectedLabelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500
                        ),
                        tabs: _buildTabs(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _buildTabViews(isTablet, isLandscape),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageTab(bool isTablet, bool isLandscape) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: ListView(
        children: [
          _buildSelectors(isTablet, isLandscape),
          const SizedBox(height: 20),
          _buildTimetableGrid(isTablet),
        ],
      ),
    );
  }

  Widget _buildViewTab(bool isTablet, bool isLandscape) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: ListView(
        children: [
          _buildSelectors(isTablet, isLandscape),
          const SizedBox(height: 20),
          _buildViewOnlyTimetable(isTablet),
        ],
      ),
    );
  }

  Widget _buildTeacherTab(bool isTablet, bool isLandscape) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (schoolController.selectedSchool.value != null) {
        
        schoolController.loadTeachers();
      }
    });
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: ListView(
        children: [
          _buildTeacherSelector(isTablet),
          const SizedBox(height: 20),
          _buildTeacherSchedule(isTablet),
        ],
      ),
    );
  }

  Widget _buildSelectors(bool isTablet, bool isLandscape) {
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
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: Colors.indigo.shade600, size: 15),
                const SizedBox(width: 8),
                Text(
                  'Select Class & Section',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 18 : 14,
                    color: Colors.indigo.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            isLandscape && isTablet
                ? Row(
                    children: [
                      Expanded(child: _buildSchoolSelector()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildClassSelector()),
                      if (ApiPermissions.hasSectionAccess(currentUserRole)) ...[
                        const SizedBox(width: 16),
                        Expanded(child: _buildSectionSelector()),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      if(ApiPermissions.hasSectionAccess(currentUserRole)=='correspondent')
                      _buildSchoolSelector(),
                      const SizedBox(height: 12),
                      _buildClassSelector(),
                      if (ApiPermissions.hasSectionAccess(currentUserRole)) ...[
                        const SizedBox(height: 12),
                        _buildSectionSelector(),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolSelector() {
    return Obx(() {
      if (ApiPermissions.isSchoolReadOnly(currentUserRole)) {
        final school = schoolController.selectedSchool.value;
        // Show loading only when schools list is actually loading
        final schoolName = school?.name ??
            (schoolController.isLoading.value ? 'Loading...' : 'No school assigned');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
            child: Row(
        children: [
        Icon(Icons.school, color: Colors.indigo.shade600, size: 16),
      const SizedBox(width: 10),
      Expanded(
      child: Text(
      schoolName,
      style: const TextStyle(color: Colors.black87, fontSize: 12),
      ),
      ),
      ],
      ),
          );
      }
      
      return DropdownButtonFormField<School>(
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Choose School',
        prefixIcon: Icon(Icons.school, color: Colors.indigo.shade600,size: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      value: schoolController.selectedSchool.value,
      selectedItemBuilder: (context) => schoolController.schools.map((s) => Text(s.name)).toList(),
      items: schoolController.schools.map((school) {
        return DropdownMenuItem<School>(
          value: school,
          child: Row(
            children: [
              Icon(Icons.school, size: 16, color: Colors.indigo.shade600),
              const SizedBox(width: 8),
              Expanded(child: Text(school.name, overflow: TextOverflow.ellipsis)),
            ],
          ),
        );
      }).toList(),
      onChanged: (school) {
        schoolController.selectedSchool.value = school;
        selectedClass = null;
        selectedSection = null;
        // Reset teachers when school changes
        schoolController.resetTeachers();
        if (school != null) {
          schoolController.getAllClasses(school.id);
          // Load teachers for the new school
          schoolController.loadTeachers();
        }
      },
    );
    });
  }

  Widget _buildClassSelector() {
    return Obx(() {
      // Trigger class loading if school is selected but classes are empty
      if (schoolController.selectedSchool.value != null && 
          schoolController.classes.isEmpty && 
          !schoolController.isLoading.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          schoolController.getAllClasses(schoolController.selectedSchool.value!.id);
        });
      }
      
      final sortedClasses = List<SchoolClass>.from(schoolController.classes);
      sortedClasses.sort((a, b) => _compareClassNames(a.name, b.name));
      
      return DropdownButtonFormField<SchoolClass>(
        isExpanded: true,
        isDense: true,
        // 1. FORCE THE HINT WIDGET DIRECTLY HERE
        hint: Align(
          alignment: Alignment.centerLeft, // Keeps it vertically centered and left-aligned
          child: Text(
            sortedClasses.isEmpty ? 'Select school first' : 'Choose Class',
            style: TextStyle(
              fontSize: 12,        // Your desired hint font size
            ),
          ),
        ),
        decoration: InputDecoration(
          // 2. Remove hintText and hintStyle from here completely to prevent conflicts
          prefixIcon: Icon(Icons.class_, color: Colors.indigo.shade600, size: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Keeps the outer container neat
        ),
        value: selectedClass,
        items: sortedClasses.isEmpty ? [] : sortedClasses.map((cls) {
          return DropdownMenuItem<SchoolClass>(
            value: cls,
            child: Row(
              children: [
                Icon(_getClassIcon(cls.name), size: 15, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
                Text(
                  cls.name,
                  style: const TextStyle(fontSize: 12), // Matches the selected item text to the hint size
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (cls) {
          setState(() {
            selectedClass = cls;
            selectedSection = null;
          });
          if (cls != null && schoolController.selectedSchool.value != null) {
            schoolController.getAllSections(
              classId: cls.id,
              schoolId: schoolController.selectedSchool.value!.id,
            );
            timetableController.getAllTimetables(
              schoolId: schoolController.selectedSchool.value!.id,
              classId: cls.id,
              sectionId: selectedSection?.id,
            );
          }
        },
      );
    });
  }

  Widget _buildSectionSelector() {
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    
    // Hide section dropdown for roles without section access
    if (!ApiPermissions.hasSectionAccess(userRole)) {
      return SizedBox.shrink();
    }
    
    return Obx(() => DropdownButtonFormField<Section>(
      isExpanded: true,
      isDense: true,
      // FIX 1: The 'hint' property must be a direct child of DropdownButtonFormField, NOT inside InputDecoration
      hint: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Choose Section (Optional)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600, // Optional: Add a nice hint color
          ),
        ),
      ),
      decoration: InputDecoration(
        // FIX 2: Removed 'hint' and 'hintStyle' from here to prevent layout conflicts
        prefixIcon: Icon(Icons.group, color: Colors.indigo.shade600, size: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
        // Add consistent contentPadding to ensure it perfectly aligns with your Class dropdown
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
      value: selectedSection,
      items: [
        const DropdownMenuItem<Section>(
          value: null,
          child: Text('All Sections', style: TextStyle(fontSize: 12)),
        ),
        ...schoolController.sections.map((section) {
          return DropdownMenuItem<Section>(
            value: section,
            child: Text(section.name, style: TextStyle(fontSize: 12)),
          );
        }),
      ],
      onChanged: (section) {
        setState(() {
          selectedSection = section;
        });
      },
    )); // FIX 3: Removed the extra closing parenthesis that was hanging at the very end);
  }

  Widget _buildTeacherSelector(bool isTablet) {
    final TextEditingController searchController = TextEditingController();
    final filteredTeachers = <Map<String, dynamic>>[].obs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title with a modern "Label" look
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Teacher Directory',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),

        // Professional Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              filteredTeachers.value = schoolController.teachers
                  .where((t) => (t['userName'] as String)
                  .toLowerCase()
                  .contains(value.toLowerCase()))
                  .toList();
            },
            decoration: InputDecoration(
              hintText: 'Search by name or department...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.indigo.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // The List Area
        Obx(() {
          final list = searchController.text.isEmpty ? schoolController.teachers : filteredTeachers;

          if (schoolController.isLoading.value) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(strokeWidth: 3),
            ));
          }

          if (list.isEmpty) {
            return _buildEmptyState("No teachers found matching your search");
          }

          return Container(
            constraints: BoxConstraints(maxHeight: isTablet ? 500 : 350),
            padding: EdgeInsets.only(bottom: 30),
            child: ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                final teacher = list[index];
                final isSelected = selectedTeacherId == teacher['_id'];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.indigo.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.indigo.shade200 : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (!isSelected)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    leading: Hero(
                      tag: 'teacher-${teacher['_id']}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.indigo.shade400 : Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: isSelected ? Colors.indigo.shade600 : Colors.grey.shade100,
                          child: Text(
                            (teacher['userName'] as String).substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.indigo.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      teacher['userName'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isSelected ? Colors.indigo.shade900 : Colors.grey.shade800,
                      ),
                    ),
                    subtitle: Text(
                      "Teacher ID: ${teacher['_id'].toString().substring(0, 8)}...",
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: Colors.indigo.shade600)
                        : Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                    onTap: () {
                      setState(() => selectedTeacherId = teacher['_id']);
                      timetableController.getTeacherSchedule(
                        schoolId: schoolController.selectedSchool.value!.id,
                        teacherId: teacher['_id'],
                      );
                    },
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

// Custom Empty State Widget
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.person_off_rounded, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableGrid(bool isTablet) {
    if (schoolController.selectedSchool.value == null || selectedClass == null) {
      return _buildEmptyState('Select school and class to manage timetable');
    }

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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.indigo.shade600),
                    const SizedBox(width: 12),
                    Text(
                      'Weekly Timetable',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade600,
                      ),
                    ),
                  ],
                ),
                if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showAddDayDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Day'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showDeleteTimetableDialog,
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Timetable Content
          Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: _buildTimetableContent(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableContent(bool isTablet) {
    return Obx(() {
      // Check if timetable has any days added
      if (timetableController.timetables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Timetable Days Added',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Add Day" button above to create your first timetable day',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.arrow_upward,
              size: 32,
              color: Colors.indigo.shade300,
            ),
          ],
        ),
      );
      }
      
      // Get weeklySchedule from first timetable
      final timetable = timetableController.timetables.first;
      final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
      final addedDays = weeklySchedule.map((ws) => ws['day'] as String).toList();
      
      return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: isTablet ? 20 : 10,
        columns: [
          const DataColumn(label: Text('Period', style: TextStyle(fontWeight: FontWeight.bold))),
          ...addedDays.map((day) => DataColumn(
            label: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
        ],
        rows: List.generate(8, (periodIndex) {
          return DataRow(
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Period ${periodIndex + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ),
              ),
              ...addedDays.map((day) => DataCell(
                _buildPeriodCell(day, periodIndex + 1, isTablet),
              )),
            ],
          );
        }),
      ));
    });
  }

  Widget _buildPeriodCell(String day, int period, bool isTablet) {
    // Get period data from timetable
    if (timetableController.timetables.isEmpty) {
      return InkWell(
        onTap: () => _showEditPeriodDialog(day, period),
        child: Container(
          width: isTablet ? 120 : 80,
          height: 60,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Subject', style: TextStyle(fontSize: isTablet ? 12 : 10, fontWeight: FontWeight.w600)),
              Text('Teacher', style: TextStyle(fontSize: isTablet ? 10 : 8, color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    final timetable = timetableController.timetables.first;
    final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
    final daySchedule = weeklySchedule.firstWhere((ws) => ws['day'] == day, orElse: () => null);
    
    String subject = 'Subject';
    String teacher = 'Teacher';
    
    if (daySchedule != null) {
      final periods = daySchedule['periods'] as List? ?? [];
      final periodData = periods.firstWhere((p) => p['periodNumber'] == period, orElse: () => null);
      
      if (periodData != null) {
        subject = periodData['subjectName'] ?? 'Subject';
        final teacherData = periodData['teacherId'];
        if (teacherData is Map) {
          teacher = teacherData['userName'] ?? 'Teacher';
        }
      }
    }
    
    return InkWell(
      onTap: ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod')
          ? () => _showEditPeriodDialog(day, period)
          : null,
      child: Container(
        width: isTablet ? 120 : 80,
        height: 60,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: subject != 'Subject' ? Colors.indigo.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              subject,
              style: TextStyle(
                fontSize: isTablet ? 12 : 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              teacher,
              style: TextStyle(
                fontSize: isTablet ? 10 : 8,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOnlyTimetable(bool isTablet) {
    if (schoolController.selectedSchool.value == null || selectedClass == null) {
      return _buildEmptyState('Select school and class to view timetable');
    }

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
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.blue.shade600,size: 13,),
                    const SizedBox(width: 12),
                    Text(
                      'Timetable View',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
                if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showDeleteTimetableDialog,
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete Timetable'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: _buildReadOnlyTimetable(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyTimetable(bool isTablet) {
    return Obx(() {
      if (timetableController.isLoading.value) {
        return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
      }
      
      if (timetableController.timetables.isEmpty) {
        return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [Icon(Icons.schedule, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16), Text('No timetable data', style: TextStyle(fontSize: 16, color: Colors.grey))])));
      }

      // Get weeklySchedule from timetable
      final timetable = timetableController.timetables.first;
      final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
      final addedDays = weeklySchedule.map((ws) => ws['day'] as String).toList();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 50),
          child: DataTable(
            columnSpacing: isTablet ? 20 : 10,
            dataRowMinHeight: 70,
            dataRowMaxHeight: 70,
            columns: [
              const DataColumn(label: Text('Period', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12))),
              ...addedDays.map((day) => DataColumn(
                label: Text(day, style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 12)),
              )),
            ],
            rows: List.generate(8, (periodIndex) {
              final periodNumber = periodIndex + 1;
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Period $periodNumber',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),
                  ...weeklySchedule.map((daySchedule) {
                    final periods = daySchedule['periods'] as List? ?? [];
                    final period = periods.firstWhere(
                      (p) => p['periodNumber'] == periodNumber,
                      orElse: () => null,
                    );
                    
                    String subject = '-';
                    String teacher = '-';
                    
                    if (period != null) {
                      subject = period['subjectName'] ?? '-';
                      final teacherData = period['teacherId'];
                      if (teacherData is Map) {
                        teacher = teacherData['userName'] ?? '-';
                      }
                    }
                    
                    return DataCell(
                      InkWell(
                        onTap: ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher')
                            ? () => _showAssignTeacherDialog(daySchedule['day'], periodNumber)
                            : null,
                        child: Container(
                          width: isTablet ? 120 : 80,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: period != null ? Colors.blue.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                teacher,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ),
        ),
      );
    });
  }

  Widget _buildTeacherSchedule(bool isTablet) {
    return Obx(() {
      
      
      
      if (timetableController.teacherSchedule.isEmpty) {
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
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    Text(
                      'Teacher Schedule',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: _buildEmptyState1('Select a teacher to view their schedule'),
              ),
            ],
          ),
        );
      }

      // Display teacher schedule
      final schedule = timetableController.teacherSchedule.first;
      final weeklySchedule = schedule['weeklySchedule'] as List? ?? [];
      final addedDays = weeklySchedule.map((ws) => ws['day'] as String).toList();

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
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 11),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.green.shade600,size: 14,),
                  const SizedBox(width: 12),
                  Text(
                    'Teacher Schedule',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: isTablet ? 20 : 10,
                  dataRowMinHeight: 70,
                  dataRowMaxHeight: 70,
                  columns: [
                    const DataColumn(label: Text('Period', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 13))),
                    ...addedDays.map((day) => DataColumn(
                      label: Text(day, style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 13)),
                    )),
                  ],
                  rows: List.generate(8, (periodIndex) {
                    final periodNumber = periodIndex + 1;
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Period $periodNumber',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ),
                        ...weeklySchedule.map((daySchedule) {
                          final periods = daySchedule['periods'] as List? ?? [];
                          final period = periods.firstWhere(
                            (p) => p['periodNumber'] == periodNumber,
                            orElse: () => null,
                          );
                          
                          String subject = '-';
                          bool isYourPeriod = false;
                          
                          if (period != null) {
                            subject = period['subjectName'] ?? '-';
                            isYourPeriod = period['isYourPeriod'] ?? false;
                          }
                          
                          return DataCell(
                            Container(
                              margin: EdgeInsets.all(8),
                              width: isTablet ? 120 : 80,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isYourPeriod ? Colors.green.shade100 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isYourPeriod ? Colors.green.shade600 : Colors.grey.shade200,
                                  width: isYourPeriod ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  subject,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isYourPeriod ? FontWeight.bold : FontWeight.w600,
                                    color: isYourPeriod ? Colors.green.shade700 : Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState1(String message) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDayDialog() {
    String selectedDay = days.first;
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Day to Timetable'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              value: selectedDay,
              decoration: InputDecoration(
                labelText: 'Select Day',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              selectedItemBuilder: (context) => days.map((day) => Text(day)).toList(),
              items: days.map((day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.indigo.shade600),
                      const SizedBox(width: 8),
                      Text(day),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (day) {
                if (day != null) {
                  setState(() => selectedDay = day);
                }
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (schoolController.selectedSchool.value != null && selectedClass != null) {
                await timetableController.addDay(
                  schoolId: schoolController.selectedSchool.value!.id,
                  classId: selectedClass!.id,
                  sectionId: selectedSection?.id,
                  day: selectedDay,
                );
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTimetableDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Timetable'),
        content: Text('Are you sure you want to delete the entire timetable for ${selectedClass?.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (timetableController.timetables.isNotEmpty) {
                final timetableId = timetableController.timetables.first['_id'];
                
                Get.back();
                final success = await timetableController.deleteTimetable(timetableId);
                if (success && schoolController.selectedSchool.value != null && selectedClass != null) {
                  await timetableController.getAllTimetables(
                    schoolId: schoolController.selectedSchool.value!.id,
                    classId: selectedClass!.id,
                    sectionId: selectedSection?.id,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAssignTeacherDialog(String day, int period) {
    if (schoolController.selectedSchool.value != null) {
      schoolController.loadTeachers();
    }
    
    final searchController = TextEditingController();
    String? selectedTeacherId;
    final filteredTeachers = <Map<String, dynamic>>[].obs;
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          if (filteredTeachers.isEmpty) {
            filteredTeachers.value = schoolController.teachers;
          }
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Assign Teacher - $day Period $period'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Teacher',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        filteredTeachers.value = schoolController.teachers;
                      } else {
                        filteredTeachers.value = schoolController.teachers
                            .where((t) => (t['userName'] as String)
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Obx(() => Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: schoolController.teachers.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(child: Text('Loading...', style: TextStyle(fontSize: 11))),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTeachers.length,
                        itemBuilder: (context, index) {
                          final teacher = filteredTeachers[index];
                          final isSelected = selectedTeacherId == teacher['_id'];

                          return InkWell(
                            onTap: () => setState(() => selectedTeacherId = teacher['_id']),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 9, // 👈 smaller circle
                                  backgroundColor: isSelected ? Colors.blue.shade600 : Colors.blue.shade100,
                                  child: Icon(
                                    Icons.person,
                                    color: isSelected ? Colors.white : Colors.blue.shade600,
                                    size: 10, // 👈 smaller icon
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    teacher['userName'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 11, // 👈 smaller font
                                      color: isSelected ? Colors.blue.shade800 : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle, color: Colors.blue.shade600, size: 12), // 👈 smaller check
                              ]),
                            ),
                          );
                        },
                      ),
                    )),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedTeacherId == null) {
                    Get.snackbar('Error', 'Please select a teacher');
                    return;
                  }
                  
                  if (timetableController.timetables.isEmpty) {
                    Get.snackbar('Error', 'No timetable found');
                    return;
                  }
                  
                  final timetable = timetableController.timetables.first;
                  final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
                  final daySchedule = weeklySchedule.firstWhere((ws) => ws['day'] == day, orElse: () => null);
                  
                  if (daySchedule == null) {
                    Get.snackbar('Error', 'Day not found');
                    return;
                  }
                  
                  final dayId = daySchedule['_id'] as String?;
                  if (dayId == null) {
                    Get.snackbar('Error', 'Invalid timetable data');
                    return;
                  }
                  
                  Get.back();
                  
                  final success = await timetableController.assignTeacher(
                    mode: 'add',
                    schoolId: schoolController.selectedSchool.value!.id,
                    classId: selectedClass!.id,
                    sectionId: selectedSection?.id,
                    weeklyScheduleId: dayId,
                    periodNumber: period,
                    teacherId: selectedTeacherId!,
                  );
                  
                  if (success && schoolController.selectedSchool.value != null && selectedClass != null) {
                    await timetableController.getAllTimetables(
                      schoolId: schoolController.selectedSchool.value!.id,
                      classId: selectedClass!.id,
                      sectionId: selectedSection?.id,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Assign'),
              ),
            ],
          );
        })
    );
  }

  void _showEditPeriodDialog(String day, int period) {
    if (schoolController.selectedSchool.value != null) {
      
      schoolController.loadTeachers();
    }
    
    // Get existing period data
    String existingSubject = '';
    String? existingTeacherId;
    
    if (timetableController.timetables.isNotEmpty) {
      final timetable = timetableController.timetables.first;
      final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
      final daySchedule = weeklySchedule.firstWhere((ws) => ws['day'] == day, orElse: () => null);
      
      if (daySchedule != null) {
        final periods = daySchedule['periods'] as List? ?? [];
        final periodData = periods.firstWhere((p) => p['periodNumber'] == period, orElse: () => null);
        
        if (periodData != null) {
          existingSubject = periodData['subjectName'] ?? '';
          final teacherData = periodData['teacherId'];
          if (teacherData is Map) {
            existingTeacherId = teacherData['_id'];
          }
        }
      }
    }
    
    final subjectController = TextEditingController(text: existingSubject);
    final searchController = TextEditingController();
    String? selectedTeacherId = existingTeacherId;
    final filteredTeachers = <Map<String, dynamic>>[].obs;
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          if (filteredTeachers.isEmpty) {
            filteredTeachers.value = schoolController.teachers;
          }
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Edit Period - $day Period $period'),
            content: SizedBox(
              width: 300,
              height: 350,
              child: Column(
                children: [
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Teacher',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        filteredTeachers.value = schoolController.teachers;
                      } else {
                        filteredTeachers.value = schoolController.teachers
                            .where((t) =>
                            (t['userName'] as String)
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Obx(() => Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: schoolController.teachers.isEmpty
                          ? Center(child: Text('Loading...'))
                          : ListView.builder(
                        itemCount: filteredTeachers.length,
                        itemBuilder: (context, index) {
                          final teacher = filteredTeachers[index];
                          final isSelected = selectedTeacherId == teacher['_id'];
                          return ListTile(
                            selected: isSelected,
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? Colors.indigo.shade600 : Colors.indigo.shade100,
                              child: Icon(Icons.person, color: isSelected ? Colors.white : Colors.indigo.shade600, size: 20),
                            ),
                            title: Text(teacher['userName'] ?? 'Unknown'),
                            trailing: isSelected ? Icon(Icons.check_circle, color: Colors.indigo.shade600) : null,
                            onTap: () {
                              setState(() => selectedTeacherId = teacher['_id']);
                            },
                          );
                        },
                      ),
                    )),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              if (ApiPermissions.hasApiAccess(
                  currentUserRole, 'DELETE /api/timetable/deleteperiod'))
                TextButton(
                  onPressed: () {
                    Get.back();
                    Get.snackbar('Success', 'Period deleted');
                  },
                  child: const Text(
                      'Delete', style: TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: () async {
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  if (subjectController.text.isEmpty) {
                    Get.snackbar('Error', 'Please enter a subject');
                    return;
                  }
                  
                  if (selectedTeacherId == null) {
                    Get.snackbar('Error', 'Please select a teacher');
                    return;
                  }
                  
                  if (schoolController.selectedSchool.value == null || selectedClass == null) {
                    Get.snackbar('Error', 'School and class must be selected');
                    return;
                  }
                  
                  // Get weeklyScheduleId and dayId from timetable
                  if (timetableController.timetables.isEmpty) {
                    Get.snackbar('Error', 'No timetable found. Please add a day first.');
                    return;
                  }
                  
                  final timetable = timetableController.timetables.first;
                  final timetableId = timetable['_id'] as String?;
                  final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
                  
                  
                  
                  
                  // Find the specific day in weeklySchedule
                  final daySchedule = weeklySchedule.firstWhere(
                    (ws) => ws['day'] == day,
                    orElse: () => null,
                  );
                  
                  if (daySchedule == null) {
                    Get.snackbar('Error', 'Day "$day" not found in timetable. Please add it first.');
                    return;
                  }
                  
                  final dayId = daySchedule['_id'] as String?;
                  
                  if (timetableId == null || dayId == null) {
                    Get.snackbar('Error', 'Invalid timetable data');
                    return;
                  }
                  
                  
                  
                  Get.back();
                  
                  final success = await timetableController.updatePeriod(
                    schoolId: schoolController.selectedSchool.value!.id,
                    classId: selectedClass!.id,
                    sectionId: selectedSection?.id,
                    weeklyScheduleId: dayId,  // Use dayId instead of timetableId
                    day: day,
                    periodData: {
                      'periodNumber': period,
                      'subjectName': subjectController.text,
                      'teacherId': selectedTeacherId,
                    },
                  );
                  
                  if (success) {
                    // Reload timetable
                    await timetableController.getAllTimetables(
                      schoolId: schoolController.selectedSchool.value!.id,
                      classId: selectedClass!.id,
                      sectionId: selectedSection?.id,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        })
    );
  }
}

