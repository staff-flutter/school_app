import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/admin_sidebar.dart';

const double kSidebarCollapsedWidth = 64.0;
const double kSidebarExpandedWidth = 248.0;

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
          body: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── 1. Main content ──
              Positioned(
                left: kSidebarCollapsedWidth,
                top: 0,
                right: 0,
                bottom: 0,
                child: widget.child,
              ),

              // ── 2. Dim overlay ──
              Positioned.fill(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _expandedNotifier,
                  builder: (context, expanded, _) {
                    if (!expanded) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: kSidebarExpandedWidth),
                      child: GestureDetector(
                        onTap: () => _expandedNotifier.value = false,
                        onPanUpdate: (_) => _expandedNotifier.value = false,
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── 3. Sidebar — always on top ──
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AdminSidebar(expandedNotifier: _expandedNotifier),
              ),
            ],
          ),
        ),
      ),
    );
  }
}