import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../controllers/my_children_controller.dart';
import '../core/theme/app_theme.dart';
import 'details_of_student_view.dart';

class MyChildrenView extends StatefulWidget {
  const MyChildrenView({super.key});

  @override
  State<MyChildrenView> createState() => _MyChildrenViewState();
}

class _MyChildrenViewState extends State<MyChildrenView> {
  late MyChildrenController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<MyChildrenController>();
    // Reload children data when navigating to this view - delay to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMyChildren();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MyChildrenController>(
      builder: (controller) => Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryBlue, Colors.indigo.shade600],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.child_care_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'My Children',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'View your children\'s information',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Get.toNamed('/notifications');
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.children.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.child_care, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No children found'),
                Text('Contact school admin to link your children'),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: controller.loadMyChildren,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.children.length,
              itemBuilder: (context, index) {
                final child = controller.children[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.biologySoftGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.biologyGreen.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.cardBackground,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.biologyGreen.withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: (child['studentImage'] is Map && child['studentImage']['url'] != null)

                                        ? Image.network(
                                            child['studentImage']['url'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              
                                              return Center(
                                                child: Text(
                                                  (child['studentName'] ?? 'U')[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: AppTheme.biologyGreen,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : Center(
                                            child: Text(
                                              (child['studentName'] ?? 'U')[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: AppTheme.biologyGreen,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child['studentName'] ?? 'Unknown Student',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.titleOnWhite,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.mathOrange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.mathOrange.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          'Class: ${child['className'] ?? 'Unknown Class'}',
                                          style: const TextStyle(
                                            color: AppTheme.mathOrange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          'Section: ${child['sectionName'] ?? 'Unknown Section'}',
                                          style: const TextStyle(
                                            color: AppTheme.successGreen,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // PopupMenuButton<String>(
                                //   icon: Icon(
                                //     Icons.more_vert,
                                //     color: AppTheme.primaryBlue,
                                //   ),
                                //   itemBuilder: (context) => [
                                //     const PopupMenuItem(
                                //       value: 'attendance',
                                //       child: Row(
                                //         children: [
                                //           Icon(Icons.how_to_reg, color: Colors.blue),
                                //           SizedBox(width: 12),
                                //           Text('View Attendance'),
                                //         ],
                                //       ),
                                //     ),
                                //   ],
                                //   onSelected: (value) {
                                //     if (value == 'attendance') {
                                //       controller.viewChildAttendance(
                                //         child['_id'] ?? '',
                                //         child['studentName'] ?? 'Unknown Student',
                                //       );
                                //     }
                                //   },
                                // ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Class Teacher Information

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      controller.viewChildAttendance(
                                        child['_id'] ?? '',
                                        child['studentName'] ?? 'Unknown Student',
                                      );
                                    },
                                    icon: const Icon(Icons.how_to_reg),
                                    label: const Text('View Attendance'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      foregroundColor: AppTheme.titleOnGradient,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.successGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Prepare student data in the expected format
                                        final studentData = {
                                          'studentName': child['studentName'],
                                          'srId': child['srId'],
                                          'className': child['className'],
                                          'sectionName': child['sectionName'],
                                          '_id': child['_id'],
                                          'studentImage': child['studentImage'],
                                          'mandatory': child['mandatory'] ?? {},
                                          'nonMandatory': child['nonMandatory'] ?? {},
                                          'clubs': child['clubs'] ?? [],
                                        };
                                        Get.to(() => const DetailsOfStudentView(), arguments: studentData);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text(
                                        'View Details',
                                        style: TextStyle(color: AppTheme.titleOnGradient),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          ),
                        ),
                      ),
                    ),
                  );

              },
            ),
          ),
        );
      }),
    ));
  }
}
