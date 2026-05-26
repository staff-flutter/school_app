import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'main_wrapper.dart';
import 'sidebar_wrapper.dart';

/// Reactively picks the right chrome based on the logged-in role.
/// Uses [Obx] so it rebuilds the moment the auth user value changes —
/// eliminating the race condition where role was '' on first build.
///
/// • **correspondent / accountant** → [SidebarWrapper]
/// • **every other role**           → [MainWrapper]
class RoleAwareWrapper extends StatelessWidget {
  final Widget child;
  const RoleAwareWrapper({super.key, required this.child});

  static const _sidebarRoles = {'correspondent', 'accountant','teacher','principal','administrator','viceprincipal',};

  @override
  Widget build(BuildContext context) {
    // final role = Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
    // final hasSidebar = ['correspondent', 'administrator', 'principal',
    //   'viceprincipal', 'teacher', 'accountant'].contains(role);
    //
    // AppBar(
    //   automaticallyImplyLeading: !hasSidebar,
    //   title: Text('Timetable'),
    // );
    // Grab the controller once; Obx makes the subtree reactive.
    AuthController? auth;
    try {
      auth = Get.find<AuthController>();
    } catch (_) {
      // AuthController not yet registered — default to MainWrapper.
      return MainWrapper(child: child);
    }

    return Obx(() {
      final role = auth!.user.value?.role?.toLowerCase() ?? '';
      print('🟡 RoleAwareWrapper rebuilding, role: $role');

      // If role is empty, show a loader instead of building the child
      // This prevents TabBar from rendering before everything is ready
      if (role.isEmpty) {
        print('🟡 role empty, showing loader');

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (_sidebarRoles.contains(role)) {
        return SidebarWrapper(child: child);
      }
      return MainWrapper(child: child);
    });
  }
}
