import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:school_app/app/core/widgets/gradient_card.dart';
import 'dart:io';
import '../../../controllers/school_controller.dart';
import '../../../controllers/subscription_controller.dart';
import '../../../controllers/club_controller.dart';
import '../../../views/subscription_management_view.dart';
import '../controllers/clubs_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_wrapper.dart';

import '../../../data/models/school_models.dart' hide Club;
import '../../../data/models/student_model.dart';
import '../../../data/models/club_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../controllers/my_children_controller.dart';
import 'club_detail_view.dart';
import 'video_detail_view.dart';

class ClubsActivitiesView extends GetView<ClubsController> {
  const ClubsActivitiesView({super.key});

  void _populateClassesFromChildren(SchoolController schoolController, MyChildrenController myChildrenController) {
    final classMap = <String, SchoolClass>{};
    
    for (var child in myChildrenController.children) {
      final classId = child['classId'];
      final className = child['className'];
      
      if (classId != null && classId.toString().isNotEmpty && className != null) {
        classMap[classId.toString()] = SchoolClass(
          id: classId.toString(),
          name: className.toString(),
          schoolId: schoolController.selectedSchool.value?.id ?? '',
          order: 0,
          hasSections: false,
        );
      }
    }
    
    if (classMap.isNotEmpty) {
      schoolController.classes.value = classMap.values.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolController = Get.find<SchoolController>();
    final subscriptionController = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : null;

    if (schoolController.schools.isEmpty && !schoolController.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        schoolController.getAllSchools();
      });
    }

    final userRole = Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
    final isParentUser = userRole == 'parent';

    if (isParentUser && Get.isRegistered<MyChildrenController>()) {
      final myChildrenController = Get.find<MyChildrenController>();
      if (myChildrenController.children.isEmpty && !myChildrenController.isLoading.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await myChildrenController.loadMyChildren();
          _populateClassesFromChildren(schoolController, myChildrenController);
        });
      } else if (myChildrenController.children.isNotEmpty && schoolController.classes.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _populateClassesFromChildren(schoolController, myChildrenController);
        });
      }
    }

    if (!isParentUser && schoolController.selectedSchool.value != null &&
        schoolController.classes.isEmpty &&
        !schoolController.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        schoolController.getAllClasses(schoolController.selectedSchool.value!.id);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Obx(() {
          final selectedSchool = schoolController.selectedSchool.value;
          if (selectedSchool == null) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildModernHeader(context),
                  _buildSchoolSelector(context, schoolController),
                  _buildSelectSchoolPrompt(),
                ],
              ),
            );
          }

          final requiresSubscriptionCheck = ['correspondent', 'principal'].contains(userRole);

          if (requiresSubscriptionCheck) {
            final hasAccess = subscriptionController?.hasModuleAccess('club') ?? false;
            if (!hasAccess) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildModernHeader(context),
                    _buildSchoolSelector(context, schoolController),
                    _buildUpgradeRequiredWidget(context, 'Club'),
                  ],
                ),
              );
            }
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(child: _buildModernHeader(context)),
                SliverToBoxAdapter(child: _buildSchoolSelector(context, schoolController)),
              ];
            },
            body: _buildTabContent(context),
          );
        }),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      padding: EdgeInsets.all(isTablet ? 32 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clubs & Activities',
            style: TextStyle(
              fontSize: isTablet ? 32 : 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage school clubs and activities',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolSelector(BuildContext context, SchoolController schoolController) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final authController = Get.find<AuthController>();
    final isCorrespondent = authController.user.value?.role == 'correspondent';
    
    return Container(
      margin: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Obx(() {
          if (schoolController.isLoading.value && schoolController.schools.isEmpty) {
            return const Center(child: LinearProgressIndicator());
          }

          if (schoolController.schools.isEmpty) {
            return const Text("No schools available");
          }

          if (isCorrespondent) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select School',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: DropdownButtonFormField<School>(
                    value: schoolController.schools.contains(schoolController.selectedSchool.value)
                        ? schoolController.selectedSchool.value
                        : null,
                    hint: const Text('Choose your school'),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: schoolController.schools.map((school) {
                      return DropdownMenuItem<School>(
                        value: school,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: school.logo != null && school.logo!['url'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        school.logo!['url'],
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(Icons.school, size: 16, color: Colors.grey.shade600),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(Icons.school, size: 16, color: Colors.grey.shade600),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                school.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (School? value) {
                      if (value != null) {
                        schoolController.selectedSchool.value = value;
                        schoolController.classes.clear();
                        schoolController.getAllClasses(value.id);
                        if (Get.isRegistered<SubscriptionController>()) {
                          Get.find<SubscriptionController>().loadSubscription(value.id);
                        }
                      }
                    },
                  ),
                ),
              ],
            );
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'School',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (schoolController.selectedSchool.value?.logo != null &&
                      schoolController.selectedSchool.value!.logo!['url'] != null) ...[
                    GestureDetector(
                      onTap: () => _showFullScreenImage(context, schoolController.selectedSchool.value!.logo!['url']),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          schoolController.selectedSchool.value!.logo!['url'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.school, size: 20, color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.school, size: 20, color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(width: 12),
                  Text(
                    schoolController.selectedSchool.value?.name ?? 'Loading...',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSelectSchoolPrompt() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.04),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select a School',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a school to view clubs and activities',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(18, 24, 18, 0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF0F172A),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF64748B).withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              indicatorPadding: const EdgeInsets.all(2),
              labelPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Clubs'),
                Tab(text: 'Classes'),
                Tab(text: 'Activities'),
                Tab(text: 'Events'),
                Tab(text: 'Members'),
                Tab(text: 'Students'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _buildClubsTab(context),
                _buildRecordedClassesTab(context),
                _buildActivitiesTab(context),
                _buildEventsTab(context),
                _buildMembershipsTab(context),
                _buildStudentsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubsTab(BuildContext context) {
    final selectedCategory = 'All'.obs;
    final selectedClass = Rxn<SchoolClass>();
    final searchQuery = ''.obs;
    final authController = Get.find<AuthController>();
    final schoolController = Get.find<SchoolController>();
    final canManageClubs = authController.hasPermission('CLUBS:CREATE') ||
                          authController.hasPermission('CLUBS:EDIT') ||
                          authController.hasPermission('CLUBS:DELETE');
    
    final isParent = authController.user.value?.role == 'parent';
    final myChildrenController = isParent && Get.isRegistered<MyChildrenController>()
        ? Get.find<MyChildrenController>()
        : null;

    final linkedChildrenClasses = <String, String>{};
    if (isParent && myChildrenController != null) {
      for (var child in myChildrenController.children) {
        final className = child['className']?.toString();
        final classId = child['classId']?.toString();
        if (className != null && className.isNotEmpty && classId != null && classId.isNotEmpty) {
          linkedChildrenClasses[classId] = className;
        }
      }
    }

    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.all(isTablet ? 20 : 16),
            padding: EdgeInsets.all(isTablet ? 28 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'School Clubs',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (canManageClubs)
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => _showAddClubDialog(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Add Club',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                Obx(() {
                  List<SchoolClass> availableClasses;
                  if (isParent && linkedChildrenClasses.isNotEmpty) {
                    availableClasses = linkedChildrenClasses.entries.map((entry) {
                      return SchoolClass(
                        id: entry.key,
                        name: entry.value,
                        order: 0,
                        hasSections: true,
                        schoolId: schoolController.selectedSchool.value?.id ?? '',
                      );
                    }).toList();
                  } else {
                    availableClasses = schoolController.classes;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: DropdownButtonFormField<SchoolClass>(
                      value: selectedClass.value,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Class',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      isExpanded: true,
                      hint: const Text('All Classes'),
                      items: [
                        const DropdownMenuItem<SchoolClass>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.class_, size: 18, color: Color(0xFF3B82F6)),
                              SizedBox(width: 8),
                              Text('All Classes', style: TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        ...availableClasses.map((schoolClass) {
                          return DropdownMenuItem<SchoolClass>(
                            value: schoolClass,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.class_, size: 18, color: Color(0xFF3B82F6)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    schoolClass.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (SchoolClass? value) {
                        selectedClass.value = value;
                      },
                    ),
                  );
                }),
                
                const SizedBox(height: 12),
                
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search clubs...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) => searchQuery.value = value,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        Obx(() {
          final clubsController = Get.find<ClubsController>();
          
          if (clubsController.clubs.isNotEmpty) {
            
          }
          if (clubsController.isLoading.value) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    Text('Loading clubs...', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            );
          }

          var filteredClubs = clubsController.clubs.toList();
          
          if (selectedClass.value != null) {
            filteredClubs = clubsController.getClubsByClass(selectedClass.value!.id);
          }
          
          if (selectedCategory.value != 'All') {
            filteredClubs = filteredClubs.where((club) => club.category == selectedCategory.value).toList();
          }
          
          if (searchQuery.value.isNotEmpty) {
            final query = searchQuery.value.toLowerCase();
            filteredClubs = filteredClubs.where((club) => 
              club.name.toLowerCase().contains(query) ||
              club.description.toLowerCase().contains(query) ||
              club.category.toLowerCase().contains(query)
            ).toList();
          }

          if (filteredClubs.isEmpty) {
            return SliverFillRemaining(
              child: _buildEmptyState(
                title: 'No clubs found',
                subtitle: searchQuery.value.isNotEmpty 
                    ? 'Try adjusting your search terms'
                    : 'Create clubs to get started',
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildModernClubCard(context, filteredClubs[index], canManageClubs),
                childCount: filteredClubs.length,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildModernClubCard(BuildContext context, Club club, bool canManageClubs) {
    // Generate dynamic colors based on club ID
    final colorPairs = [
      [Color(0xFF667eea), Color(0xFF764ba2)],
      [Color(0xFF4facfe), Color(0xFF00f2fe)],
      [Color(0xFF43e97b), Color(0xFF38f9d7)],
      [Color(0xFF89f7fe), Color(0xFF66a6ff)],
      [Color(0xFF6a11cb), Color(0xFF2575fc)],
      [Color(0xFF00c6ff), Color(0xFF0072ff)],
      [Color(0xFF11998e), Color(0xFF38ef7d)],
      [Color(0xFFf093fb), Color(0xFFf5576c)],
      [Color(0xFF667eea), Color(0xFF764ba2)],
      [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ];
    
    final colorIndex = club.id.hashCode.abs() % colorPairs.length;
    final gradient = LinearGradient(
      colors: colorPairs[colorIndex],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return GestureDetector(
      onTap: () {
        Get.to(() => ClubDetailView(), arguments: club.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorPairs[colorIndex][0].withOpacity(0.1),
              colorPairs[colorIndex][1].withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorPairs[colorIndex][0].withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Get.to(() => ClubDetailView(), arguments: club.id);
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colorPairs[colorIndex][0].withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          club.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (canManageClubs)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showEditClubDialog(context, club);
                                break;
                              case 'delete':
                                _showDeleteClubConfirmation(context, club);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    club.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    club.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  _buildClubInfo(context, club),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClubInfo(BuildContext context, Club club) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF64748B), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coordinator: ${club.coordinator.isEmpty ? 'Not assigned' : club.coordinator}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF64748B), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Meeting: ${club.meetingDay ?? 'TBD'} at ${club.meetingTime ?? 'TBD'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF64748B), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Location: ${club.location.isEmpty ? 'Not specified' : club.location}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordedClassesTab(BuildContext context) {
    final selectedClass = Rxn<SchoolClass>();
    final selectedClub = 'All'.obs;
    final searchQuery = ''.obs;
    final authController = Get.find<AuthController>();
    final schoolController = Get.find<SchoolController>();
    final isParent = authController.user.value?.role == 'parent';
    final canManageClubs = authController.hasPermission('CLUBS:UPLOAD_VIDEO') ||
                          authController.hasPermission('CLUBS:EDIT');

    final myChildrenController = isParent && Get.isRegistered<MyChildrenController>()
        ? Get.find<MyChildrenController>()
        : null;

    final linkedChildrenClasses = <String, String>{};
    if (isParent && myChildrenController != null) {
      for (var child in myChildrenController.children) {
        final className = child['className']?.toString();
        final classId = child['classId']?.toString();
        if (className != null && className.isNotEmpty && classId != null && classId.isNotEmpty) {
          linkedChildrenClasses[classId] = className;
        }
      }
    }

    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(isTablet ? 20 : 16),
            padding: EdgeInsets.all(isTablet ? 28 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recorded Classes',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (canManageClubs)
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => _showUploadVideoDialog(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Upload Video',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Obx(() {
                  List<SchoolClass> filteredClasses;
                  if (isParent && linkedChildrenClasses.isNotEmpty) {
                    filteredClasses = linkedChildrenClasses.entries.map((entry) {
                      return SchoolClass(
                        id: entry.key,
                        name: entry.value,
                        order: 0,
                        hasSections: true,
                        schoolId: schoolController.selectedSchool.value?.id ?? '',
                      );
                    }).toList();
                  } else {
                    filteredClasses = schoolController.classes;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: DropdownButtonFormField<SchoolClass>(
                      value: selectedClass.value,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Class',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      isExpanded: true,
                      hint: const Text('All Classes'),
                      items: [
                        const DropdownMenuItem<SchoolClass>(
                          value: null,
                          child: Text('All Classes', style: TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        ...filteredClasses.map((schoolClass) {
                          return DropdownMenuItem<SchoolClass>(
                            value: schoolClass,
                            child: Text(
                              schoolClass.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (SchoolClass? value) {
                        selectedClass.value = value;
                        selectedClub.value = 'All';
                      },
                    ),
                  );
                }),
                
                const SizedBox(height: 16),
                
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search videos...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) => searchQuery.value = value,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Obx(() {
              final clubsController = Get.find<ClubsController>();
              if (clubsController.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      const SizedBox(height: 16),
                      Text('Loading videos...', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }
              
              var filteredClasses = clubsController.getRecordedClassesByCategory('All');

              if (selectedClass.value != null) {
                final classClubs = clubsController.getClubsByClass(selectedClass.value!.id);
                final classClubIds = classClubs.map((c) => c.id).toList();
                filteredClasses = filteredClasses.where((cls) => classClubIds.contains(cls.clubId)).toList();
              }
              
              if (selectedClub.value != 'All') {
                filteredClasses = filteredClasses.where((cls) => cls.clubName == selectedClub.value).toList();
              }
              
              if (searchQuery.value.isNotEmpty) {
                final query = searchQuery.value.toLowerCase();
                filteredClasses = filteredClasses.where((cls) => 
                  cls.title.toLowerCase().contains(query) ||
                  cls.clubName.toLowerCase().contains(query) ||
                  cls.instructor.toLowerCase().contains(query)
                ).toList();
              }
              
              if (filteredClasses.isEmpty) {
                return _buildEmptyState(
                  title: 'No recorded classes found',
                  subtitle: searchQuery.value.isNotEmpty 
                      ? 'Try adjusting your search terms'
                      : 'Upload videos to get started',
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredClasses.length,
                itemBuilder: (context, index) {
                  return _buildModernVideoCard(context, filteredClasses[index], canManageClubs);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab(BuildContext context) {
    final selectedStatus = 'All'.obs;
    final searchQuery = ''.obs;
    
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(isTablet ? 20 : 16),
            padding: EdgeInsets.all(isTablet ? 28 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Club Activities',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 24),
                
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search activities...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) => searchQuery.value = value,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Obx(() {
              final clubsController = Get.find<ClubsController>();
              var filteredActivities = clubsController.getActivitiesByStatus(selectedStatus.value);
              if (searchQuery.value.isNotEmpty) {
                final query = searchQuery.value.toLowerCase();
                filteredActivities = filteredActivities.where((activity) => 
                  activity.title.toLowerCase().contains(query) ||
                  activity.clubName.toLowerCase().contains(query)
                ).toList();
              }
              
              if (filteredActivities.isEmpty) {
                return _buildEmptyState(
                  title: 'No activities found',
                  subtitle: searchQuery.value.isNotEmpty 
                      ? 'Try adjusting your search terms'
                      : 'Create activities to get started',
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredActivities.length,
                itemBuilder: (context, index) {
                  return _buildModernActivityCard(context, filteredActivities[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(BuildContext context) {
    final searchQuery = ''.obs;
    
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(isTablet ? 20 : 16),
            padding: EdgeInsets.all(isTablet ? 28 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'School Events',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 24),
                
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search events...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) => searchQuery.value = value,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Obx(() {
              final clubsController = Get.find<ClubsController>();
              var filteredEvents = clubsController.events.toList();
              if (searchQuery.value.isNotEmpty) {
                final query = searchQuery.value.toLowerCase();
                filteredEvents = filteredEvents.where((event) => 
                  event.title.toLowerCase().contains(query) ||
                  event.description.toLowerCase().contains(query) ||
                  event.category.toLowerCase().contains(query)
                ).toList();
              }
              
              if (filteredEvents.isEmpty) {
                return _buildEmptyState(
                  title: 'No events found',
                  subtitle: searchQuery.value.isNotEmpty 
                      ? 'Try adjusting your search terms'
                      : 'Create events to get started',
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  return _buildModernEventCard(context, filteredEvents[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipsTab(BuildContext context) {
    final searchQuery = ''.obs;
    
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(isTablet ? 20 : 16),
            padding: EdgeInsets.all(isTablet ? 28 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Club Memberships',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 24),
                
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search members...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) => searchQuery.value = value,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Obx(() {
              final clubsController = Get.find<ClubsController>();
              var filteredMemberships = clubsController.memberships.toList();
              if (searchQuery.value.isNotEmpty) {
                final query = searchQuery.value.toLowerCase();
                filteredMemberships = filteredMemberships.where((membership) => 
                  membership.studentName.toLowerCase().contains(query) ||
                  membership.clubName.toLowerCase().contains(query) ||
                  membership.role.toLowerCase().contains(query)
                ).toList();
              }
              
              if (filteredMemberships.isEmpty) {
                return _buildEmptyState(
                  title: 'No memberships found',
                  subtitle: searchQuery.value.isNotEmpty 
                      ? 'Try adjusting your search terms'
                      : 'Join clubs to see memberships',
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredMemberships.length,
                itemBuilder: (context, index) {
                  return _buildModernMembershipCard(context, filteredMemberships[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab(BuildContext context) {
    final selectedClass = Rxn<SchoolClass>();
    final searchQuery = ''.obs;
    final schoolController = Get.find<SchoolController>();
    final authController = Get.find<AuthController>();
    final canManageClubs = authController.hasPermission('CLUBS:CREATE') ||
                          authController.hasPermission('CLUBS:EDIT') ||
                          authController.hasPermission('CLUBS:DELETE');
    
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(isTablet ? 20 : 16),
            padding: EdgeInsets.all(isTablet ? 28 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Club Management',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 24),
                
                Obx(() {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: DropdownButtonFormField<SchoolClass>(
                      value: selectedClass.value,
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      isExpanded: true,
                      hint: const Text('Choose a class to manage clubs'),
                      items: [
                        ...schoolController.classes.map((schoolClass) {
                          return DropdownMenuItem<SchoolClass>(
                            value: schoolClass,
                            child: Text(
                              '${schoolClass.name} (${schoolClass.studentCount ?? 0} students)',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (SchoolClass? value) {
                        selectedClass.value = value;
                        if (value != null) {
                          schoolController.getAllStudents(
                            schoolId: schoolController.selectedSchool.value!.id,
                            classId: value.id,
                          );
                        }
                      },
                    ),
                  );
                }),
                
                const SizedBox(height: 16),
                
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search students...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) => searchQuery.value = value,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Obx(() {
              if (selectedClass.value == null) {
                return _buildEmptyState(
                  title: 'Select a Class',
                  subtitle: 'Choose a class to manage student club memberships',
                );
              }
              
              if (schoolController.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      const SizedBox(height: 16),
                      Text('Loading students...', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }
              
              var filteredStudents = schoolController.students.toList();
              
              if (searchQuery.value.isNotEmpty) {
                final query = searchQuery.value.toLowerCase();
                filteredStudents = filteredStudents.where((student) => 
                  student.studentName.toLowerCase().contains(query) ||
                  (student.srId?.toLowerCase().contains(query) ?? false)
                ).toList();
              }
              
              if (filteredStudents.isEmpty) {
                return _buildEmptyState(
                  title: 'No students found',
                  subtitle: searchQuery.value.isNotEmpty 
                      ? 'Try adjusting your search terms'
                      : 'No students in this class',
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  return _buildStudentCard(context, filteredStudents[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeRequiredWidget(BuildContext context, String featureName) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.04),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upgrade Required',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your current plan does not include the $featureName module. Please contact your correspondent to upgrade.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionManagementView()));
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'View Plans',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClubDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final coordinatorController = TextEditingController();
    final locationController = TextEditingController();
    final maxMembersController = TextEditingController(text: '30');
    final selectedCategory = 'Academic'.obs;
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Club',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Club Name',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: coordinatorController,
                decoration: InputDecoration(
                  labelText: 'Coordinator',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => DropdownButtonFormField<String>(
                value: selectedCategory.value,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['Academic', 'Arts', 'Sports', 'Social']
                    .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) => selectedCategory.value = value!,
              )),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxMembersController,
                decoration: InputDecoration(
                  labelText: 'Max Members',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty) {
                            final schoolController = Get.find<SchoolController>();
                            final schoolId = schoolController.selectedSchool.value?.id ?? '';
                            
                            final newClub = Club(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameController.text,
                              description: descriptionController.text,
                              isActive: true,
                              createdAt: DateTime.now().toIso8601String(),
                              updatedAt: DateTime.now().toIso8601String(),
                              schoolId: schoolId,
                              category: selectedCategory.value,
                              coordinator: coordinatorController.text,
                              meetingDay: 'Monday',
                              meetingTime: '3:00 PM',
                              location: locationController.text,
                              memberCount: 0,
                              maxMembers: int.tryParse(maxMembersController.text) ?? 30,
                            );
                            final clubsController = Get.find<ClubsController>();
                            clubsController.addClub(newClub);
                            Get.back();
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Club'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernVideoCard(BuildContext context, RecordedClass recordedClass, bool canManageClubs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: [
                Center(
                  child: recordedClass.videoUrl != null && recordedClass.videoUrl!.isNotEmpty
                      ? Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Center(
                            child: Text(
                              '▶',
                              style: TextStyle(
                                fontSize: 24,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Video not available',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                ),
                
                if (canManageClubs)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditVideoDialog(context, recordedClass);
                            break;
                          case 'delete':
                            _showDeleteVideoConfirmation(context, recordedClass);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      recordedClass.academicYear ?? 'N/A',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recordedClass.level,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recordedClass.category,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  recordedClass.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recordedClass.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  'Club: ${recordedClass.clubName}',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
                Text(
                  'Instructor: ${recordedClass.instructor}',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
                Text(
                  'Uploaded: ${recordedClass.uploadDate}',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
                Text(
                  '${recordedClass.viewCount} views',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActivityCard(BuildContext context, Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4facfe).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              activity.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Club: ${activity.clubName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            Text(
              '${activity.date} at ${activity.time}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            Text(
              '${activity.participantCount} participants',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEventCard(BuildContext context, Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFf093fb).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditEventDialog(context, event);
                        break;
                      case 'delete':
                        _showDeleteEventConfirmation(context, event);
                        break;
                      case 'register':
                        _registerForEvent(event);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (event.registrationRequired)
                      const PopupMenuItem(value: 'register', child: Text('Register')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Date: ${event.date}', style: const TextStyle(fontSize: 14, color: Colors.white)),
                      const SizedBox(width: 16),
                      Text('Time: ${event.time}', style: const TextStyle(fontSize: 14, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Location: ${event.location}', style: const TextStyle(fontSize: 14, color: Colors.white)),
                      const SizedBox(width: 16),
                      Text('Organizer: ${event.organizer}', style: const TextStyle(fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            if (event.registrationRequired) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: event.registrationRate,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        event.isFull ? Colors.red : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${event.currentParticipants}/${event.maxParticipants}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernMembershipCard(BuildContext context, Membership membership) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
            radius: 24,
            child: Text(
              membership.studentName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membership.studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Club: ${membership.clubName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Joined: ${membership.joinDate}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getRoleColor(membership.role),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              membership.role,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
            radius: 24,
            child: student.studentImage != null
                ? ClipOval(
                    child: Image.network(
                      student.studentImage!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          student.studentName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    student.studentName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${student.srId}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (student.fatherName != null)
                  Text(
                    'Father: ${student.fatherName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: student.isActive ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              student.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: student.isActive ? Colors.green.shade700 : Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return const Color(0xFF3B82F6);
      case 'In Progress':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'President':
        return Colors.red;
      case 'Secretary':
        return Colors.orange;
      case 'Member':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  void _showEditClubDialog(BuildContext context, Club club) {
    final nameController = TextEditingController(text: club.name);
    final descriptionController = TextEditingController(text: club.description);
    final coordinatorController = TextEditingController(text: club.coordinator);
    final locationController = TextEditingController(text: club.location);
    final maxMembersController = TextEditingController(text: club.maxMembers.toString());
    final selectedCategory = club.category.obs;
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Club',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Club Name',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: coordinatorController,
                decoration: InputDecoration(
                  labelText: 'Coordinator',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => DropdownButtonFormField<String>(
                value: selectedCategory.value,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['Academic', 'Arts', 'Sports', 'Social']
                    .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) => selectedCategory.value = value!,
              )),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxMembersController,
                decoration: InputDecoration(
                  labelText: 'Max Members',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty) {
                            final schoolController = Get.find<SchoolController>();
                            final schoolId = schoolController.selectedSchool.value?.id ?? '';
                            
                            final updatedClub = Club(
                              id: club.id,
                              name: nameController.text,
                              description: descriptionController.text,
                              isActive: club.isActive,
                              createdAt: club.createdAt,
                              updatedAt: DateTime.now().toIso8601String(),
                              schoolId: schoolId,
                              category: selectedCategory.value,
                              coordinator: coordinatorController.text,
                              meetingDay: club.meetingDay,
                              meetingTime: club.meetingTime,
                              location: locationController.text,
                              memberCount: club.memberCount,
                              maxMembers: int.tryParse(maxMembersController.text) ?? 30,
                            );
                            final clubsController = Get.find<ClubsController>();
                            clubsController.updateClub(updatedClub);
                            Get.back();
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Update Club'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUploadVideoDialog(BuildContext context) {
    Get.snackbar('Info', 'Upload video functionality would be implemented here');
  }

  void _showEditVideoDialog(BuildContext context, RecordedClass video) {
    Get.snackbar('Info', 'Edit video functionality would be implemented here');
  }

  void _showDeleteVideoConfirmation(BuildContext context, RecordedClass video) {
    Get.snackbar('Info', 'Delete video functionality would be implemented here');
  }

  void _showEditEventDialog(BuildContext context, Event event) {
    Get.snackbar('Info', 'Edit event functionality would be implemented here');
  }

  void _showDeleteEventConfirmation(BuildContext context, Event event) {
    Get.snackbar('Info', 'Delete event functionality would be implemented here');
  }

  void _registerForEvent(Event event) {
    Get.snackbar('Info', 'Event registration functionality would be implemented here');
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteClubConfirmation(BuildContext context, Club club) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Club'),
        content: Text('Are you sure you want to delete ${club.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                final clubsController = Get.find<ClubsController>();
                clubsController.deleteClub(club.id);
                Get.back();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}