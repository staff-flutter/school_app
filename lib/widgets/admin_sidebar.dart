import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/core/role_modules.dart';
import 'package:school_app/routes/app_routes.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg           = Color(0xFFFFFFFF);
const _kBorderColor  = Color(0xFFDDE6F5);
const _kDividerColor = Color(0xFFEAF0FB);
const _kSelectedBg   = Color(0xFFEFF6FF);
const _kSelectedClr  = Color(0xFF2563EB);
const _kIconDefault  = Color(0xFF8A9FC0);
const _kTextDefault  = Color(0xFF1A2A3A);
const _kSectionLabel = Color(0xFF90A4BE);
const _kFooterBg     = Color(0xFFF5F9FF);
const _kLogoutClr    = Color(0xFFDC2626);

const double _kRailWidth     = 64.0;
const double _kExpandedWidth = 248.0;
const _kDuration = Duration(milliseconds: 260);
const _kCurve    = Curves.easeInOutCubic;

// ─── MAIN SCAFFOLD WRAPPER ───────────────────────────────────────────────────
// Use this as your top-level page structure
class AdminScaffold extends StatefulWidget {
  final Widget body;
  const AdminScaffold({super.key, required this.body});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Row(
        children: [
          // The Sidebar
          AdminSidebar(expandedNotifier: _isExpanded),

          // The Main Content Area
          Expanded(
            child: GestureDetector(
              // behavior: opaque ensures taps on empty space are captured
              behavior: HitTestBehavior.opaque,
              onTap: () {
                print("👍 Screen tapped! Sidebar open: ${_isExpanded.value}");
                if (_isExpanded.value) {
                  _isExpanded.value = false;
                }
              },
              child: widget.body,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SIDEBAR WIDGET ──────────────────────────────────────────────────────────

class AdminSidebar extends StatefulWidget {
  final ValueNotifier<bool>? expandedNotifier;
  const AdminSidebar({super.key, this.expandedNotifier});

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _anim;
  late final Animation<double> _progress;
  final ValueNotifier<String> _selectedKey = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: _kDuration);
    _progress = CurvedAnimation(parent: _anim, curve: _kCurve);
    widget.expandedNotifier?.addListener(_onExternal);
    _selectedKey.value = Get.currentRoute;
  }

  void _onExternal() {
    final v = widget.expandedNotifier?.value ?? false;
    if (v != _expanded) _setExpanded(v);
  }

  @override
  void dispose() {
    widget.expandedNotifier?.removeListener(_onExternal);
    _anim.dispose();
    _selectedKey.dispose();
    super.dispose();
  }

  void _setExpanded(bool v) {
    if (!mounted) return;
    setState(() => _expanded = v);
    v ? _anim.forward() : _anim.reverse();
  }

  void _toggle() {
    final newValue = !_expanded;
    if (widget.expandedNotifier != null) {
      widget.expandedNotifier!.value = newValue;
    } else {
      _setExpanded(newValue);
    }
  }

  void _navigate(String route) {
    final activeKey = route.contains('?') ? route.split('?')[0] : route;
    _selectedKey.value = activeKey;

    // Auto-collapse on navigation
    if (widget.expandedNotifier != null) {
      widget.expandedNotifier!.value = false;
    } else {
      _setExpanded(false);
    }

    Future.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      if (route.contains('?')) {
        final parts  = route.split('?');
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
    final topPad = MediaQuery.of(context).padding.top;
    String role = '';
    try {
      role = Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
    } catch (_) {}

    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) {
        final w = _kRailWidth + (_kExpandedWidth - _kRailWidth) * _progress.value;
        return Container(
          width: w,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            color: _kBg,
            border: Border(right: BorderSide(color: _kBorderColor, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(6, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                topPad: topPad,
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
                  selectedKey: _selectedKey,
                ),
              ),
              _Footer(expanded: _expanded, progress: _progress.value),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  final bool expanded;
  final double progress;
  final String role;
  final VoidCallback onToggle;
  const _Header({
    required this.topPad,
    required this.expanded,
    required this.progress,
    required this.role,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 + topPad,
      padding: EdgeInsets.only(left: 10, right: 10, top: topPad + 12, bottom: 4),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kDividerColor)),
      ),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.menu_rounded,
            active: expanded,
            onTap: onToggle,
            tooltip: expanded ? 'Collapse' : 'Expand menu',
          ),
          if (progress > 0.2)
            Expanded(
              child: ClipRect(
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
                              color: _kTextDefault,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
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
                              letterSpacing: 1.1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Menu body ────────────────────────────────────────────────────────────────

class _MenuBody extends StatelessWidget {
  final String role;
  final bool expanded;
  final double progress;
  final void Function(String) onNavigate;
  final ValueNotifier<String> selectedKey;

  const _MenuBody({
    required this.role,
    required this.expanded,
    required this.progress,
    required this.onNavigate,
    required this.selectedKey,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _getSections(role)
              .map((s) => _SectionBlock(
            section: s,
            expanded: expanded,
            progress: progress,
            onNavigate: onNavigate,
            selectedKey: selectedKey,
          ))
              .toList(),
        ),
      ),
    );
  }

  static List<_Section> _getSections(String role) {
    if (role == 'accountant') {
      return [
        _Section('Menu', [
          _Item('Dashboard', Icons.dashboard_rounded, AppRoutes.ACCOUNTING_DASHBOARD),
        ]),
        _Section('Finance', [
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
        _Section('Other', [
          _Item('Profile', Icons.person_rounded, '/profile'),
        ]),
      ];
    }
    else if(role== 'administrator') {
      return [
        _Section('Menu', [
          _Item('Dashboard', Icons.dashboard_rounded, AppRoutes.ACCOUNTING_DASHBOARD),
          _Item('School', Icons.business_rounded, AppRoutes.SCHOOL_MANAGEMENT),
          _Item('Communications', Icons.campaign_rounded, AppRoutes.COMMUNICATIONS),
        ]),
        _Section('Finance', [
          _Item('Fee Structure', Icons.account_balance_wallet_rounded, AppRoutes.FEE_STRUCTURE),
        ]),
        _Section('Manage', [
          _Item('Users', Icons.people_rounded, '${AppRoutes.SCHOOL_MANAGEMENT}?initialTab=users'),
          _Item('Students', Icons.school_rounded, '${AppRoutes.SCHOOL_MANAGEMENT}?initialTab=students'),
          _Item('Teachers', Icons.person_rounded, '${AppRoutes.SCHOOL_MANAGEMENT}?initialTab=teachers'),
          _Item('Attendance', Icons.how_to_reg_rounded, AppRoutes.ATTENDANCE),
          _Item('Student Records', Icons.folder_shared_rounded, AppRoutes.STUDENT_RECORDS),
          _Item('Academics', Icons.menu_book_rounded, AppRoutes.ACADEMICS),
          _Item('Clubs & Activities', Icons.groups_rounded, AppRoutes.CLUBS_ACTIVITIES),
<<<<<<< Updated upstream
        if (RoleModules.hasModule(role, 'campusManagementPage'))
          _Item('Campus Management', Icons.account_balance_rounded, AppRoutes.CAMPUS_MANAGEMENT_PAGE),
      ]),
      _Section('Other', [
        if (RoleModules.hasModule(role, 'subscription'))
          _Item('Subscription', Icons.subscriptions_rounded,
              AppRoutes.SUBSCRIPTION_MANAGEMENT),
=======
        ]),
        _Section('Other', [
          _Item('Profile', Icons.person_rounded, '/profile'),
        ]),
      ];
    }
    else if(role== 'principal') {
      return [
        _Section('Menu', [
          _Item('Dashboard', Icons.dashboard_rounded, AppRoutes.ACCOUNTING_DASHBOARD),
          _Item('Communications', Icons.campaign_rounded, AppRoutes.COMMUNICATIONS),
        ]),
        _Section('Finance', [
          _Item('Fee Structure', Icons.account_balance_wallet_rounded, AppRoutes.FEE_STRUCTURE),
          _Item('Reports', Icons.bar_chart_rounded, AppRoutes.REPORTS),
          _Item('Transactions', Icons.swap_horiz_rounded, '/finance_transactions'),
        ]),
        _Section('Manage', [
          _Item('Students', Icons.school_rounded, '${AppRoutes.SCHOOL_MANAGEMENT}?initialTab=students'),
          _Item('Student Records', Icons.folder_shared_rounded, AppRoutes.STUDENT_RECORDS),
          _Item('Clubs & Activities', Icons.groups_rounded, AppRoutes.CLUBS_ACTIVITIES),
          _Item('Campus Management', Icons.admin_panel_settings_rounded, AppRoutes.CAMPUS_MANAGEMENT),
        ]),
        _Section('Other', [
          _Item('Profile', Icons.person_rounded, '/profile'),
        ]),
      ];
    }
    else if(role == 'teacher'){
      return [
        _Section('Menu', [
          _Item('Dashboard', Icons.dashboard_rounded, AppRoutes.ACCOUNTING_DASHBOARD),
          _Item('Communications', Icons.campaign_rounded,  AppRoutes.COMMUNICATIONS),
        ]),
        _Section('My Work', [
          _Item('My Classes', Icons.class_rounded, '/teacher-classes'),
          _Item('Attendance', Icons.how_to_reg_rounded,  AppRoutes.ATTENDANCE),
          _Item('Clubs & Activities', Icons.groups_rounded,    AppRoutes.CLUBS_ACTIVITIES),
          _Item('Timetable', Icons.calendar_today_rounded, AppRoutes.TIMETABLE_MANAGEMENT),
          _Item('Homework', Icons.assignment_rounded,  AppRoutes.HOMEWORK_MANAGEMENT),
        ]),
        _Section('Other', [
          _Item('Profile', Icons.person_rounded, '/profile'),
        ]),
      ];
    }

    return [
      _Section('Menu', [
        _Item('Dashboard', Icons.dashboard_rounded, AppRoutes.ACCOUNTING_DASHBOARD),
>>>>>>> Stashed changes
        _Item('Profile', Icons.person_rounded, '/profile'),
      ]),
    ];
  }
}

// ─── Section block ────────────────────────────────────────────────────────────

class _SectionBlock extends StatelessWidget {
  final _Section section;
  final bool expanded;
  final double progress;
  final void Function(String) onNavigate;
  final ValueNotifier<String> selectedKey;

  const _SectionBlock({
    required this.section,
    required this.expanded,
    required this.progress,
    required this.onNavigate,
    required this.selectedKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    letterSpacing: 1.3),
              ),
            ),
          )
        else if (!expanded)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Divider(height: 1, thickness: 1, color: _kDividerColor),
          ),
        ...section.items.map((item) => _NavItem(
          item: item,
          expanded: expanded,
          progress: progress,
          onNavigate: onNavigate,
          selectedKey: selectedKey,
        )),
      ],
    );
  }
}

// ─── Nav item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _Item item;
  final bool expanded;
  final double progress;
  final void Function(String) onNavigate;
  final ValueNotifier<String> selectedKey;

  const _NavItem({
    required this.item,
    required this.expanded,
    required this.progress,
    required this.onNavigate,
    required this.selectedKey,
  });

  bool _isActive(String sel) {
    if (sel == item.route) return true;
    final selBase  = sel.split('?')[0];
    final itemBase = item.route.split('?')[0];
    return selBase == itemBase;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedKey,
      builder: (context, sel, _) {
        final active = _isActive(sel);
        return Tooltip(
          message: expanded ? '' : item.label,
          child: GestureDetector(
            onTap: () => onNavigate(item.route),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              padding: EdgeInsets.symmetric(
                  horizontal: progress > 0.8 ? 12 : 0,
                  vertical: 10),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: active ? _kSelectedBg : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: progress > 0.5
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: active ? _kSelectedClr : _kIconDefault,
                    ),
                  ),
                  if (progress > 0.6)
                    Expanded(
                      child: Opacity(
                        opacity: ((progress - 0.6) / 0.4).clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: active ? _kSelectedClr : _kTextDefault,
                              fontSize: 13,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final bool expanded;
  final double progress;
  const _Footer({required this.expanded, required this.progress});

  @override
  Widget build(BuildContext context) {
    AuthController? auth;
    try { auth = Get.find<AuthController>(); } catch (_) {}

    return ClipRect(
      child: Container(
        decoration: const BoxDecoration(
          color: _kFooterBg,
          border: Border(top: BorderSide(color: _kDividerColor)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(
            mainAxisAlignment: progress > 0.25
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: auth == null
                      ? const Icon(Icons.person, color: Colors.white, size: 16)
                      : Obx(() => Text(
                      (auth!.user.value?.userName ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13))),
                ),
              ),
              if (progress > 0.25 && auth != null)
                Expanded(
                  child: ClipRect(
                    child: Opacity(
                      opacity: ((progress - 0.25) / 0.75).clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Obx(() => Text(
                                auth!.user.value?.userName ?? 'User',
                                style: const TextStyle(
                                    color: _kTextDefault,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                            Obx(() => Text(
                                auth!.user.value?.email ?? '',
                                style: const TextStyle(
                                    color: _kSectionLabel, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: () => _confirmLogout(auth),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: progress > 0.3
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, size: 18, color: _kLogoutClr),
                  if (progress > 0.3)
                    Expanded(
                      child: ClipRect(
                        child: Opacity(
                          opacity: ((progress - 0.3) / 0.7).clamp(0.0, 1.0),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Text('Logout',
                                style: TextStyle(
                                    color: _kLogoutClr,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmLogout(AuthController? auth) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Get.back(); auth?.logout(); },
          style: ElevatedButton.styleFrom(backgroundColor: _kLogoutClr),
          child: const Text('Logout', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }
}

// ─── Small icon button ────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;
  const _IconBtn({
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
          duration: _kDuration,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? _kSelectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: active ? _kSelectedClr : _kIconDefault),
        ),
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class _Section {
  final String title;
  final List<_Item> items;
  _Section(this.title, this.items);
}

class _Item {
  final String label;
  final IconData icon;
  final String route;
  _Item(this.label, this.icon, this.route);
}