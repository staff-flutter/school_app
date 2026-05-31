import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final AuthController controller;
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _isPasswordVisible = false.obs;
  final _currentPage = 0.obs;
  late final PageController _pageController;
  Timer? _autoSlideTimer;

  static const _white = Colors.white;
  static const _accentBlue = Color(0xFF1D4ED8);
  static const _lightBlue = Color(0xFFEFF6FF);
  static const _medBlue = Color(0xFFBFDBFE);
  static const _softBlue = Color(0xFF93C5FD);

  final List<_SlideData> _slides = const [
    _SlideData(
      icon: Icons.school_rounded,
      title: 'All-in-One School Hub',
      subtitle: 'Everything in one place',
      description:
          'Manage attendance, grades, timetables, and communication — all from one powerful platform built for modern schools.',
      bgColor: Color(0xFFEFF6FF),
      accentColor: Color(0xFF1D4ED8),
    ),
    _SlideData(
      icon: Icons.people_alt_rounded,
      title: 'Connect Everyone',
      subtitle: 'Teachers · Students · Parents',
      description:
          'Stay in sync with real-time updates, announcements, and instant messaging across every role in your school.',
      bgColor: Color(0xFFE0F2FE),
      accentColor: Color(0xFF0369A1),
    ),
    _SlideData(
      icon: Icons.bar_chart_rounded,
      title: 'Smart Insights',
      subtitle: 'Data-driven decisions',
      description:
          'Track academic progress with detailed analytics, performance reports, and AI-powered recommendations for every student.',
      bgColor: Color(0xFFDBEAFE),
      accentColor: Color(0xFF2563EB),
    ),
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
    _pageController = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _isPasswordVisible.close();
    _currentPage.close();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentPage.value + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      // This allows the scaffold to resize automatically when the keyboard appears
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              final maxWidth = isTablet ? 460.0 : double.infinity;

              return Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  // Wrap in SingleChildScrollView to handle small screens/keyboards
                  child: SingleChildScrollView(
                    // physics ensures a smooth bounce effect
                    physics: const BouncingScrollPhysics(),
                    child: Column(

                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopBar(isTablet),

                        const SizedBox(height: 10),

                        // FIX: Replace Expanded with a sized container
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20), // Increase this from 16 to 20
                          child: SizedBox(
                            height: isTablet ? 480 : 360,
                            child: _buildCarousel(isTablet),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 24 : 16,
                          ),
                          child: Form(
                            key: _formKey,
                            child: _buildSignInCard(isTablet),
                          ),
                        ),

                        _buildPolicyLinks(isTablet),

                        // Adds a little breathing room at the bottom
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 28 : 20,
        vertical: isTablet ? 12 : 8,
      ),
      decoration: const BoxDecoration(
        color: _white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFDBEAFE), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 8 : 6),
            decoration: BoxDecoration(
              color: _accentBlue,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.school_rounded,
              size: isTablet ? 20 : 16,
              color: _white,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'School Management',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: _accentBlue,
                ),
              ),
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: isTablet ? 11 : 10,
                  color: _softBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Carousel ───────────────────────────────────────────────────────────────
  Widget _buildCarousel(bool isTablet) {
    return Container(
      // 1. THIS IS KEY: It forces the children (the slides)
      // to stay inside the rounded corners of the border.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        // 2. Make the border slightly thicker or darker to test visibility
        border: Border.all(color: _medBlue, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: _accentBlue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) => _currentPage.value = i,
              itemBuilder: (_, i) => _buildSlide(_slides[i], isTablet),
            ),
          ),
          _buildDotIndicator(),
        ],
      ),
    );
  }

  Widget _buildSlide(_SlideData slide, bool isTablet) {
    return Container(
      color: slide.bgColor, // This color will now be clipped by the parent's Clip.antiAlias
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 28,
        vertical: isTablet ? 24 : 16,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 22 : 18),
            decoration: BoxDecoration(
              color: _white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: slide.accentColor.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              slide.icon,
              size: isTablet ? 52 : 42,
              color: slide.accentColor,
            ),
          ),
          SizedBox(height: isTablet ? 18 : 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: slide.accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              slide.subtitle,
              style: TextStyle(
                fontSize: isTablet ? 12 : 11,
                color: slide.accentColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 10 : 8),
          Text(
            slide.title,
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: _accentBlue,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 10 : 8),
          Text(
            slide.description,
            style: TextStyle(
              fontSize: isTablet ? 14 : 13,
              color: const Color(0xFF4B5563),
              height: 1.55,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Container(
      color: _white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final active = _currentPage.value == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 7,
                width: active ? 22 : 7,
                decoration: BoxDecoration(
                  color: active ? _accentBlue : _softBlue.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          )),
    );
  }

  // ── Compact sign-in card ───────────────────────────────────────────────────
  Widget _buildSignInCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 28 : 18,
        vertical: isTablet ? 18 : 12,
      ),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _medBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _accentBlue.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fields row on tablet, column on phone
          isTablet
              ? Row(
                  children: [
                    Expanded(child: _identifierField(isTablet)),
                    const SizedBox(width: 12),
                    Expanded(child: _passwordField(isTablet)),
                  ],
                )
              : Column(
                  children: [
                    _identifierField(isTablet),
                    const SizedBox(height: 8),
                    _passwordField(isTablet),
                  ],
                ),
          SizedBox(height: isTablet ? 14 : 10),
          SizedBox(
            width: double.infinity,
            height: isTablet ? 46 : 42,
            child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentBlue,
                    foregroundColor: _white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _identifierField(bool isTablet) {
    return SizedBox(
      height: isTablet ? 50 : 44,
      child: TextFormField(
        controller: _identifierController,
        style: TextStyle(
            fontSize: isTablet ? 13 : 12, color: const Color(0xFF1F2937)),
        decoration: _inputDeco(
          label: 'Email or Phone',
          icon: Icons.person_outline,
          isTablet: isTablet,
        ),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Enter email or phone' : null,
      ),
    );
  }

  Widget _passwordField(bool isTablet) {
    return SizedBox(
      height: isTablet ? 50 : 44,
      child: Obx(() => TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible.value,
            style: TextStyle(
                fontSize: isTablet ? 13 : 12, color: const Color(0xFF1F2937)),
            decoration: _inputDeco(
              label: 'Password',
              icon: Icons.lock_outline,
              isTablet: isTablet,
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  _isPasswordVisible.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: _accentBlue,
                  size: 17,
                ),
                onPressed: () =>
                    _isPasswordVisible.value = !_isPasswordVisible.value,
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter password' : null,
          )),
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required IconData icon,
    required bool isTablet,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: const Color(0xFF6B7280),
        fontSize: isTablet ? 12 : 11,
      ),
      prefixIcon: Icon(icon, color: _accentBlue, size: isTablet ? 18 : 16),
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _medBlue),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _medBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _accentBlue, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
      filled: true,
      fillColor: _lightBlue,
      errorStyle: const TextStyle(fontSize: 9, height: 0.8),
    );
  }

  // ── Policy links ───────────────────────────────────────────────────────────
  Widget _buildPolicyLinks(bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 10 : 6,
        horizontal: isTablet ? 24 : 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _policyBtn('Privacy Policy',
              'https://www.bmbproducts.com/privacy-policy', isTablet),
          Container(
            height: 12,
            width: 1,
            color: _softBlue.withOpacity(0.5),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          _policyBtn('Account Deletion',
              'https://www.bmbproducts.com/account-deletion', isTablet),
        ],
      ),
    );
  }

  Widget _policyBtn(String label, String url, bool isTablet) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Text(
        label,
        style: TextStyle(
          color: _accentBlue,
          fontSize: isTablet ? 12 : 11,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: _accentBlue,
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        'Error',
        'Could not launch $url',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      controller.login(
        _identifierController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }
}

// ── Slide data model ───────────────────────────────────────────────────────
class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color bgColor;
  final Color accentColor;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.bgColor,
    required this.accentColor,
  });
}