import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart'; // Retained your project path imports
import '../routes/app_routes.dart';
import '../widgets/primary_button.dart';
import 'login_page_for_daily_grades.dart';
import 'login_view.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  int page = 0;

  // The 4 clean sub-layouts designated for your PageView viewspace
  final List<Widget> onboardingPages = [
    const FirstPageLayout(),
    const SecondPageLayout(),
    const ThirdPageLayout(),
    const FourthPageLayout(),
  ];

  void finish() {
    Get.offNamed(AppRoutes.ACCOUNTING_DASHBOARD);
  }
  Future<void> _completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false); // Mark onboarding as complete

    // Navigate to Login Page
    Get.offAll(() => const LoginView());
  }
  @override
  Widget build(BuildContext context) {
    final last = page == onboardingPages.length - 1;

    // Unified palette used globally across controls
    const Color primaryBlue = Color(0xFF0D2344);
    const Color primaryRed = Color(0xFFE51A1A);
    const Color dotInactive = Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Unified layout background
      body: SafeArea(
        child: Column(
          children: [
            // 1. Single Global Skip Button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: finish,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Main Page View Content Area
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: onboardingPages.length,
                onPageChanged: (value) => setState(() => page = value),
                itemBuilder: (_, index) {
                  return onboardingPages[index];
                },
              ),
            ),

            const SizedBox(height: 16),

            // 3. Single Global Page Indicator Dots Tracker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingPages.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: index == page ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == page ? primaryRed : dotInactive,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),

            // 4. Single Global Custom Navigation Action Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: last ? 'Get Started' : 'Next',
                onPressed: () {
                  if (last) {
                    DailyGradesLoginScreen();
                  } else {
                    controller.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 1: CLEAN CONTENT LAYOUT
// ==========================================
class FirstPageLayout extends StatelessWidget {
  const FirstPageLayout({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0D2344);
    const Color textSecondary = Color(0xFF5A6E85);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Welcome to',
            style: TextStyle(
              color: primaryBlue,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const Text(
            'Daily Grades',
            style: TextStyle(
              color: primaryBlue,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your smart school companion to track grades, attendance, homework, and school updates—all in one place.',
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                // Swap Image.network with Image.asset('assets/welcome_illustration.png') later
                child: Image.asset(
                  'assets/images/school_bag_transparent (2).png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.school_outlined,
                      size: 180,
                      color: primaryBlue,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 2: CLEAN CONTENT LAYOUT
// ==========================================
class SecondPageLayout extends StatelessWidget {
  const SecondPageLayout({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0D2344);
    const Color textSecondary = Color(0xFF5A6E85);
    const Color greenAccent = Color(0xFF10B981);
    const Color primaryRed = Color(0xFFE51A1A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Track daily progress\nand assignments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryBlue,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Stay on top of classes, due dates,\nand attendance every day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Overview",
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.calendar_month_outlined, color: primaryBlue.withValues(alpha: 0.8)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard('Classes Today', '5', primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard('Attendance', 'Present', greenAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming Assignments',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('View All', style: TextStyle(color: textSecondary, fontSize: 13)),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildAssignmentTile(Icons.assignment_outlined, const Color(0xFFEFF6FF), Colors.blue, 'Math Homework', 'Algebra Chapter 4', 'Due Today', primaryRed),
                        _buildAssignmentTile(Icons.science_outlined, const Color(0xFFECFDF5), greenAccent, 'Science Lab Report', 'Experiment 3', 'Due Tomorrow', textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAssignmentTile(IconData icon, Color bg, Color iconCol, String title, String sub, String due, Color dueCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconCol, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF0D2344), fontSize: 14, fontWeight: FontWeight.bold)),
                Text(sub, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Text(due, style: TextStyle(color: dueCol, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 3: CLEAN CONTENT LAYOUT
// ==========================================
class ThirdPageLayout extends StatelessWidget {
  const ThirdPageLayout({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0D2344);
    const Color textSecondary = Color(0xFF5A6E85);
    const Color greenAccent = Color(0xFF10B981);
    const Color lineBlue = Color(0xFF3B82F6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'View results and\nunderstand growth.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryBlue,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'See your performance, subject-wise\ninsights, and areas to improve.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overall Performance', style: TextStyle(color: primaryBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: 0.82,
                              strokeWidth: 12,
                              backgroundColor: Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(greenAccent),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('82%', style: TextStyle(color: primaryBlue.withValues(alpha: 0.9), fontSize: 30, fontWeight: FontWeight.bold)),
                              const Text('Overall Score', style: TextStyle(color: textSecondary, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildMetricItem('Average Grade', 'B+')),
                        Container(width: 1, height: 35, color: const Color(0xFFE2E8F0)),
                        Expanded(child: _buildMetricItem('Subjects', '6')),
                      ],
                    ),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Performance Trend', style: TextStyle(color: primaryBlue, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('This Week v', style: TextStyle(color: textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: CustomPaint(painter: TrendLinePainter(lineColor: lineBlue, lastDotColor: greenAccent)),
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

  Widget _buildMetricItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Color(0xFF0D2344), fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ==========================================
// SCREEN 4: CLEAN CONTENT LAYOUT
// ==========================================
// ==========================================
// SCREEN 4: CORRECT TROPHY LAYOUT SPECIFICATION
// ==========================================
class FourthPageLayout extends StatelessWidget {
  const FourthPageLayout({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0D2344);
    const Color textSecondary = Color(0xFF5A6E85);
    const Color primaryRed = Color(0xFFE51A1A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Centered Header Design
          const Text(
            'Stay connected\nand achieve more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryBlue,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Centered Subtitle
          const Text(
            'Get school updates, communicate\neasily, and celebrate achievements.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. Soft Circular Wave Backdrop behind the Trophy
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFEFF6FF).withValues(alpha: 0.8),
                          const Color(0xFFF8FAFC).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. High Resolution Center Transparent Trophy Image
                Positioned(
                  bottom: 0,
                  left: 20,
                  right: 20,
                 // top: 60,
                  child: Image.asset(
                    'assets/images/Gemini_Generated_Image_jqhmodjqhmodjqhm.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: 150,
                          color: Colors.amber,
                        ),
                      );
                    },
                  ),
                ),

                // 3. Top Notification Card: "School Notice"
                Positioned(
                  top: 30,
                  left: 10,
                  right: 10,
                  child: _buildChatBubble(
                    icon: Icons.campaign,
                    iconColor: primaryRed,
                    title: 'School Notice',
                    body: 'Sports Day on May 5th.\nDetails inside.',
                  ),
                ),

                // 4. Middle Left Overlapping Card: "Ms. Johnson"
                Positioned(
                  top: 145,
                  left: -10,
                  right: 30,
                  child: _buildChatBubble(
                    avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100',
                    title: 'Ms. Divya',
                    body: 'Great progress in\nMath this week!',
                  ),
                ),

                // 5. Floating heart bubble on the bottom-right side
                Positioned(
                  bottom: 160,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: const Icon(Icons.favorite, color: primaryRed, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble({IconData? icon, Color? iconColor, String? avatarUrl, required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 24))
          else if (avatarUrl != null)
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF0D2344), fontSize: 14, fontWeight: FontWeight.bold)),
                Text(body, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ==========================================
// CHART CUSTOM PAINTER DESIGN
// ==========================================
class TrendLinePainter extends CustomPainter {
  final Color lineColor;
  final Color lastDotColor;
  TrendLinePainter({required this.lineColor, required this.lastDotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()..color = const Color(0xFFF1F5F9)..strokeWidth = 1.0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    List<String> yLabels = ['100', '75', '50', '25', '0'];
    double rowStep = (size.height - 20) / 4;
    for (int i = 0; i < 5; i++) {
      double y = rowStep * i;
      canvas.drawLine(Offset(25, y), Offset(size.width, y), paintGrid);
      textPainter.text = TextSpan(text: yLabels[i], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9));
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    List<String> xLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<double> normalizedDataPoints = [0.22, 0.45, 0.50, 0.80, 0.65, 0.82, 0.95];

    double xStart = 35;
    double columnStep = (size.width - 10 - xStart) / (xLabels.length - 1);
    double graphHeightMax = size.height - 20;

    List<Offset> pointCoordinates = [];
    for (int i = 0; i < xLabels.length; i++) {
      double x = xStart + (columnStep * i);
      double y = graphHeightMax - (normalizedDataPoints[i] * graphHeightMax);
      pointCoordinates.add(Offset(x, y));

      textPainter.text = TextSpan(text: xLabels[i], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9));
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), size.height - 12));
    }

    final paintLine = Paint()..color = lineColor..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(pointCoordinates[0].dx, pointCoordinates[0].dy);
    for (int i = 1; i < pointCoordinates.length; i++) {
      path.lineTo(pointCoordinates[i].dx, pointCoordinates[i].dy);
    }
    canvas.drawPath(path, paintLine);

    final paintDot = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < pointCoordinates.length; i++) {
      bool isLast = (i == pointCoordinates.length - 1);
      paintDot.color = isLast ? lastDotColor : lineColor;
      canvas.drawCircle(pointCoordinates[i], isLast ? 4.5 : 3.5, paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}