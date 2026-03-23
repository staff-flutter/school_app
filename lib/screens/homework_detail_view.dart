import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/homework_controller.dart';
import 'package:school_app/controllers/school_controller.dart';

class HomeworkDetailView extends StatefulWidget {
  final Map<String, dynamic> homework;

  const HomeworkDetailView({super.key, required this.homework});

  @override
  State<HomeworkDetailView> createState() => _HomeworkDetailViewState();
}

class _HomeworkDetailViewState extends State<HomeworkDetailView> {
  late Map<String, dynamic> currentHomework;

  @override
  void initState() {
    super.initState();
    currentHomework = widget.homework;
  }

  Future<void> _refreshHomework() async {
    final homeworkController = Get.find<HomeworkController>();
    
    String? homeworkId = currentHomework['_id'] as String?;
    if (homeworkId == null) {
      final subjects = currentHomework['subjects'] as List?;
      if (subjects != null && subjects.isNotEmpty) {
        final foundHomework = homeworkController.homeworkList.firstWhereOrNull(
          (h) => (h['subjects'] as List).any((s) => s['_id'] == subjects[0]['_id']),
        );
        homeworkId = foundHomework?['_id'] as String?;
      }
    }
    
    if (homeworkId != null) {
      final foundHomework = homeworkController.homeworkList.firstWhereOrNull(
        (h) => h['_id'] == homeworkId,
      );
      if (foundHomework != null) {
        final oldUpdatedAt = currentHomework['updatedAt'];
        
        await homeworkController.getAllHomework(
          schoolId: foundHomework['schoolId'],
          classId: foundHomework['classId'],
          sectionId: foundHomework['sectionId'],
        );
        
        // Wait for the observable list to update with new data
        int attempts = 0;
        while (attempts < 10) {
          await Future.delayed(Duration(milliseconds: 50));
          final updated = homeworkController.homeworkList.firstWhereOrNull(
            (h) => h['_id'] == homeworkId,
          );
          if (updated != null && updated['updatedAt'] != oldUpdatedAt) {
            setState(() {
              currentHomework = updated;
            });
            
            break;
          }
          attempts++;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final subjects = currentHomework['subjects'] as List<dynamic>? ?? [];
    final date = currentHomework['homeworkDate'] ?? currentHomework['date'] ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Homework Details'),
        actions: [
          Builder(
            builder: (context) {
              final authController = Get.find<AuthController>();
              final userRole = authController.user.value?.role?.toLowerCase() ?? '';
              
              if (ApiPermissions.hasApiAccess(userRole, 'DELETE /api/homework/deleteentireday')) {
                return IconButton(
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'Delete Entire Day',
                  onPressed: () => _showDeleteEntireDayConfirmation(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade600, Colors.red.shade600],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.indigo.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Date: $date',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // All Subjects
            ...subjects.map((subjectData) {
              final subject = subjectData as Map<String, dynamic>;
              final subjectName = subject['subjectName'] ?? 'Subject';
              final description = subject['description'] ?? 'No description';
              final teacherData = subject['teacherId'];
              final teacher = teacherData is Map ? teacherData['userName'] ?? 'N/A' : 'N/A';
              final attachments = subject['attachments'] as List<dynamic>? ?? [];
              
              return Column(
                children: [
                  // Subject Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade600, Colors.red.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assignment,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                subjectName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 28 : 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final authController = Get.find<AuthController>();
                                final userRole = authController.user.value?.role?.toLowerCase() ?? '';
                                
                                if (ApiPermissions.hasApiAccess(userRole, 'DELETE /api/homework/deletesubject')) {
                                  return IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                    tooltip: 'Delete Subject',
                                    onPressed: () => _showDeleteSubjectConfirmation(context, subject),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.person,
                          'Teacher',
                          teacher,
                          Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.orange.shade600),
                            const SizedBox(width: 12),
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Attachments Card
                  if (attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attach_file, color: Colors.orange.shade600),
                              const SizedBox(width: 12),
                              Text(
                                'Attachments (${attachments.length})',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isTablet ? 4 : 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                            itemCount: attachments.length,
                            itemBuilder: (context, index) {
                              final attachment = attachments[index];
                              final isImage = _isImageFile(attachment['url'] ?? '');
                              final authController = Get.find<AuthController>();
                              final userRole = authController.user.value?.role?.toLowerCase() ?? '';
                              
                              return GestureDetector(
                                onTap: () => _showFullImage(context, attachment, subject, userRole),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: isImage
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                attachment['url'],
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return _buildFileIcon(attachment['name'] ?? 'File');
                                                },
                                              ),
                                            )
                                          : _buildFileIcon(attachment['name'] ?? 'File'),
                                    ),
                                    if (ApiPermissions.hasApiAccess(userRole, 'DELETE /api/homework/deleteattachment'))
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _showDeleteAttachmentConfirmation(context, attachment, subject),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color.withOpacity(0.9), size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileIcon(String fileName) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getFileIconData(fileName),
          size: 48,
          color: Colors.orange.shade600,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            fileName,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getFileIconData(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  bool _isImageFile(String url) {
    final extension = url.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  void _showFullImage(BuildContext context, Map<String, dynamic> attachment, Map<String, dynamic> subject, String userRole) {
    final imageUrl = attachment['url'] ?? '';
    final isImage = _isImageFile(imageUrl);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: isImage
                  ? InteractiveViewer(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            color: Colors.white,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error, size: 48, color: Colors.red),
                                SizedBox(height: 16),
                                Text('Failed to load image'),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insert_drive_file, size: 80, color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            attachment['name'] ?? 'File',
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Row(
                children: [
                  if (ApiPermissions.hasApiAccess(userRole, 'DELETE /api/homework/deleteattachment'))
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showDeleteAttachmentConfirmation(context, attachment, subject);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAttachmentConfirmation(BuildContext context, Map<String, dynamic> attachment, Map<String, dynamic> subject) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Attachment'),
        content: Text('Are you sure you want to delete "${attachment['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              Get.dialog(
                WillPopScope(
                  onWillPop: () async => false,
                  child: const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Deleting attachment...'),
                      ],
                    ),
                  ),
                ),
                barrierDismissible: false,
              );
              
              
              
              
              
              
              final homeworkController = Get.find<HomeworkController>();
              final schoolController = Get.find<SchoolController>();
              
              // Try to find homework ID from the homework object or from controller's list
              String? homeworkId = currentHomework['_id'] as String?;
              
              if (homeworkId == null) {
                
                final foundHomework = homeworkController.homeworkList.firstWhereOrNull(
                  (h) => (h['subjects'] as List).any((s) => s['_id'] == subject['_id']),
                );
                homeworkId = foundHomework?['_id'] as String?;
                
              }
              
              final subjectId = subject['_id'] as String?;
              final attachmentId = attachment['_id'] as String?;
              
              
              
              
              
              if (homeworkId == null || subjectId == null || attachmentId == null) {
                Navigator.pop(Get.context!);
                Get.snackbar('Error', 'Missing required IDs: homework=${homeworkId != null}, subject=${subjectId != null}, attachment=${attachmentId != null}');
                return;
              }
              
              final success = await homeworkController.deleteAttachment(
                homeworkId: homeworkId,
                subjectId: subjectId,
                attachmentId: attachmentId,
              );
              
              Navigator.pop(Get.context!);
              
              if (success) {
                await _refreshHomework();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSubjectConfirmation(BuildContext context, Map<String, dynamic> subject) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject['subjectName']}" subject?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              Get.dialog(
                WillPopScope(
                  onWillPop: () async => false,
                  child: const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Deleting subject...'),
                      ],
                    ),
                  ),
                ),
                barrierDismissible: false,
              );
              
              final homeworkController = Get.find<HomeworkController>();
              
              String? homeworkId = currentHomework['_id'] as String?;
              if (homeworkId == null) {
                final foundHomework = homeworkController.homeworkList.firstWhereOrNull(
                  (h) => (h['subjects'] as List).any((s) => s['_id'] == subject['_id']),
                );
                homeworkId = foundHomework?['_id'] as String?;
              }
              
              final subjectId = subject['_id'] as String?;
              
              if (homeworkId == null || subjectId == null) {
                Navigator.pop(Get.context!);
                Get.snackbar('Error', 'Missing required IDs');
                return;
              }
              
              final success = await homeworkController.deleteSubject(
                homeworkId: homeworkId,
                subjectId: subjectId,
              );
              
              Navigator.pop(Get.context!);
              
              if (success) {
                await _refreshHomework();
                // If no subjects left, go back
                if (currentHomework['subjects'] == null || (currentHomework['subjects'] as List).isEmpty) {
                  Get.back();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteEntireDayConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entire Day'),
        content: const Text('Are you sure you want to delete all homework for this day? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              Get.dialog(
                WillPopScope(
                  onWillPop: () async => false,
                  child: const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Deleting homework...'),
                      ],
                    ),
                  ),
                ),
                barrierDismissible: false,
              );
              
              final homeworkController = Get.find<HomeworkController>();
              
              String? homeworkId = currentHomework['_id'] as String?;
              if (homeworkId == null) {
                final subjects = currentHomework['subjects'] as List?;
                if (subjects != null && subjects.isNotEmpty) {
                  final foundHomework = homeworkController.homeworkList.firstWhereOrNull(
                    (h) => (h['subjects'] as List).any((s) => s['_id'] == subjects[0]['_id']),
                  );
                  homeworkId = foundHomework?['_id'] as String?;
                }
              }
              
              if (homeworkId == null) {
                Navigator.pop(Get.context!);
                Get.snackbar('Error', 'Missing homework ID');
                return;
              }
              
              final success = await homeworkController.deleteEntireDay(homeworkId);
              
              Navigator.pop(Get.context!);
              
              if (success) {
                Get.back(result: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
