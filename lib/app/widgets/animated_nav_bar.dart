import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_navigation_controller.dart';

class AnimatedNavBar extends StatelessWidget {
  const AnimatedNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainNavigationController>();

    return Obx(() {
      final items = controller.navigationItems;
      if (items.isEmpty) return const SizedBox();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(42),

          /// REALISTIC DEPTH SHADOW
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xffC4B5FD).withOpacity(.35),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(.7),
              blurRadius: 12,
              offset: const Offset(-6, -6),
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(42),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(42),

                /// GLASS BASE
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(.55),
                    const Color(0xffE9D5FF).withOpacity(.28),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                /// GLASS EDGE
                border: Border.all(
                  color: Colors.white.withOpacity(.5),
                  width: 1.3,
                ),
              ),

              child: Stack(
                children: [

                  /// TOP LIGHT REFLECTION
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 28,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(.35),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// NAV ITEMS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(items.length, (index) {
                        final isSelected =
                            controller.selectedIndex.value == index;
                        final item = items[index];

                        return Flexible(
                          child: _NavItem(
                            icon: _getIcon(item.label),
                            isSelected: isSelected,
                            onTap: () => controller.onItemTapped(index),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// ICON MAP
  IconData _getIcon(String label) {
    switch (label.toLowerCase()) {
      case 'dashboard': return Icons.dashboard_rounded;
      case 'school': return Icons.school_rounded;
      case 'profile': return Icons.person_rounded;
      case 'subscription': return Icons.subscriptions_rounded;
      case 'attendance': return Icons.how_to_reg_rounded;
      case 'clubs': return Icons.groups_rounded;
      case 'homework': return Icons.assignment_rounded;
      case 'timetable': return Icons.schedule_rounded;
      case 'my classes': return Icons.class_rounded;
      default: return Icons.grid_view_rounded;
    }
  }
}

////////////////////////////////////////////////////////////
/// NAV ITEM
////////////////////////////////////////////////////////////

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [

            /// GLOW CAPSULE BACK
            AnimatedOpacity(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              opacity: isSelected ? 1 : 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: isSelected ? 102 : 56,
                height: isSelected ? 40 : 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  /// GRADIENT
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xffDDD6FE), // light highlight
                      Color(0xffA78BFA), // main purple
                      Color(0xff7C3AED), // deep vibrant
                    ],


                ),

                  /// ⭐ THICK BORDER ADDED
                  border: Border.all(
                    color: Colors.white.withOpacity(.55),
                    width: 1.5,
                  ),

                  /// SHADOWS
                  boxShadow: [

                    /// depth shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(.18),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),

                    /// glow
                    BoxShadow(
                      color: const Color(0xffC4B5FD).withOpacity(.65),
                      blurRadius: 35,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),

            /// ICON WITH BOTTOM SHADOW
            AnimatedScale(
              duration: const Duration(milliseconds: 280),
              curve: const Cubic(0.34, 1.56, 0.64, 1),
              scale: isSelected ? 1.35 : 1,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: isSelected
                      ? [

                    /// CLOSE SHADOW
                    BoxShadow(
                      color: Colors.black.withOpacity(.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),

                    /// FAR SOFT SHADOW
                    BoxShadow(
                      color: Colors.black.withOpacity(.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),

                    /// SUBTLE PURPLE GLOW DEPTH
                    BoxShadow(
                      color: const Color(0xff7C3AED).withOpacity(.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                      : [],


                ),
                child: Icon(
                  icon,
                  size: isSelected ? 20 : 24,
                  color: isSelected
                      ? Colors.white.withOpacity(0.95)


                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

