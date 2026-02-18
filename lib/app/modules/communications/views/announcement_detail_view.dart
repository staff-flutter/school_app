import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class AnnouncementDetailView extends StatelessWidget {
  final Map<String, dynamic> announcement;

  const AnnouncementDetailView({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: Text(
          announcement['title'] ?? 'Announcement',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: isLandscape && isTablet
              ? _buildTabletLandscapeLayout(size, isTablet)
              : _buildMobileLayout(size, isTablet),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Size size, bool isTablet) {
    return Column(
      children: [
        _buildHeaderCard(size, isTablet),
        _buildContentCard(size, isTablet),
        if (_hasAttachments()) _buildAttachmentsCard(size, isTablet),
        // _buildMetadataCard(size, isTablet),
        SizedBox(height: isTablet ? 32 : 24),
      ],
    );
  }

  Widget _buildTabletLandscapeLayout(Size size, bool isTablet) {
    return Column(
      children: [
        _buildHeaderCard(size, isTablet),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildContentCard(size, isTablet),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  if (_hasAttachments()) _buildAttachmentsCard(size, isTablet),
                  if (_hasAttachments()) const SizedBox(height: 16),
                  _buildMetadataCard(size, isTablet),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeaderCard(Size size, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: _getTypeGradient(announcement['type']),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isTablet ? 20 : 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                  ),
                  child: Icon(
                    _getTypeIcon(announcement['type']),
                    color: Colors.white,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Text(
                    announcement['title'] ?? 'No Title',
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Row(
              children: [
                _buildBadge(
                  announcement['type']?.toString().toUpperCase() ?? 'GENERAL',
                  Colors.white.withOpacity(0.2),
                  Colors.white,
                  isTablet,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                _buildBadge(
                  announcement['priority']?.toString().toUpperCase() ?? 'NORMAL',
                  _getPriorityColor(announcement['priority']).withOpacity(0.2),
                  Colors.white,
                  isTablet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(Size size, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isTablet ? 20 : 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              announcement['description'] ?? 'No description available',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
            if (_hasTargetClasses()) ...[
              SizedBox(height: isTablet ? 20 : 16),
              Text(
                'Target Classes',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Wrap(
                spacing: isTablet ? 8 : 6,
                runSpacing: isTablet ? 8 : 6,
                children: _getTargetClasses().map((cls) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 8,
                    vertical: isTablet ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                  ),
                  child: Text(
                    cls['name']?.toString() ?? 'N/A',
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard(Size size, bool isTablet) {
    final attachments = announcement['attachments'] as List? ?? [];
    
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isTablet ? 20 : 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attachment,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            if (isTablet && size.width > 800)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: attachments.length,
                itemBuilder: (context, index) => _buildAttachmentItem(attachments[index], isTablet),
              )
            else
              SizedBox(
                height: isTablet ? 120 : 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: attachments.length,
                  itemBuilder: (context, index) => Container(
                    margin: EdgeInsets.only(right: isTablet ? 12 : 8),
                    child: _buildAttachmentItem(attachments[index], isTablet),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(Map<String, dynamic> attachment, bool isTablet) {
    final isPdf = attachment['type'] == 'pdf' || attachment['url'].toString().endsWith('.pdf');
    final size = isTablet ? 100.0 : 80.0;

    return GestureDetector(
      onTap: () => isPdf ? _openPdf(attachment['url']) : _viewFullImage(attachment['url']),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
          child: isPdf
              ? Container(
                  color: Colors.red.shade50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, size: isTablet ? 32 : 24, color: Colors.red),
                      SizedBox(height: isTablet ? 4 : 2),
                      Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: isTablet ? 10 : 8,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                )
              : Image.network(
                  attachment['url'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade100,
                    child: Icon(Icons.broken_image, size: isTablet ? 32 : 24, color: Colors.grey),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMetadataCard(Size size, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isTablet ? 20 : 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            _buildDetailRow('Target Audience', _getTargetAudience(), isTablet),
            _buildDetailRow('Academic Year', announcement['academicYear'] ?? 'N/A', isTablet),
            _buildDetailRow('Posted by', announcement['createdBy']?['userName'] ?? 'System', isTablet),
            _buildDetailRow('Created', _formatDate(announcement['createdAt']), isTablet),
            if (announcement['updatedAt'] != announcement['createdAt'])
              _buildDetailRow('Updated', _formatDate(announcement['updatedAt']), isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isTablet) {
    return Padding(
      
      padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 14 : 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color backgroundColor, Color textColor, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 8,
        vertical: isTablet ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: isTablet ? 12 : 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper methods
  bool _hasAttachments() {
    final attachments = announcement['attachments'] as List?;
    return attachments != null && attachments.isNotEmpty;
  }

  bool _hasTargetClasses() {
    final classes = announcement['targetClasses'] as List?;
    return classes != null && classes.isNotEmpty;
  }

  List<Map<String, dynamic>> _getTargetClasses() {
    return List<Map<String, dynamic>>.from(announcement['targetClasses'] ?? []);
  }

  String _getTargetAudience() {
    final audience = announcement['targetAudience'] as List?;
    if (audience == null || audience.isEmpty) return 'All';
    return audience.map((a) => a.toString().capitalizeFirst ?? a.toString()).join(', ');
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'urgent': return Icons.warning;
      case 'event': return Icons.event;
      case 'holiday': return Icons.celebration;
      default: return Icons.announcement;
    }
  }

  Gradient _getTypeGradient(String? type) {
    switch (type) {
      case 'urgent': return AppTheme.errorGradient;
      case 'event': return AppTheme.primaryGradient;
      case 'holiday': return AppTheme.successGradient;
      default: return const LinearGradient(
        colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'urgent': return Colors.red;
      case 'high': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.blue;
    }
  }

  void _viewFullImage(String url) {
    Get.to(() => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Image'),
      ),
      body: SafeArea(
        child: Center(
          child: PhotoView(
            imageProvider: NetworkImage(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text('Failed to load image', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> _openPdf(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Notice', 'No application found to open this PDF.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not open the document.');
    }
  }
}
