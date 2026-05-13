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
              // ── 1. Main content — offset by collapsed sidebar width ──
              Positioned(
                left: kSidebarCollapsedWidth,
                top: 0,
                right: 0,
                bottom: 0,
                child: widget.child,
              ),

              // ── 2. Sidebar — overlays content when expanded ──────────
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _expandedNotifier,
                  builder: (context, expanded, _) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Dim backdrop when expanded — tap to collapse
                        if (expanded)
                          Positioned(
                            left: kSidebarExpandedWidth,
                            top: 0,
                            bottom: 0,
                            width: MediaQuery.of(context).size.width -
                                kSidebarExpandedWidth,
                            child: GestureDetector(
                              onTap: () => _expandedNotifier.value = false,
                              child: Container(
                                color: Colors.black.withOpacity(0.18),
                              ),
                            ),
                          ),
                        // The sidebar itself — always visible, grows on expand
                        AdminSidebar(expandedNotifier: _expandedNotifier),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}