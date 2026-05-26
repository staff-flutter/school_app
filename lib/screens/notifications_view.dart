import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/announcement_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/screens/announcement_detail_view.dart';
import '../controllers/school_controller.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late AnnouncementController announcementController;
  Worker? _schoolWatcher;

  // Guard flag: prevents the `ever()` watcher from re-fetching while the
  // initState postFrameCallback is already in the middle of its own fetch.
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

    // ── Register the ever() watcher BEFORE the postFrameCallback so we
    //    never miss a change, but guard it with _initialLoadDone so it
    //    doesn't fire while initState is already loading.
    try {
      final schoolController = Get.find<SchoolController>();

      _schoolWatcher = ever(schoolController.selectedSchool, (school) async {
        // Skip if:
        //   • no school selected
        //   • initial load hasn't finished yet (avoid double-fetch)
        //   • non-correspondent (their school never changes from sidebar)
        if (school == null) return;
        if (!_initialLoadDone) return;
        if (userRole != 'correspondent') return;

        announcementController.selectedSchool.value = school;
        await announcementController.getAllAnnouncements(school.id);
        announcementController.filterByRole(userRole);
      });
    } catch (_) {}

    // ── Single postFrameCallback that does ALL initial loading ──────────────
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // 1. Ensure schools are loaded
      if (announcementController.schools.isEmpty) {
        await announcementController.getAllSchools();
      }

      if (!mounted) return;

      if (userRole != 'correspondent') {
        // ── Non-correspondent: use the school assigned to their account ──
        //    Prefer the globally selected school (already set by sidebar
        //    _loadSchoolData) so we don't fire two fetches.
        SchoolController? schoolCtrl;
        try { schoolCtrl = Get.find<SchoolController>(); } catch (_) {}

        final globalSchool = schoolCtrl?.selectedSchool.value;

        if (globalSchool != null) {
          announcementController.selectedSchool.value = globalSchool;
          await announcementController.getAllAnnouncements(globalSchool.id);
        } else if (userSchoolId != null && announcementController.schools.isNotEmpty) {
          final userSchool = announcementController.schools.firstWhereOrNull(
                (s) => s.id == userSchoolId,
          );
          if (userSchool != null) {
            announcementController.selectedSchool.value = userSchool;
            await announcementController.getAllAnnouncements(userSchool.id);
          }
        }

        if (mounted) announcementController.filterByRole(userRole);

      } else {
        // ── Correspondent: honour whatever school is already chosen
        //    in the global SchoolController (sidebar picker).  Fall back
        //    to the first school only if nothing is selected yet.
        SchoolController? schoolCtrl;
        try { schoolCtrl = Get.find<SchoolController>(); } catch (_) {}

        final globalSchool = schoolCtrl?.selectedSchool.value;

        if (globalSchool != null) {
          announcementController.selectedSchool.value = globalSchool;
          await announcementController.getAllAnnouncements(globalSchool.id);
        } else if (announcementController.schools.isNotEmpty) {
          final firstSchool = announcementController.schools.first;
          announcementController.selectedSchool.value = firstSchool;
          await announcementController.getAllAnnouncements(firstSchool.id);
        }

        if (mounted) announcementController.filterByRole(userRole);
      }

      // ── Mark initial load complete so the ever() watcher is now active ──
      _initialLoadDone = true;
    });
  }

  @override
  void dispose() {
    _schoolWatcher?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = userRole == 'correspondent';

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.appBarGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C4FC7).withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                ),
              ),
            ),
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
                  child: const Icon(Icons.notifications_active,
                      color: Colors.white, size: 15),
                ),
                const SizedBox(width: 10),
                Text(
                  'Notificatio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                height: 30,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: IconButton(
                    onPressed: () async {
                      final school = announcementController.selectedSchool.value;
                      if (school != null) {
                        await announcementController.getAllAnnouncements(school.id);
                        announcementController.filterByRole(userRole);
                      } else {
                        announcementController.refreshSchools();
                      }
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          // ── Loading state ──────────────────────────────────────────────────
          if (announcementController.isLoading.value &&
              announcementController.filteredAnnouncements.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── No school selected (correspondent only) ────────────────────────
          if (announcementController.selectedSchool.value == null &&
              isCorrespondent) {
            return _buildInfoCard(
              context,
              icon: Icons.school,
              title: 'Select a School',
              subtitle:
              'Please select a school from the sidebar to view notifications.',
            );
          }

          // ── Empty state ───────────────────────────────────────────────────
          if (announcementController.filteredAnnouncements.isEmpty) {
            return _buildInfoCard(
              context,
              icon: Icons.notifications_none,
              title: 'No Notifications',
              subtitle:
              'You\'re all caught up! No new announcements at the moment.',
            );
          }

          // ── List ──────────────────────────────────────────────────────────
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcementController.filteredAnnouncements.length,
            itemBuilder: (context, index) {
              final announcement =
              announcementController.filteredAnnouncements[index];
              return _AnnouncementCard(
                announcement: announcement,
                announcementController: announcementController,
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
      }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Announcement card extracted to its own widget ───────────────────────────
// Keeping it separate prevents the whole list from rebuilding on every Obx tick.

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final AnnouncementController announcementController;

  const _AnnouncementCard({
    required this.announcement,
    required this.announcementController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: _getCardGradient(announcement['type']),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetail(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(announcement['type']),
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        announcement['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openDetail(),
                      child: Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.visibility,
                              color: Colors.white, size: 15),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  announcement['description'] ?? 'No Description',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Footer row
                Row(
                  children: [
                    _Pill(
                      announcement['type']?.toString().toUpperCase() ?? 'GENERAL',
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      'By ${announcement['createdBy']?['userName'] ?? 'System'}',
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(announcement['createdAt']),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
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
  }

  void _openDetail() {
    announcementController
        .getAnnouncement(announcement['_id'])
        .then((_) {
      final fresh = announcementController.selectedAnnouncement.value ??
          announcement;
      Get.to(() => AnnouncementDetailView(announcement: fresh));
    });
  }

  Gradient _getCardGradient(String? type) {
    switch (type) {
      case 'urgent':
        return AppTheme.errorGradient;
      case 'event':
        return AppTheme.primaryGradient;
      case 'holiday':
        return AppTheme.successGradient;
      default:
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'urgent':
        return Icons.warning;
      case 'event':
        return Icons.event;
      case 'holiday':
        return Icons.celebration;
      default:
        return Icons.announcement;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}