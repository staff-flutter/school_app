import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/core/role_modules.dart';
import 'package:school_app/routes/app_routes.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kSidebarBg       = Color(0xFFFFFFFF);
const _kBorderColor     = Color(0xFFDDE6F5);
const _kDividerColor    = Color(0xFFEAF0FB);
const _kSelectedBg      = Color(0xFFEFF6FF);
const _kSelectedColor   = Color(0xFF2563EB);
const _kDefaultIcon     = Color(0xFF8A9FC0);
const _kDefaultText     = Color(0xFF1A2A3A);
const _kSectionLabel    = Color(0xFF90A4BE);
const _kFooterBg        = Color(0xFFF5F9FF);
const _kLogoutColor     = Color(0xFFDC2626);

const double _kRailWidth     = 64.0;
const double _kExpandedWidth = 248.0;
const Duration _kAnimDuration = Duration(milliseconds: 260);
const Curve _kAnimCurve = Curves.easeInOutCubic;

// ─── Widget ───────────────────────────────────────────────────────────────────

class AdminSidebar extends StatefulWidget {
  const AdminSidebar({super.key});

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _kAnimDuration);
    _progress = CurvedAnimation(parent: _ctrl, curve: _kAnimCurve);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  void _collapse() {
    if (_expanded) _toggle();
  }

  void _navigate(String route) {
    _collapse();
    Future.delayed(const Duration(milliseconds: 140), () {
      if (route.contains('?')) {
        final parts = route.split('?');
        final params = <String, dynamic>{};
        for (final seg in parts[1].split('&')) {
          final kv = seg.split('=');
          if (kv.length == 2) params[kv[0]] = kv[1];
        }
        Get.offNamed(parts[0], arguments: params);
      } else {
        Get.offNamed(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth  = Get.find<AuthController>();
    final role  = auth.user.value?.role.toLowerCase() ?? '';

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final w = _kRailWidth + (_kExpandedWidth - _kRailWidth) * _progress.value;
        return Container(
          width: w,
          decoration: BoxDecoration(
            color: _kSidebarBg,
            border: Border(
              right: BorderSide(color: _kBorderColor, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(6, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopHeader(
                expanded: _expanded,
                progress: _progress.value,
                role: role,
                onToggle: _toggle,
              ),
              Expanded(
                child: _MenuBody(
                  role: role,
                  expanded: _expanded,
                  progress: _progress.value,
                  onNavigate: _navigate,
                ),
              ),
              _FooterBar(
                expanded: _expanded,
                progress: _progress.value,
                auth: auth,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _TopHeader extends StatelessWidget {
  final bool expanded;
  final double progress;
  final String role;
  final VoidCallback onToggle;

  const _TopHeader({
    required this.expanded,
    required this.progress,
    required this.role,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: _kSidebarBg,
        border: Border(bottom: BorderSide(color: _kDividerColor, width: 1)),
      ),
      child: Row(
        children: [
          // Toggle chevron button
          _SidebarIconButton(
            icon: Icons.menu_rounded,
            active: expanded,
            onTap: onToggle,
            tooltip: expanded ? 'Collapse' : 'Expand menu',
          ),

          // App label (visible when expanding) – no school name here
          if (progress > 0.2)
            Expanded(
              child: Opacity(
                opacity: ((progress - 0.2) / 0.8).clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'School Portal',
                        style: TextStyle(
                          color: _kDefaultText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          color: _kSectionLabel,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Menu Body ────────────────────────────────────────────────────────────────

class _MenuBody extends StatelessWidget {
  final String role;
  final bool expanded;
  final double progress;
  final void Function(String) onNavigate;

  const _MenuBody({
    required this.role,
    required this.expanded,
    required this.progress,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final sections = _getSections(role);
    return ClipRect(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections
              .map((s) => _SectionBlock(
                    section: s,
                    expanded: expanded,
                    progress: progress,
                    onNavigate: onNavigate,
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ─── Section Definitions ─────────────────────────────────────────────────

  static List<_Section> _getSections(String role) {
    if (role == 'accountant') {
      return [
        _Section(title: 'Menu', items: [
          _Item('Dashboard', Icons.dashboard_rounded, AppRoutes.ACCOUNTING_DASHBOARD),
        ]),
        _Section(title: 'Finance', items: [
          if (RoleModules.hasModule(role, 'feeCollection'))
            _Item('Fee Collection', Icons.payments_rounded, AppRoutes.FEE_COLLECTION),
          if (RoleModules.hasModule(role, 'feeStructure'))
            _Item('Fee Structure', Icons.account_balance_wallet_rounded, AppRoutes.FEE_STRUCTURE),
          if (RoleModules.hasModule(role, 'expenses'))
            _Item('Expenses', Icons.receipt_long_rounded, AppRoutes.EXPENSES),
          if (RoleModules.hasModule(role, 'reports'))
            _Item('Reports', Icons.bar_chart_rounded, AppRoutes.REPORTS),
          if (RoleModules.hasModule(role, 'studentRecords'))
            _Item('Student Records', Icons.folder_shared_rounded, AppRoutes.STUDENT_RECORDS),
        ]),
        _Section(title: 'Other', items: [
          _Item('Profile', Icons.person_rounded, '/profile'),
        ]),
      ];
    }

    // Correspondent (default admin)
    return [
      _Section(title: 'Menu', items: [
        _Item('Dashboard', Icons.dashboard_rounded, AppRoutes.ACCOUNTING_DASHBOARD),
        if (RoleModules.hasModule(role, 'schoolManagement'))
          _Item('School', Icons.business_rounded, AppRoutes.SCHOOL_MANAGEMENT),
        if (RoleModules.hasModule(role, 'announcements') &&
            ApiPermissions.canCreateAnnouncement(role))
          _Item('Communications', Icons.campaign_rounded, AppRoutes.COMMUNICATIONS),
      ]),
      _Section(title: 'Finance', items: [
        if (RoleModules.hasModule(role, 'feeCollection'))
          _Item('Fee Collection', Icons.payments_rounded, AppRoutes.FEE_COLLECTION),
        if (RoleModules.hasModule(role, 'feeStructure'))
          _Item('Fee Structure', Icons.account_balance_wallet_rounded, AppRoutes.FEE_STRUCTURE),
        if (RoleModules.hasModule(role, 'expenses'))
          _Item('Expenses', Icons.receipt_long_rounded, AppRoutes.EXPENSES),
        if (RoleModules.hasModule(role, 'reports'))
          _Item('Reports', Icons.bar_chart_rounded, AppRoutes.REPORTS),
      ]),
      _Section(title: 'Manage', items: [
        if (ApiPermissions.hasApiAccess(role, 'POST /api/user/create'))
          _Item('Users', Icons.people_rounded, '${AppRoutes.SCHOOL_MANAGEMENT}?initialTab=users'),
        if (RoleModules.hasModule(role, 'students'))
          _Item('Students', Icons.school_rounded,
              '${AppRoutes.SCHOOL_MANAGEMENT}?initialTab=students'),
        if (RoleModules.hasModule(role, 'attendance'))
          _Item('Attendance', Icons.how_to_reg_rounded, AppRoutes.ATTENDANCE),
        if (RoleModules.hasModule(role, 'studentRecords'))
          _Item('Student Records', Icons.folder_shared_rounded, AppRoutes.STUDENT_RECORDS),
        if (RoleModules.hasModule(role, 'clubs'))
          _Item('Clubs & Activities', Icons.groups_rounded, AppRoutes.CLUBS_ACTIVITIES),
      ]),
      _Section(title: 'Other', items: [
        if (RoleModules.hasModule(role, 'subscription'))
          _Item('Subscription', Icons.subscriptions_rounded,
              AppRoutes.SUBSCRIPTION_MANAGEMENT),
        _Item('Profile', Icons.person_rounded, '/profile'),
        _Item('System', Icons.settings_rounded, '/system-management'),
      ]),
    ];
  }
}

// ─── Section Block ────────────────────────────────────────────────────────────

class _SectionBlock extends StatelessWidget {
  final _Section section;
  final bool expanded;
  final double progress;
  final void Function(String) onNavigate;

  const _SectionBlock({
    required this.section,
    required this.expanded,
    required this.progress,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title or thin divider
        if (expanded && progress > 0.5)
          Opacity(
            opacity: ((progress - 0.5) / 0.5).clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 18, bottom: 6),
              child: Text(
                section.title.toUpperCase(),
                style: const TextStyle(
                  color: _kSectionLabel,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
            ),
          )
        else if (!expanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Divider(height: 1, thickness: 1, color: _kDividerColor),
          ),

        // Items
        ...section.items.map((item) => _NavItem(
              item: item,
              expanded: expanded,
              progress: progress,
              onNavigate: onNavigate,
            )),
      ],
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _Item item;
  final bool expanded;
  final double progress;
  final void Function(String) onNavigate;

  const _NavItem({
    required this.item,
    required this.expanded,
    required this.progress,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    // Determine active route
    final currentRoute = Get.currentRoute;
    final itemBase = item.route.split('?')[0];
    final isActive = currentRoute == itemBase ||
        (currentRoute.contains('?') && currentRoute.split('?')[0] == itemBase);

    return Tooltip(
      message: expanded ? '' : item.label,
      preferBelow: false,
      verticalOffset: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3142),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      child: GestureDetector(
        onTap: () => onNavigate(item.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive ? _kSelectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment:
                expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              // Icon with active indicator dot
              SizedBox(
                width: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: isActive ? _kSelectedColor : _kDefaultIcon,
                    ),
                    if (isActive && !expanded)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _kSelectedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Label (fades in as sidebar expands)
              if (progress > 0.25)
                Expanded(
                  child: Opacity(
                    opacity: ((progress - 0.25) / 0.75).clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: isActive ? _kSelectedColor : _kDefaultText,
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),

              // Active dot on the right when expanded
              if (isActive && progress > 0.6)
                Opacity(
                  opacity: ((progress - 0.6) / 0.4).clamp(0.0, 1.0),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _kSelectedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Footer Bar ───────────────────────────────────────────────────────────────

class _FooterBar extends StatelessWidget {
  final bool expanded;
  final double progress;
  final AuthController auth;

  const _FooterBar({
    required this.expanded,
    required this.progress,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kFooterBg,
        border: Border(top: BorderSide(color: _kDividerColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User avatar row
          Tooltip(
            message: expanded ? '' : auth.user.value?.userName ?? 'User',
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 10 : 0,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment:
                    expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  // Avatar circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Obx(() => Text(
                        (auth.user.value?.userName ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      )),
                    ),
                  ),

                  if (progress > 0.25)
                    Expanded(
                      child: Opacity(
                        opacity: ((progress - 0.25) / 0.75).clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Obx(() => Text(
                                auth.user.value?.userName ?? 'User',
                                style: const TextStyle(
                                  color: _kDefaultText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                              Obx(() => Text(
                                auth.user.value?.email ?? '',
                                style: const TextStyle(
                                  color: _kSectionLabel,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 2),

          // Logout row
          Tooltip(
            message: expanded ? '' : 'Logout',
            child: GestureDetector(
              onTap: () => _confirmLogout(auth),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: expanded ? 10 : 0,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: expanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        size: 18, color: _kLogoutColor),
                    if (progress > 0.3)
                      Opacity(
                        opacity: ((progress - 0.3) / 0.7).clamp(0.0, 1.0),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: _kLogoutColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(AuthController auth) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(
              color: _kDefaultText, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: _kSectionLabel, fontSize: 13),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(color: _kSectionLabel, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kLogoutColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child:
                const Text('Logout', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Small Icon Button ────────────────────────────────────────────────────────

class _SidebarIconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;

  const _SidebarIconButton({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: _kAnimDuration,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? _kSelectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? _kSelectedColor : _kDefaultIcon,
          ),
        ),
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class _Section {
  final String title;
  final List<_Item> items;
  _Section({required this.title, required this.items});
}

class _Item {
  final String label;
  final IconData icon;
  final String route;
  _Item(this.label, this.icon, this.route);
}
