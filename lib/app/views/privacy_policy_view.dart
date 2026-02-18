import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/responsive_wrapper.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
                      // Header with last updated info
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Last updated: January 2025',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSection('1. Introduction', _introductionText, isTablet),
                      _buildSection('2. Information We Collect', _informationCollectedText, isTablet),
                      _buildSection('3. How We Use Your Information', _howWeUseText, isTablet),
                      _buildSection('4. Data Privacy for Minors (Children)', _childPrivacyText, isTablet),
                      _buildSection('5. Data Sharing and Disclosure', _dataSharingText, isTablet),
                      _buildSection('6. Data Security', _dataSecurityText, isTablet),
                      _buildSection('7. Data Retention and Deletion', _dataRetentionText, isTablet),
                      _buildSection('8. Your Rights', _yourRightsText, isTablet),
                      _buildSection('9. Changes to This Policy', _policyChangesText, isTablet),
                      _buildSection('10. Contact Us', _contactText, isTablet),
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
          gradient: AppTheme.primaryGradient,
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
                    Icons.privacy_tip_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Privacy Policy',
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

  Widget _buildSection(String title, String content, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              color: AppTheme.primaryText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  static const String _introductionText = '''
Welcome to BMB School App ("we," "our," or "us"). We provide a school management platform that allows educational institutions to manage student data, teacher records, academic years, and school-wide communications.

This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our application.
''';

  static const String _informationCollectedText = '''
We collect the following information to provide our services:

• School/Admin Data: Institution name, administrator contact details, and login credentials.
• Teacher & Staff Data: Names, email addresses, employee IDs, and class assignments.
• Student Data: Names, enrollment numbers, academic records, grades, and attendance.
• User Content: Announcements, messages, and uploaded files.
• Device Information: IP address, device identifiers, and operating system details.
''';

  static const String _howWeUseText = '''
Your data is used strictly for educational and administrative purposes:

• Managing student, teacher, and staff accounts.
• Maintaining academic and institutional records.
• Sending notifications and announcements.
• Ensuring system security and technical support.
''';

  static const String _childPrivacyText = '''
We are committed to protecting children's privacy:

• Student data is never used for marketing or advertising.
• Schools are responsible for obtaining parental consent.
• Parents or guardians may request access or deletion through school administration.
''';

  static const String _dataSharingText = '''
We do not sell personal data. Information may be shared only with:

• Authorized school users.
• Trusted service providers bound by confidentiality agreements.
• Legal authorities if required by law.
''';

  static const String _dataSecurityText = '''
We use industry-standard security practices, including encryption and strict tenant isolation, to protect all data.
''';

  static const String _dataRetentionText = '''
Data is retained while the school account remains active.

• Deletion requests can be made through school administration or support.
• Data is securely deleted or anonymized within 90 days after termination.
''';

  static const String _yourRightsText = '''
Depending on your jurisdiction, you may have rights to access, correct, or delete your personal data through your school administrator.
''';

  static const String _policyChangesText = '''
We may update this Privacy Policy periodically. Updates will be reflected in the app with a revised "Last Updated" date.
''';

  static const String _contactText = '''
If you have questions about this Privacy Policy, contact us at:

BMB School App  
Email: ramstechcircle@gmail.com
''';
}