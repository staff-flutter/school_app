import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/school_controller.dart';
import '../controllers/timetable_controller.dart';
import '../controllers/teacher_controller.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/rbac/api_rbac.dart';
import '../data/models/school_models.dart';

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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_calendar, size: 18),
            SizedBox(width: 8),
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
            Icon(Icons.view_list, size: 18),
            SizedBox(width: 8),
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
            Icon(Icons.person, size: 18),
            SizedBox(width: 8),
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
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.appBarGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD8D5E8).withOpacity(0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Timetable Management',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Manage class schedules and periods',
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
                  ),
                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.indigo.shade600,
                      unselectedLabelColor: Colors.white.withOpacity(0.7),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      tabs: _buildTabs(),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                Icon(Icons.filter_list, color: Colors.indigo.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Select Class & Section',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 18 : 16,
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
        final schoolName = schoolController.selectedSchool.value?.name ?? 'Loading...';
        return TextFormField(
          initialValue: schoolName,
          decoration: InputDecoration(
            labelText: 'School',
            prefixIcon: Icon(Icons.school, color: Colors.indigo.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          enabled: false,
          style: TextStyle(color: Colors.black87),
        );
      }
      
      return DropdownButtonFormField<School>(
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Choose School',
        prefixIcon: Icon(Icons.school, color: Colors.indigo.shade600),
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
              Icon(Icons.school, size: 18, color: Colors.indigo.shade600),
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
        decoration: InputDecoration(
          hintText: sortedClasses.isEmpty ? 'Select school first' : 'Choose Class',
          prefixIcon: Icon(Icons.class_, color: Colors.indigo.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        value: selectedClass,
        items: sortedClasses.isEmpty ? [] : sortedClasses.map((cls) {
          return DropdownMenuItem<SchoolClass>(
            value: cls,
            child: Row(
              children: [
                Icon(_getClassIcon(cls.name), size: 20, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
                Text(cls.name),
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
            // Load timetable when class is selected
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
      decoration: InputDecoration(
        hintText: 'Choose Section (Optional)',
        prefixIcon: Icon(Icons.group, color: Colors.indigo.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      value: selectedSection,
      items: [
        const DropdownMenuItem<Section>(
          value: null,
          child: Text('All Sections'),
        ),
        ...schoolController.sections.map((section) {
          return DropdownMenuItem<Section>(
            value: section,
            child: Text(section.name),
          );
        }),
      ],
      onChanged: (section) {
        setState(() {
          selectedSection = section;
        });
      },
    ));
  }

  Widget _buildTeacherSelector(bool isTablet) {
    final searchController = TextEditingController();
    final filteredTeachers = <Map<String, dynamic>>[].obs;

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
                Icon(Icons.person, color: Colors.indigo.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Select Teacher',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 18 : 16,
                    color: Colors.indigo.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (filteredTeachers.isEmpty) {
                filteredTeachers.value = schoolController.teachers;
              }
              return Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search teacher...',
                      prefixIcon: Icon(Icons.search, color: Colors.indigo.shade600),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
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
                  Container(
                    constraints: BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: schoolController.teachers.isEmpty
                        ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No teachers found')))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredTeachers.length,
                            itemBuilder: (context, index) {
                              final teacher = filteredTeachers[index];
                              final isSelected = selectedTeacherId == teacher['_id'];
                              return ListTile(
                                selected: isSelected,
                                tileColor: isSelected ? Colors.green.shade50 : null,
                                leading: CircleAvatar(
                                  backgroundColor: isSelected ? Colors.green.shade600 : Colors.indigo.shade100,
                                  child: Icon(Icons.person, color: isSelected ? Colors.white : Colors.indigo.shade600, size: 20),
                                ),
                                title: Text(
                                  teacher['userName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.green.shade700 : Colors.black,
                                  ),
                                ),
                                trailing: isSelected 
                                    ? Icon(Icons.check_circle, color: Colors.green.shade600, size: 20)
                                    : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                onTap: () {
                                  setState(() {
                                    selectedTeacherId = teacher['_id'];
                                  });
                                  if (schoolController.selectedSchool.value != null) {
                                    timetableController.getTeacherSchedule(
                                      schoolId: schoolController.selectedSchool.value!.id,
                                      teacherId: teacher['_id'],
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            }),
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
                    Icon(Icons.visibility, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Text(
                      'Timetable View',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
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
              const DataColumn(label: Text('Period', style: TextStyle(fontWeight: FontWeight.bold))),
              ...addedDays.map((day) => DataColumn(
                label: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                child: _buildEmptyState('Select a teacher to view their schedule'),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: isTablet ? 20 : 10,
                  dataRowMinHeight: 70,
                  dataRowMaxHeight: 70,
                  columns: [
                    const DataColumn(label: Text('Period', style: TextStyle(fontWeight: FontWeight.bold))),
                    ...addedDays.map((day) => DataColumn(
                      label: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildEmptyState(String message) {
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
                              backgroundColor: isSelected ? Colors.blue.shade600 : Colors.blue.shade100,
                              child: Icon(Icons.person, color: isSelected ? Colors.white : Colors.blue.shade600, size: 20),
                            ),
                            title: Text(teacher['userName'] ?? 'Unknown'),
                            trailing: isSelected ? Icon(Icons.check_circle, color: Colors.blue.shade600) : null,
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

