import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';

import '../controllers/school_controller.dart';

// ─── Design tokens matching AccountingDashboardView ──────────────────────────
const _kBg          = Color(0xFFF0F5FF);
const _kBlue        = Color(0xFF2563EB);
const _kBorder      = Color(0xFFDDE6F5);
const _kTextPrimary = Color(0xFF1A2A3A);
const _kTextMuted   = Color(0xFF90A4BE);

class CorrespondentProfileView extends StatelessWidget {
  const CorrespondentProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final schoolCtrl = Get.isRegistered<SchoolController>()
        ? Get.find<SchoolController>()
        : null;

    return Scaffold(
      backgroundColor: _kBg,
      body: Obx(() {
        final user = auth.user.value;
        final role = user?.role?.toLowerCase() ?? '';

        Map<String, dynamic>? school;
        if (role == 'correspondent' && schoolCtrl != null) {
          final selected = schoolCtrl.selectedSchool.value;
          if (selected != null) {
            school = {
              '_id':                 selected.id,
              'name':                selected.name,
              'email':               selected.email ?? '',
              'phoneNo':             selected.phoneNo ?? '',
              'address':             selected.address ?? '',
              'currentAcademicYear': selected.currentAcademicYear ?? '',
              'logo':                selected.logo,
            };
          }
        } else {
          school = auth.userSchool.value;
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _card(
                  child: Row(
                    children: [
                      _schoolLogo(school),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              school?['name'] ?? 'School Portal',
                              style: const TextStyle(
                                color: _kTextPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'My Profile',
                              style: TextStyle(color: _kTextMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Avatar + name — unchanged
                _card(
                  child: Column(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF60A5FA), _kBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (user?.userName ?? 'U').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(user?.userName ?? 'User',
                          style: const TextStyle(
                            color: _kTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kBlue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (user?.role ?? 'User').toUpperCase(),
                          style: const TextStyle(
                            color: _kBlue, fontSize: 11,
                            fontWeight: FontWeight.w700, letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Account info — unchanged
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Account Information'),
                      const SizedBox(height: 12),
                      _infoRow(Icons.person_outline_rounded, 'Username', user?.userName ?? '—'),
                      _divider(),
                      _infoRow(Icons.email_outlined, 'Email', user?.email ?? '—'),
                      _divider(),
                      _infoRow(Icons.badge_outlined, 'Role', user?.role ?? '—'),
                      if (user?.schoolId != null) ...[
                        _divider(),
                        _infoRow(Icons.business_rounded, 'School ID', user!.schoolId!),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // School info — now uses sidebar-selected school
                if (school != null)
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('School Information'),
                        const SizedBox(height: 12),
                        _infoRow(Icons.school_rounded, 'School Name', school['name'] ?? '—'),
                        if ((school['email'] ?? '').isNotEmpty) ...[
                          _divider(),
                          _infoRow(Icons.alternate_email_rounded, 'School Email', school['email']),
                        ],
                        if ((school['phoneNo'] ?? '').isNotEmpty) ...[
                          _divider(),
                          _infoRow(Icons.phone_outlined, 'Phone', school['phoneNo']),
                        ],
                        if ((school['address'] ?? '').isNotEmpty) ...[
                          _divider(),
                          _infoRow(Icons.location_on_outlined, 'Address', school['address']),
                        ],
                        if ((school['currentAcademicYear'] ?? '').isNotEmpty) ...[
                          _divider(),
                          _infoRow(Icons.calendar_today_outlined, 'Academic Year', school['currentAcademicYear']),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Logout — unchanged
                GestureDetector(
                  onTap: () => _confirmLogout(auth),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDDE6F5).withOpacity(0.5),
                          blurRadius: 8, offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 8),
                        Text('Logout',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            )),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _kTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kBlue, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _kTextMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Divider(height: 1, color: _kBorder),
      );

  Widget _schoolLogo(dynamic school) {
    try {
      if (school != null &&
          school['logo'] != null &&
          school['logo']['url'] != null) {
        return GestureDetector(
          onTap: () => _showFullScreenSchoolLogo(school['logo']['url']),
          child: ClipOval(
            child: Image.network(
              school['logo']['url'],
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF2563EB),
                  size: 30,
                );
              },
            ),
          ),
        );
      }
    } catch (_) {}
    return _defaultLogoIcon();
  }

  Widget _defaultLogoIcon() => const Icon(
        Icons.school_rounded,
        color: _kBlue,
        size: 30,
      );

  void _confirmLogout(AuthController auth) {
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(
                color: _kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: _kTextMuted, fontSize: 13),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(color: _kTextMuted, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Logout', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showFullScreenSchoolLogo(String logoUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        Get.back();
                        Get.snackbar(
                          'Error',
                          'Failed to load logo',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }}
