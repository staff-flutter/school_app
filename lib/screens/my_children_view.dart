import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:school_app/controllers/my_children_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/screens/details_of_student_view.dart';

// Pastel palette for child avatar rings — cycles by index
const List<List<Color>> _kChildPalettes = [
  [Color(0xFF8E7CFF), Color(0xFF6A5AE0)],
  [Color(0xFFFF8A3D), Color(0xFFFF6200)],
  [Color(0xFF4CC9F0), Color(0xFF0096C7)],
  [Color(0xFFFF6B9D), Color(0xFFC9184A)],
  [Color(0xFF8EDB4F), Color(0xFF52B788)],
  [Color(0xFFFFD60A), Color(0xFFFFB700)],
];

List<Color> _paletteFor(int index) =>
    _kChildPalettes[index % _kChildPalettes.length];

class MyChildrenView extends StatefulWidget {
  const MyChildrenView({super.key});

  @override
  State<MyChildrenView> createState() => _MyChildrenViewState();
}

class _MyChildrenViewState extends State<MyChildrenView>
    with SingleTickerProviderStateMixin {
  late MyChildrenController controller;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    controller = Get.find<MyChildrenController>();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMyChildren();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MyChildrenController>(
      builder: (controller) => Scaffold(
        backgroundColor: const Color(0xFFF6F4FF),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) return _buildLoadingState();
                if (controller.children.isEmpty) return _buildEmptyState();
                return _buildChildList(controller);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9D8FFF), Color(0xFF5C4FC7)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Children',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Progress, attendance & more',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _HeaderBtn(
                    icon: Icons.notifications_outlined,
                    onTap: () => Get.toNamed('/notifications'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Wave divider bottom
            SizedBox(
              height: 28,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _WavePainter()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildList(MyChildrenController controller) {
    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      onRefresh: controller.loadMyChildren,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        itemCount: controller.children.length,
        itemBuilder: (context, index) {
          final child = controller.children[index];
          return _ChildCard(
            child: child,
            index: index,
            animCtrl: _animCtrl,
            onAttendance: () => controller.viewChildAttendance(
              child['_id'] ?? '',
              child['studentName'] ?? 'Unknown Student',
            ),
            onDetails: () {
              final studentData = {
                'studentName': child['studentName'],
                'srId': child['srId'],
                'className': child['className'],
                'sectionName': child['sectionName'],
                '_id': child['_id'],
                'studentImage': child['studentImage'],
                'mandatory': child['mandatory'] ?? {},
                'nonMandatory': child['nonMandatory'] ?? {},
                'clubs': child['clubs'] ?? [],
              };
              Get.to(() => const DetailsOfStudentView(), arguments: studentData);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8E7CFF), Color(0xFF5C4FC7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your children...',
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('👨\u200d👧\u200d👦',
                    style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No children linked yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact your school admin to link\nyour children to this account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CHILD CARD ───────────────────────────────────────────────────────────────

class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final int index;
  final AnimationController animCtrl;
  final VoidCallback onAttendance;
  final VoidCallback onDetails;

  const _ChildCard({
    required this.child,
    required this.index,
    required this.animCtrl,
    required this.onAttendance,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(index);
    final name = child['studentName'] as String? ?? 'Student';
    final className = child['className'] as String? ?? '-';
    final sectionName = child['sectionName'] as String? ?? '-';
    final imageData = child['studentImage'];
    final hasImage =
        imageData is Map && (imageData['url'] as String?)?.isNotEmpty == true;

    final double start = (index * 0.12).clamp(0.0, 0.6);
    final double end = (start + 0.45).clamp(0.2, 1.0);

    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: animCtrl, curve: Interval(start, end, curve: Curves.easeOutCubic)));

    final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: animCtrl, curve: Interval(start, end)));

    return AnimatedBuilder(
      animation: animCtrl,
      builder: (context, _) => FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: palette[0].withOpacity(0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDetails,
                  splashColor: palette[0].withOpacity(0.08),
                  highlightColor: palette[0].withOpacity(0.04),
                  child: Column(
                    children: [
                      // Color stripe top
                      Container(
                        height: 5,
                        decoration:
                            BoxDecoration(gradient: LinearGradient(colors: palette)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _Avatar(
                                  name: name,
                                  imageUrl:
                                      hasImage ? imageData['url'] as String : null,
                                  palette: palette,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1C1C1E),
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          _InfoChip(
                                              label: 'Class $className',
                                              color: palette[0]),
                                          _InfoChip(
                                              label: 'Sec $sectionName',
                                              color: const Color(0xFF52B788)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: palette[0].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.chevron_right_rounded,
                                      color: palette[0], size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: Color(0xFFF2F0FB)),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionBtn(
                                    label: 'Attendance',
                                    icon: Icons.how_to_reg_rounded,
                                    gradient: LinearGradient(colors: palette),
                                    onTap: onAttendance,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ActionBtn(
                                    label: 'View Details',
                                    icon: Icons.person_search_rounded,
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFF4CC9F0),
                                      Color(0xFF0096C7)
                                    ]),
                                    onTap: onDetails,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── AVATAR ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final List<Color> palette;
  const _Avatar({required this.name, required this.palette, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
            colors: palette,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
              color: palette[0].withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initial(name: name))
            : _Initial(name: name),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  final String name;
  const _Initial({required this.name});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: const TextStyle(
            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ─── INFO CHIP ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.1)),
    );
  }
}

// ─── ACTION BUTTON ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.gradient,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: gradient.colors.first.withOpacity(0.28),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── HEADER BUTTON ────────────────────────────────────────────────────────────

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─── WAVE PAINTER ─────────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF6F4FF)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 1.2, size.width, size.height * 0.4);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => false;
}
