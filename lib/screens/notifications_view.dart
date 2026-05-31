import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/announcement_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/screens/announcement_detail_view.dart';
import '../controllers/school_controller.dart';

// ── same _DS constants ───────────────────────────────────────────
class _DS {
  static const accent       = Color(0xFF3B82F6);
  static const accentSoft   = Color(0xFFEFF6FF);
  static const accentMid    = Color(0xFFBFDBFE);
  static const bg           = Color(0xFFF0F4F8);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceAlt   = Color(0xFFF8FAFC);
  static const textPrimary  = Color(0xFF0F172A);
  static const textSecondary= Color(0xFF475569);
  static const textMuted    = Color(0xFF94A3B8);
  static const success      = Color(0xFF059669);
  static const successSoft  = Color(0xFFD1FAE5);
  static const warning      = Color(0xFFD97706);
  static const warningSoft  = Color(0xFFFEF3C7);
  static const danger       = Color(0xFFDC2626);
  static const dangerSoft   = Color(0xFFFEE2E2);
  static const border       = Color(0xFFE2E8F0);
  static const shadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
}

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late AnnouncementController announcementController;
  Worker? _schoolWatcher;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();

    announcementController = Get.isRegistered<AnnouncementController>()
        ? Get.find<AnnouncementController>()
        : Get.put(AnnouncementController());

    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final userSchoolId = authController.user.value?.schoolId;

    try {
      final schoolController = Get.find<SchoolController>();
      _schoolWatcher = ever(schoolController.selectedSchool, (school) async {
        if (school == null) return;
        if (!_initialLoadDone) return;
        if (userRole != 'correspondent') return;
        announcementController.selectedSchool.value = school;
        await announcementController.getAllAnnouncements(school.id);
        announcementController.filterByRole(userRole);
      });
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (announcementController.schools.isEmpty)
        await announcementController.getAllSchools();
      if (!mounted) return;

      SchoolController? schoolCtrl;
      try { schoolCtrl = Get.find<SchoolController>(); } catch (_) {}
      final globalSchool = schoolCtrl?.selectedSchool.value;

      if (userRole != 'correspondent') {
        if (globalSchool != null) {
          announcementController.selectedSchool.value = globalSchool;
          await announcementController.getAllAnnouncements(globalSchool.id);
        } else if (userSchoolId != null &&
            announcementController.schools.isNotEmpty) {
          final userSchool = announcementController.schools
              .firstWhereOrNull((s) => s.id == userSchoolId);
          if (userSchool != null) {
            announcementController.selectedSchool.value = userSchool;
            await announcementController.getAllAnnouncements(userSchool.id);
          }
        }
      } else {
        if (globalSchool != null) {
          announcementController.selectedSchool.value = globalSchool;
          await announcementController.getAllAnnouncements(globalSchool.id);
        } else if (announcementController.schools.isNotEmpty) {
          final first = announcementController.schools.first;
          announcementController.selectedSchool.value = first;
          await announcementController.getAllAnnouncements(first.id);
        }
      }

      if (mounted) announcementController.filterByRole(userRole);
      _initialLoadDone = true;
    });
  }

  @override
  void dispose() {
    _schoolWatcher?.dispose();
    super.dispose();
  }

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
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = userRole == 'correspondent';

    return Scaffold(
      backgroundColor: _DS.bg,
      appBar: AppBar(
        backgroundColor: _DS.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _DS.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: _DS.accent, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Notifications',
              style: TextStyle(
                  color: _DS.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(
            onPressed: () async {
              final school =
                  announcementController.selectedSchool.value;
              if (school != null) {
                await announcementController
                    .getAllAnnouncements(school.id);
                announcementController.filterByRole(userRole);
              } else {
                announcementController.refreshSchools();
              }
            },
            icon: const Icon(Icons.refresh_rounded,
                color: _DS.textMuted, size: 20),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _DS.border),
        ),
      ),
      body: Obx(() {
        if (announcementController.isLoading.value &&
            announcementController.filteredAnnouncements.isEmpty)
          return const Center(
              child: CircularProgressIndicator(color: _DS.accent));

        if (announcementController.selectedSchool.value == null &&
            isCorrespondent)
          return _emptyState(
            icon: Icons.school_rounded,
            title: 'Select a School',
            subtitle:
            'Choose a school from the sidebar to view notifications',
          );

        if (announcementController.filteredAnnouncements.isEmpty)
          return _emptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No Notifications',
            subtitle: "You're all caught up! No new announcements.",
          );

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount:
          announcementController.filteredAnnouncements.length,
          itemBuilder: (context, index) {
            final a = announcementController
                .filteredAnnouncements[index];
            return _buildCard(a);
          },
        );
      }),
    );
  }

  Widget _buildCard(Map<String, dynamic> a) {
    final type     = a['type'] as String?;
    final priority = a['priority'] as String?;
    final accent   = _typeAccent(type);

    return GestureDetector(
      onTap: () {
        announcementController.getAnnouncement(a['_id']).then((_) {
          final fresh =
              announcementController.selectedAnnouncement.value ?? a;
          Get.to(() => AnnouncementDetailView(announcement: fresh));
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.border),
          boxShadow: _DS.shadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Coloured header band ──────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                    Icon(_typeIcon(type), color: accent, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      a['title'] ?? 'No Title',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: accent.withOpacity(0.6)),
                ]),
              ),

              // ── Body ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['description'] ?? 'No description',
                        style: const TextStyle(
                            fontSize: 13,
                            color: _DS.textSecondary,
                            height: 1.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // ── Bottom row — wrap instead of Row to prevent overflow
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Type badge
                          _pill(
                            (type ?? 'general').toUpperCase(),
                            accent,
                          ),
                          // Priority badge
                          _pill(
                            (priority ?? 'normal').toUpperCase(),
                            _priorityColor(priority),
                          ),
                          // Posted by
                          if (a['createdBy']?['userName'] != null)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.person_outline_rounded,
                                  size: 11, color: _DS.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                a['createdBy']['userName'],
                                style: const TextStyle(
                                    fontSize: 10, color: _DS.textMuted),
                              ),
                            ]),
                          // Date
                          Text(
                            _formatDate(a['createdAt']),
                            style: const TextStyle(
                                fontSize: 10, color: _DS.textMuted),
                          ),
                        ],
                      ),
                    ]),
              ),
            ]),
      ),
    );
  }

// ── Compact pill badge ────────────────────────────────────────────
  Widget _pill(String label, Color color) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
                color: _DS.accentSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: _DS.accent),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _DS.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: _DS.textMuted, height: 1.5)),
        ]),
      ),
    );
  }
}