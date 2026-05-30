import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

// ── same _DS constants ───────────────────────────────────────────
class _DS {
  static const accent      = Color(0xFF3B82F6);
  static const accentSoft  = Color(0xFFEFF6FF);
  static const accentMid   = Color(0xFFBFDBFE);
  static const bg          = Color(0xFFF0F4F8);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted   = Color(0xFF94A3B8);
  static const success     = Color(0xFF059669);
  static const successSoft = Color(0xFFD1FAE5);
  static const warning     = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger      = Color(0xFFDC2626);
  static const dangerSoft  = Color(0xFFFEE2E2);
  static const border      = Color(0xFFE2E8F0);
  static const shadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const radius   = 16.0;
  static const radiusSm = 8.0;
}

class AnnouncementDetailView extends StatelessWidget {
  final Map<String, dynamic> announcement;

  const AnnouncementDetailView({
    super.key,
    required this.announcement,
  });

  // ── type helpers ─────────────────────────────────────────────────
  Color _typeAccent(String? type) {
    switch (type?.toLowerCase()) {
      case 'urgent':  return _DS.danger;
      case 'event':   return _DS.accent;
      case 'holiday': return _DS.success;
      default:        return const Color(0xFF3B82F6);
    }
  }

  IconData _typeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'urgent':  return Icons.warning_amber_rounded;
      case 'event':   return Icons.event_rounded;
      case 'holiday': return Icons.celebration_rounded;
      default:        return Icons.campaign_rounded;
    }
  }

  Color _priorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent': return _DS.danger;
      case 'high':   return _DS.warning;
      case 'low':    return _DS.success;
      default:       return const Color(0xFF64748B);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'N/A';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return 'N/A'; }
  }

  String _audience() {
    final a = announcement['targetAudience'] as List?;
    if (a == null || a.isEmpty) return 'All';
    return a.map((x) {
      final s = x.toString();
      return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    }).join(', ');
  }

  bool _hasAttachments() {
    final a = announcement['attachments'] as List?;
    return a != null && a.isNotEmpty;
  }

  // ── card wrapper ─────────────────────────────────────────────────
  Widget _card({required Widget child, EdgeInsets? padding}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(_DS.radius),
          border: Border.all(color: _DS.border),
          boxShadow: _DS.shadow,
        ),
        child: child,
      );

  Widget _badge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: fg.withOpacity(0.2)),
    ),
    child: Text(text,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
  );

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 15, color: _DS.textMuted),
      const SizedBox(width: 10),
      SizedBox(
        width: 110,
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: _DS.textSecondary,
                fontWeight: FontWeight.w500)),
      ),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                fontSize: 12,
                color: _DS.textPrimary,
                fontWeight: FontWeight.w600)),
      ),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final type     = announcement['type'] as String?;
    final priority = announcement['priority'] as String?;
    final accent   = _typeAccent(type);
    final accentBg = accent.withOpacity(0.08);

    return Scaffold(
      backgroundColor: _DS.bg,
      appBar: AppBar(
        backgroundColor: _DS.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _DS.textPrimary, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Text(
          announcement['title'] ?? 'Announcement',
          style: const TextStyle(
            color: _DS.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _DS.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Type header band ──────────────────────────────────────
              _card(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  // Coloured band
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(_DS.radius)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_typeIcon(type), color: accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          announcement['title'] ?? 'No Title',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  // Badges row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Row(children: [
                      _badge(
                        (type ?? 'general').toUpperCase(),
                        accent.withOpacity(0.1),
                        accent,
                      ),
                      const SizedBox(width: 8),
                      _badge(
                        (priority ?? 'normal').toUpperCase(),
                        _priorityColor(priority).withOpacity(0.1),
                        _priorityColor(priority),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(announcement['createdAt']),
                        style: const TextStyle(
                            fontSize: 11, color: _DS.textMuted),
                      ),
                    ]),
                  ),
                ]),
              ),

              // ── Description ───────────────────────────────────────────
              _card(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: _DS.accentSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.description_rounded,
                              color: _DS.accent, size: 16),
                        ),
                        const SizedBox(width: 10),
                        const Text('Description',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _DS.textPrimary)),
                      ]),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: _DS.border),
                      const SizedBox(height: 12),
                      Text(
                        announcement['description'] ?? 'No description available',
                        style: const TextStyle(
                            fontSize: 14,
                            color: _DS.textSecondary,
                            height: 1.6),
                      ),
                    ]),
              ),

              // ── Details ───────────────────────────────────────────────
              _card(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.info_outline_rounded,
                              color: Color(0xFF3B82F6), size: 16),
                        ),
                        const SizedBox(width: 10),
                        const Text('Details',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _DS.textPrimary)),
                      ]),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: _DS.border),
                      const SizedBox(height: 14),
                      _detailRow(Icons.people_rounded, 'Audience',
                          _audience()),
                      _detailRow(Icons.calendar_today_rounded, 'Academic Year',
                          announcement['academicYear'] ?? 'N/A'),
                      _detailRow(Icons.person_rounded, 'Posted by',
                          announcement['createdBy']?['userName'] ?? 'System'),
                      _detailRow(Icons.access_time_rounded, 'Created',
                          _formatDate(announcement['createdAt'])),
                      if (announcement['updatedAt'] != announcement['createdAt'])
                        _detailRow(Icons.edit_rounded, 'Updated',
                            _formatDate(announcement['updatedAt'])),
                    ]),
              ),

              // ── Attachments ───────────────────────────────────────────
              if (_hasAttachments()) ...[
                _card(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: _DS.successSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.attachment_rounded,
                                color: _DS.success, size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Text('Attachments',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _DS.textPrimary)),
                          const Spacer(),
                          Text(
                            '${(announcement['attachments'] as List).length} files',
                            style: const TextStyle(
                                fontSize: 12, color: _DS.textMuted),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: _DS.border),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                            (announcement['attachments'] as List).length,
                            itemBuilder: (_, i) {
                              final a = (announcement['attachments']
                              as List)[i] as Map<String, dynamic>;
                              final isPdf = a['type'] == 'pdf' ||
                                  a['url'].toString().endsWith('.pdf');
                              return GestureDetector(
                                onTap: () => isPdf
                                    ? _openPdf(a['url'])
                                    : _viewFullImage(a['url']),
                                child: Container(
                                  width: 80, height: 80,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: isPdf
                                        ? const Color(0xFFFEE2E2)
                                        : _DS.surfaceAlt,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _DS.border),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: isPdf
                                        ? Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.picture_as_pdf,
                                            size: 28,
                                            color: _DS.danger),
                                        SizedBox(height: 4),
                                        Text('PDF',
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: _DS.danger,
                                                fontWeight:
                                                FontWeight.w600)),
                                      ],
                                    )
                                        : Image.network(a['url'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image,
                                            color: _DS.textMuted)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ]),
                ),
              ],
            ]),
      ),
    );
  }

  void _viewFullImage(String url) {
    Get.to(() => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('Image',
            style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(url),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          loadingBuilder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image,
                  size: 64, color: Colors.white54)),
        ),
      ),
    ));
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri))
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      else
        Get.snackbar('Notice', 'No app found to open this PDF');
    } catch (_) {
      Get.snackbar('Error', 'Could not open document');
    }
  }
}