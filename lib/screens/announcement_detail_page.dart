import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final Map<String, dynamic> notice;
  const AnnouncementDetailPage({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    final targetAudience = (notice['targetAudience'] as List?)
        ?.map((e) => e.toString()).toList() ?? [];
    final targetClasses = (notice['targetClasses'] as List?)
        ?.map((e) => e is Map ? e['name']?.toString() ?? '' : e.toString())
        .where((e) => e.isNotEmpty).toList() ?? [];
    final category = (notice['type'] ?? 'general').toString().toLowerCase();
    final priority = (notice['priority'] ?? '').toString();
// ── Attachments ──
    final attachments = (notice['attachments'] as List?)
        ?.map((e) => e is Map ? e['url']?.toString() ?? '' : e.toString())
        .where((e) => e.isNotEmpty)
        .toList() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF2B5BA8),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFF7BB4DD),

                child: Stack(

                  //fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/Scientific UI background design header.png',
                      fit: BoxFit.cover,
                    ),
                    Container(color: Colors.black.withOpacity(0.1)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Type + Priority badges ──
                  Row(
                    children: [
                      _badge(category),
                      const SizedBox(width: 8),
                      _priorityBadge(priority),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Title ──
                  Text(
                    notice['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2540),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Description ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      notice['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                 // ── Target Audience ──
                 //  if (targetAudience.isNotEmpty)
                 //    _infoCard(
                 //      icon: Icons.people_outline,
                 //      title: 'Target Audience',
                 //      content: targetAudience.join(', '),
                 //    ),
                  if (attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _attachmentsCard(attachments),
                  ],
                  //
                  // // ── Target Classes ──
                  // if (targetClasses.isNotEmpty) ...[
                  //   const SizedBox(height: 12),
                  //   _infoCard(
                  //     icon: Icons.class_outlined,
                  //     title: 'Target Classes',
                  //     content: null,
                  //     child: Wrap(
                  //       spacing: 6,
                  //       runSpacing: 6,
                  //       children: targetClasses
                  //           .map((cls) => Container(
                  //         padding: const EdgeInsets.symmetric(
                  //             horizontal: 10, vertical: 4),
                  //         decoration: BoxDecoration(
                  //           color: const Color(0xFFEEF3FB),
                  //           borderRadius: BorderRadius.circular(10),
                  //           border: Border.all(
                  //               color: const Color(0xFF2B5BA8)
                  //                   .withOpacity(0.3)),
                  //         ),
                  //         child: Text(cls,
                  //             style: const TextStyle(
                  //               fontSize: 12,
                  //               color: Color(0xFF2B5BA8),
                  //               fontWeight: FontWeight.w500,
                  //             )),
                  //       ))
                  //           .toList(),
                  //     ),
                  //   ),
                  // ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _attachmentsCard(List<String> attachments) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.attach_file, size: 16, color: Color(0xFF2B5BA8)),
              SizedBox(width: 8),
              Text(
                'Attachments',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7A8BA8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Attachment items
          ...attachments.asMap().entries.map((entry) {
            final index = entry.key;
            final url = entry.value;
            final isImage = _isImage(url);
            final isPdf = url.toLowerCase().endsWith('.pdf');

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2B5BA8).withOpacity(0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview
                  if (isImage)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        url,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 180,
                            color: const Color(0xFFEEF3FB),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2B5BA8),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          color: const Color(0xFFEEF3FB),
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: Color(0xFF7A8BA8), size: 32),
                          ),
                        ),
                      ),
                    ),

                  // File row with open button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B5BA8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isImage
                                ? Icons.image_outlined
                                : isPdf
                                ? Icons.picture_as_pdf_outlined
                                : Icons.insert_drive_file_outlined,
                            color: const Color(0xFF2B5BA8),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _fileName(url, index),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1A2540),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Open button
                        InkWell(
                          onTap: () => _openUrl(url),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B5BA8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPdf
                                      ? Icons.open_in_new
                                      : isImage
                                      ? Icons.fullscreen
                                      : Icons.download_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPdf
                                      ? 'Open'
                                      : isImage
                                      ? 'View'
                                      : 'Download',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isImage(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  String _fileName(String url, int index) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty && segments.last.isNotEmpty) {
        return Uri.decodeComponent(segments.last);
      }
    } catch (_) {}
    return 'Attachment ${index + 1}';
  }

  void _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Error', 'Could not open attachment');
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not open attachment');
    }
  }
  Widget _badge(String category) {
    final colors = {
      'exam':    {'bg': const Color(0xFFEDE9FF), 'text': const Color(0xFF534AB7), 'label': 'Exam'},
      'event':   {'bg': const Color(0xFFE1F5EE), 'text': const Color(0xFF0F6E56), 'label': 'Event'},
      'holiday': {'bg': const Color(0xFFFAEEDA), 'text': const Color(0xFF854F0B), 'label': 'Holiday'},
      'urgent':  {'bg': const Color(0xFFFCEBEB), 'text': const Color(0xFFA32D2D), 'label': 'Urgent'},
    };
    final c = colors[category] ?? {'bg': const Color(0xFFE6F1FB), 'text': const Color(0xFF185FA5), 'label': 'General'};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c['bg'] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(c['label'] as String,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c['text'] as Color,
          )),
    );
  }

  Widget _priorityBadge(String priority) {
    final isHigh = priority.toLowerCase() == 'high' ||
        priority.toLowerCase() == 'urgent';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isHigh
            ? const Color(0xFFFCEBEB)
            : const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHigh ? Icons.priority_high : Icons.low_priority,
            size: 12,
            color: isHigh ? const Color(0xFFA32D2D) : const Color(0xFF185FA5),
          ),
          const SizedBox(width: 4),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isHigh
                  ? const Color(0xFFA32D2D)
                  : const Color(0xFF185FA5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    String? content,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2B5BA8)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A8BA8),
                  )),
            ],
          ),
          const SizedBox(height: 8),
          if (content != null)
            Text(content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A2540),
                  fontWeight: FontWeight.w500,
                )),
          if (child != null) child,
        ],
      ),
    );
  }
}