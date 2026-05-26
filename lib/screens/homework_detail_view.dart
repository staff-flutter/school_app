import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  static const Color _primary = Color(0xFF2563EB);
  static const Color _primaryDark = Color(0xFF3949AB);
  static const Color _primaryLight = Color(0xFFEBF0FB);
  static const Color _surface = Color(0xFFF5F5F7);

  @override
  void initState() {
    super.initState();
    currentHomework = widget.homework;
  }

  String _formatDateString(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _refreshHomework() async {
    final homeworkController = Get.find<HomeworkController>();

    String? homeworkId = currentHomework['_id'] as String?;
    if (homeworkId == null) {
      final subjects = currentHomework['subjects'] as List?;
      if (subjects != null && subjects.isNotEmpty) {
        final foundHomework = homeworkController.homeworkList.firstWhereOrNull(
              (h) => (h['subjects'] as List)
              .any((s) => s['_id'] == subjects[0]['_id']),
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

        int attempts = 0;
        while (attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 50));
          final updated = homeworkController.homeworkList.firstWhereOrNull(
                (h) => h['_id'] == homeworkId,
          );
          if (updated != null && updated['updatedAt'] != oldUpdatedAt) {
            setState(() => currentHomework = updated);
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
    final dateStr = _formatDateString(
        currentHomework['homeworkDate'] ?? currentHomework['date']);

    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isTablet, dateStr),
          SliverPadding(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final subject = subjects[index] as Map<String, dynamic>;
                  return _buildSubjectCard(context, subject, isTablet);
                },
                childCount: subjects.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isTablet, String dateStr) {
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';

    return SliverAppBar(
      leading: IconButton(onPressed: (){
        Get.back();
      }, icon: Icon(Icons.arrow_back_ios_new,size: 15,)),
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: _primary,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Homework Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (ApiPermissions.hasApiAccess(
            userRole, 'DELETE /api/homework/deleteentireday'))
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded,
                    color: Colors.white, size: 20),
              ),
              tooltip: 'Delete Entire Day',
              onPressed: () => _showDeleteEntireDayConfirmation(context),
            ),
          ),
      ],
    );
  }

  Widget _buildSubjectCard(
      BuildContext context, Map<String, dynamic> subject, bool isTablet) {
    final subjectName = subject['subjectName'] ?? 'Subject';
    final description = subject['description'] ?? 'No description';
    final teacherData = subject['teacherId'];
    final teacher =
    teacherData is Map ? teacherData['userName'] ?? 'N/A' : 'N/A';
    final attachments = subject['attachments'] as List<dynamic>? ?? [];
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject header
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, _primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                  const Icon(Icons.assignment_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              color: Colors.white70, size: 13),
                          const SizedBox(width: 4),
                          Text(teacher,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (ApiPermissions.hasApiAccess(
                    userRole, 'DELETE /api/homework/deletesubject'))
                  GestureDetector(
                    onTap: () =>
                        _showDeleteSubjectConfirmation(context, subject),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notes_rounded, color: _primary, size: 18),
                    const SizedBox(width: 8),
                    Text('Description',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        )),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 14,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Attachments
          if (attachments.isNotEmpty) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_file_rounded, color: _primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Attachments',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          )),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${attachments.length}',
                          style: TextStyle(
                              color: _primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 4 : 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: attachments.length,
                    itemBuilder: (context, index) {
                      final attachment =
                      attachments[index] as Map<String, dynamic>;
                      final isImage = _isImageFile(attachment['url'] ?? '');

                      return GestureDetector(
                        onTap: () => _showFullImage(
                            context, attachment, subject, userRole),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                Border.all(color: Colors.grey.shade200),
                              ),
                              child: isImage
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  attachment['url'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                      _buildFileIcon(
                                          attachment['name'] ??
                                              'File'),
                                ),
                              )
                                  : _buildFileIcon(
                                  attachment['name'] ?? 'File'),
                            ),
                            if (ApiPermissions.hasApiAccess(userRole,
                                'DELETE /api/homework/deleteattachment'))
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () =>
                                      _showDeleteAttachmentConfirmation(
                                          context, attachment, subject),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close_rounded,
                                        color: Colors.white, size: 12),
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
        ],
      ),
    );
  }

  Widget _buildFileIcon(String fileName) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_getFileIconData(fileName), size: 36, color: _primary),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            fileName,
            style:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
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
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'doc': case 'docx': return Icons.description_rounded;
      case 'jpg': case 'jpeg': case 'png': case 'gif': return Icons.image_rounded;
      case 'mp4': case 'avi': case 'mov': return Icons.video_file_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  bool _isImageFile(String url) {
    final extension = url.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  void _showFullImage(BuildContext context, Map<String, dynamic> attachment,
      Map<String, dynamic> subject, String userRole) {
    final imageUrl = attachment['url'] ?? '';
    final isImage = _isImageFile(imageUrl);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: isImage
                  ? InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image_rounded,
                      color: Colors.white54, size: 80),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_drive_file_rounded,
                        size: 80, color: Colors.white54),
                    const SizedBox(height: 16),
                    Text(attachment['name'] ?? 'File',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 48,
              right: 16,
              child: Row(
                children: [
                  if (ApiPermissions.hasApiAccess(
                      userRole, 'DELETE /api/homework/deleteattachment'))
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _showDeleteAttachmentConfirmation(
                            context, attachment, subject);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAttachmentConfirmation(BuildContext context,
      Map<String, dynamic> attachment, Map<String, dynamic> subject) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Text('Delete Attachment',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      content: Text('Delete "${attachment['name']}"? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            Get.dialog(
              WillPopScope(
                onWillPop: () async => false,
                child: const AlertDialog(
                  content: Row(children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Deleting attachment...'),
                  ]),
                ),
              ),
              barrierDismissible: false,
            );

            final homeworkController = Get.find<HomeworkController>();
            String? homeworkId = currentHomework['_id'] as String?;
            if (homeworkId == null) {
              final foundHomework =
              homeworkController.homeworkList.firstWhereOrNull(
                    (h) => (h['subjects'] as List)
                    .any((s) => s['_id'] == subject['_id']),
              );
              homeworkId = foundHomework?['_id'] as String?;
            }

            final subjectId = subject['_id'] as String?;
            final attachmentId = attachment['_id'] as String?;

            if (homeworkId == null || subjectId == null || attachmentId == null) {
              Navigator.pop(Get.context!);
              Get.snackbar('Error', 'Missing required IDs');
              return;
            }

            final success = await homeworkController.deleteAttachment(
              homeworkId: homeworkId,
              subjectId: subjectId,
              attachmentId: attachmentId,
            );

            Navigator.pop(Get.context!);
            if (success) await _refreshHomework();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void _showDeleteSubjectConfirmation(
      BuildContext context, Map<String, dynamic> subject) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Text('Delete Subject',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      content: Text(
          'Delete "${subject['subjectName']}" subject? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            Get.dialog(
              WillPopScope(
                onWillPop: () async => false,
                child: const AlertDialog(
                  content: Row(children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Deleting subject...'),
                  ]),
                ),
              ),
              barrierDismissible: false,
            );

            final homeworkController = Get.find<HomeworkController>();
            String? homeworkId = currentHomework['_id'] as String?;
            if (homeworkId == null) {
              final foundHomework =
              homeworkController.homeworkList.firstWhereOrNull(
                    (h) => (h['subjects'] as List)
                    .any((s) => s['_id'] == subject['_id']),
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
              if (currentHomework['subjects'] == null ||
                  (currentHomework['subjects'] as List).isEmpty) {
                Get.back();
              }
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void _showDeleteEntireDayConfirmation(BuildContext context) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Text('Delete Entire Day',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      content: const Text(
          'Delete all homework for this day? This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            Get.dialog(
              WillPopScope(
                onWillPop: () async => false,
                child: const AlertDialog(
                  content: Row(children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Deleting homework...'),
                  ]),
                ),
              ),
              barrierDismissible: false,
            );

            final homeworkController = Get.find<HomeworkController>();
            String? homeworkId = currentHomework['_id'] as String?;
            if (homeworkId == null) {
              final subjects = currentHomework['subjects'] as List?;
              if (subjects != null && subjects.isNotEmpty) {
                final foundHomework =
                homeworkController.homeworkList.firstWhereOrNull(
                      (h) => (h['subjects'] as List)
                      .any((s) => s['_id'] == subjects[0]['_id']),
                );
                homeworkId = foundHomework?['_id'] as String?;
              }
            }

            if (homeworkId == null) {
              Navigator.pop(Get.context!);
              Get.snackbar('Error', 'Missing homework ID');
              return;
            }

            final success =
            await homeworkController.deleteEntireDay(homeworkId);
            Navigator.pop(Get.context!);
            if (success) Get.back(result: true);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Delete All'),
        ),
      ],
    ));
  }
}