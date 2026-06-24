import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart'; // Ensure this import path matches your project structure

class DailyGradesLoginScreen extends StatefulWidget {
  const DailyGradesLoginScreen({super.key});

  @override
  State<DailyGradesLoginScreen> createState() => _DailyGradesLoginScreenState();
}

class _DailyGradesLoginScreenState extends State<DailyGradesLoginScreen> {
  late final AuthController controller; // Dependency injected controller
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Form validation key
  final _isPasswordVisible = false.obs; // GetX observable for password visibility

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>(); // Find the AuthController instance
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _isPasswordVisible.close();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      controller.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey, // Enclosing inside a Form widget
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                _buildHeaderLogo(),
                const SizedBox(height: 32),
                _buildHeroIllustration(),
                const SizedBox(height: 24),
                _buildFormFieldsSection(),
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 20),
                _buildFooterLinks(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER LOGO & SUBTITLE ---
  Widget _buildHeaderLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.school_rounded, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Grades',
              style: TextStyle(
                color: Color(0xFF0F2042),
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Track. Learn. Succeed.',
              style: TextStyle(
                color: Color(0xFF758A9F),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
      ],
    );
  }

  // --- 2. HERO ILLUSTRATION STACK WITH FLOATING BADGES ---
  Widget _buildHeroIllustration() {
    return Column(
      children: [
        const Text(
          'Log in and achieve more.',
          style: TextStyle(
            color: Color(0xFF0F2042),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 24),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2042).withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Center(

                child:  Image.asset(
                  'assets/images/login_image.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.laptop_chromebook_outlined,
                      size: 180,
                      color: const Color(0xFFD32F2F),
                    );
                  },
                ),
              ),
            ),

          ],
        ),
        const SizedBox(height: 36),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Access school updates, track grades, communicate.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF50667F),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }


  // --- 3. FORM FIELDS SECTION ---
  Widget _buildFormFieldsSection() {
    return Column(
      children: [
        // Username/Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => (v == null || v.isEmpty) ? 'Enter email or phone' : null,
          decoration: InputDecoration(
            hintText: 'Username/Email',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Field
        Obx(() => TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible.value,
          validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B)),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF64748B),
              ),
              onPressed: () => _isPasswordVisible.value = !_isPasswordVisible.value,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.8),
            ),
          ),
        )),
      ],
    );
  }

  // --- 4. LOGIN BUTTON WITH REACTIVE LOADING STATE ---
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Obx(() => ElevatedButton(
        onPressed: controller.isLoading.value ? null : _handleLogin, // Disable if loading
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: controller.isLoading.value
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Log In',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      )),
    );
  }

  // --- 5. FOOTER LINK BUTTONS ---
  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF50667F)),
          child: const Text(
            'Forgot Password?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF50667F)),
          child: const Text(
            'Create Account?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}