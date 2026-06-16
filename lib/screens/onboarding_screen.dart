import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../core/theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../widgets/primary_button.dart';
import 'accounting_dashboard_with_api_integration.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  int page = 0;

  final items = const [
    (
    'Welcome to Daily Grades',
    'Your smart companion to track grades, improve performance, and achieve your goals.',
    Icons.waving_hand_rounded,
    ),
    (
    'Track your progress in one place',
    'View subjects, assignments, attendance, and updates in a clean dashboard.',
    Icons.analytics_rounded,
    ),
    (
    'View results and grow',
    'Analyze performance, identify strengths, and focus on areas that need improvement.',
    Icons.trending_up_rounded,
    ),
    (
    'Stay connected and achieve more',
    'Get announcements, submit assignments, and earn badges as you reach new milestones.',
    Icons.emoji_events_rounded,
    ),
  ];

  void finish() {
    Get.offNamed(AppRoutes.ACCOUNTING_DASHBOARD);
  }

  @override
  Widget build(BuildContext context) {
    final last = page == items.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: finish,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: items.length,
                onPageChanged: (value) => setState(() => page = value),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 14),
                        Text(item.$2, style: Theme.of(context).textTheme.bodyLarge),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          height: 330,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: .08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(item.$3, size: 92, color: AppColors.red),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: index == page ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == page ? AppColors.red : AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: last ? 'Get Started' : 'Next',
                onPressed: () {
                  if (last) {
                    finish();
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
