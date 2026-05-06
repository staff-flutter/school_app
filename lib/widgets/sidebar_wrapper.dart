import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/admin_sidebar.dart';

const double kSidebarCollapsedWidth = 64.0;

class SidebarWrapper extends StatefulWidget {
  final Widget child;
  const SidebarWrapper({super.key, required this.child});

  @override
  State<SidebarWrapper> createState() => _SidebarWrapperState();
}

class _SidebarWrapperState extends State<SidebarWrapper> {
  final ValueNotifier<bool> _expandedNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _expandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: AppTheme.appBackground,
          body: Row(
            children: [
              // ── 1. Sidebar — fixed 65 px column ──────────────────
              SizedBox(
                width: 65,
                child: AdminSidebar(expandedNotifier: _expandedNotifier),
              ),

              // ── 2. Main content — takes remaining width ───────────
              Expanded(
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}