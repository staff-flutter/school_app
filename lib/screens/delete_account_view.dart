import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';

class DeleteAccountView extends StatelessWidget {
  const DeleteAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            _buildModernAppBar(context, isTablet),
            SliverToBoxAdapter(
              child: ResponsiveWrapper(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isTablet),
                      const SizedBox(height: 24),
                      _buildImportantNotice(isTablet),
                      const SizedBox(height: 20),
                      _buildWhoToContact(isTablet),
                      const SizedBox(height: 20),
                      _buildDeletionProcess(isTablet),
                      const SizedBox(height: 20),
                      _buildFinalNote(isTablet),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, bool isTablet) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: isTablet ? 130 : 110,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.mathGradient,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(56, 18, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: AppTheme.warningGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warningYellow.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Deletion Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Permanent action - cannot be undone',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Deleting your account is a permanent action and cannot be undone. Once deleted, all associated data will be permanently removed in accordance with educational data regulations.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isTablet ? 15 : 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantNotice(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: AppTheme.TealGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.TealColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Important Notice',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'To comply with school and educational data policies, account deletion requests cannot be processed directly inside the app.\n\nAll requests must be initiated through your school administration or the official support team.',
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhoToContact(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.contact_support, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Who to Contact',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactOption(
            icon: Icons.school,
            title: 'School Correspondent',
            subtitle: 'Your school correspondent is the primary authority responsible for managing user accounts and initiating profile removal requests.',
            isTablet: isTablet,
          ),
          const SizedBox(height: 12),
          _buildContactOption(
            icon: Icons.support_agent,
            title: 'Support Team',
            subtitle: 'If you are unable to contact your school correspondent, you may reach out to our support team for manual account deletion.',
            isTablet: isTablet,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.email, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Support Email:',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ramstechcircle@gmail.com',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: Colors.white,

                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isTablet,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App info header
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.mathGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.apps, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'BMB School App',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletionProcess(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.list_alt, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Account Deletion Process',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStep(1, 'Contact your school correspondent or the support team using the details provided above.', isTablet),
          _buildStep(2, 'Share your registered account details and clearly mention the reason for requesting account deletion.', isTablet),
          _buildStep(3, 'Your request will be verified and processed after validation.', isTablet),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: AppTheme.successGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Processing Time:',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successGreen,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Account deletion is typically completed within 7 business days after successful verification.',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isTablet ? 15 : 14,
                color: AppTheme.primaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalNote(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: AppTheme.physicsGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.security, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Final Note',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'For security and compliance reasons, only verified requests will be accepted. If you have any questions regarding this process, please contact the support team.',
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'ramstechcircle@gmail.com',
      query: 'subject=Account Deletion Request - BMB School&body=Hello,\n\nI would like to request the deletion of my account from BMB School App.\n\nAccount Details:\nName: \nEmail: \nSchool: \nReason for deletion: \n\nThank you.',
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        Get.snackbar(
          'Error',
          'Could not open email client',
          backgroundColor: AppTheme.errorRed,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open email client',
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
      );
    }
  }
}