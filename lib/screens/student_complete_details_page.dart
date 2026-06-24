import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─── Design System Bridge ───────────────────────────────────────────────────
// Built to match your existing '_DS' color scheme and variables perfectly.
class _DS {
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF0284C7);
  static const primarySoft = Color(0xFFE0F2FE);
  static const bg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const border = Color(0xFFE2E8F0);

  static const radius = 16.0;
  static const radiusSm = 10.0;
  static const radiusLg = 24.0;

  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 24.0;
}

class _Responsive {
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 900;
  static double padding(BuildContext context) => isTablet(context) ? _DS.spacingXl : _DS.spacingLg;
}

// ─── MAIN STUDENT PROFILE VIEW ──────────────────────────────────────────────
class StudentDetailView extends StatefulWidget {
  const StudentDetailView({Key? key}) : super(key: key);

  @override
  State<StudentDetailView> createState() => _StudentDetailViewState();
}

class _StudentDetailViewState extends State<StudentDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 5 Tabs: Bio, Fees, Admission Form, Documents, and an extra Academic summary tab
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = _Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: _DS.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Dynamic Profile Top Summary Header ────────────────────────
            _buildProfileHeroHeader(context, isTablet),

            // ─── Scrollable Custom Pill Tab Bar ────────────────────────────
            Container(
              width: double.infinity,
              color: _DS.surface,
              padding: EdgeInsets.symmetric(vertical: _DS.spacingSm, horizontal: _Responsive.padding(context)),
              child: Align(
                alignment: Alignment.centerLeft, // Left-aligns scrollable tabs cleanly
                child: _buildTabBar(context),
              ),
            ),
            const Divider(height: 1, color: _DS.border),

            // ─── Tab Content Views ─────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBioTab(context),
                  _buildFeeDetailsTab(context),
                  _buildAdmissionFormTab(context),
                  _buildDocumentsTab(context),
                  _buildAcademicsTab(context), // Extra useful panel!
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HERO HEADER COMPONENT ────────────────────────────────────────────────
  Widget _buildProfileHeroHeader(BuildContext context, bool isTablet) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_DS.primary, _DS.primaryDark],
        ),
      ),
      padding: EdgeInsets.all(_Responsive.padding(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elegant Avatar Frame
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 36,
              backgroundColor: _DS.surface,
              child: Text('SA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _DS.primary)),
            ),
          ),
          const SizedBox(width: 16),
          // Quick Student Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Sai Arjun',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: _DS.successSoft, borderRadius: BorderRadius.circular(100)),
                      child: const Text('Active', style: TextStyle(color: _DS.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Roll No: #24012  |  Admission No: ADM-2026-894', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                const SizedBox(height: 6),
                // Badges matching your layout styles
                Row(
                  children: [
                    _headerBadge(Icons.class_rounded, 'Class 10'),
                    const SizedBox(width: 6),
                    _headerBadge(Icons.room_rounded, 'Section A'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(_DS.radiusSm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── SCROLLABLE PILL TABBAR ───────────────────────────────────────────────
  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      tabAlignment: TabAlignment.start,
      indicator: BoxDecoration(
        color: _DS.primarySoft,
        borderRadius: BorderRadius.circular(100),
      ),
      labelColor: _DS.primary,
      unselectedLabelColor: _DS.textSecondary,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      tabs: const [
        Tab(text: 'Bio Profile'),
        Tab(text: 'Fee Details'),
        Tab(text: 'Admission Form'),
        Tab(text: 'Documents'),
        Tab(text: 'Academics'),
      ],
    );
  }

  // ─── TAB 1: BIO PROFILE ───────────────────────────────────────────────────
  Widget _buildBioTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_Responsive.padding(context)),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Personal Details',
            icon: Icons.person_outline_rounded,
            items: {
              'Full Name': 'Sai Arjun',
              'Date of Birth': '14 Aug 2011 (Age 14)',
              'Gender': 'Male',
              'Blood Group': 'O+ Positive',
              'Nationality': 'Indian',
              'Mother Tongue': 'Telugu',
            },
          ),
          _buildInfoCard(
            title: 'Parent & Guardian Details',
            icon: Icons.family_restroom_rounded,
            items: {
              'Father\'s Name': 'Srinivasa Rao',
              'Father\'s Phone': '+91 98765 43210',
              'Mother\'s Name': 'Lakshmi Devi',
              'Emergency Contact': '+91 98765 43211',
              'Guardian Email': 'parent.srinivas@gmail.com',
            },
          ),
          _buildInfoCard(
            title: 'Contact Address',
            icon: Icons.home_outlined,
            items: {
              'Residential Address': 'Flat 402, Sri Sai Residency, Madhapur, Hyderabad, Telangana, 500081',
            },
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: FEE DETAILS ───────────────────────────────────────────────────
  Widget _buildFeeDetailsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_Responsive.padding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Summary row
          Row(
            children: [
              Expanded(child: _buildMetricTile('Total Term Fees', '₹45,000', _DS.primarySoft, _DS.primary)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('Paid Amount', '₹30,000', _DS.successSoft, _DS.success)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('Outstanding Balance', '₹15,000', const Color(0xFFFFE2E2), _DS.danger)),
            ],
          ),
          const SizedBox(height: 16),

          // Fee Structure Breakdowns
          Text('FEES TIMELINE & INVOICES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _DS.textMuted, letterSpacing: 1.0)),
          const SizedBox(height: 8),

          _buildFeeInvoiceRow('Term 1 Academic Fees', '₹15,000', 'Paid', _DS.success, _DS.successSoft),
          _buildFeeInvoiceRow('Term 2 Academic Fees', '₹15,000', 'Paid', _DS.success, _DS.successSoft),
          _buildFeeInvoiceRow('Term 3 Exam & Lab Fees', '₹15,000', 'Pending Due (Overdue 5 days)', _DS.danger, const Color(0xFFFFE2E2)),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_DS.radiusSm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, color: fg, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildFeeInvoiceRow(String title, String amount, String status, Color statusColor, Color statusBg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _DS.surface, border: Border.all(color: _DS.border), borderRadius: BorderRadius.circular(_DS.radiusSm)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _DS.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                  child: Text(status, style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _DS.textPrimary)),
        ],
      ),
    );
  }

  // ─── TAB 3: ADMISSION FORM DETAILS ────────────────────────────────────────
  Widget _buildAdmissionFormTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_Responsive.padding(context)),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Enrollment Parameters',
            icon: Icons.assignment_turned_in_outlined,
            items: {
              'Admission Status': 'Approved & Secured',
              'Date of Joining': '02 June 2024',
              'Academic Session Batch': '2024 - 2027 Cycle',
              'Board Registration No': 'CBSE-REG-981242',
              'Admitted Under Quota': 'General Merit (Non-RTE)',
            },
          ),
          _buildInfoCard(
            title: 'Previous Institution Records',
            icon: Icons.history_edu_rounded,
            items: {
              'Last School Attended': 'St. Mary\'s High Secondary School',
              'Previous Qualified Class': 'Class 9 Certificate',
              'Transfer Certificate (TC) No': 'TC-89124-2024',
              'Cumulative Grade Value (CGPA)': '8.8 CGPA Score',
              'Conduct Certificate Marks': 'Exemplary / Good Conduct',
            },
          ),
        ],
      ),
    );
  }

  // ─── TAB 4: UPLOADED DOCUMENTS PANELS ─────────────────────────────────────
  Widget _buildDocumentsTab(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(_Responsive.padding(context)),
      children: [
        Text('VERIFIED ATTACHMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _DS.textMuted, letterSpacing: 1.0)),
        const SizedBox(height: 10),
        _buildDocRow('Student_Birth_Certificate.pdf', 'Size: 1.2 MB  |  Uploaded: Jun 2024', Icons.picture_as_pdf_rounded, Colors.red),
        _buildDocRow('Aadhar_Card_Verification.jpg', 'Size: 450 KB  |  Uploaded: Jun 2024', Icons.image_rounded, Colors.blue),
        _buildDocRow('Previous_Transfer_Certificate.pdf', 'Size: 2.1 MB  |  Uploaded: Jul 2024', Icons.picture_as_pdf_rounded, Colors.red),
        _buildDocRow('Passport_Size_Photo.png', 'Size: 180 KB  |  Uploaded: Jun 2024', Icons.insert_photo_rounded, Colors.teal),
      ],
    );
  }

  Widget _buildDocRow(String fileName, String meta, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: _DS.surface, border: Border.all(color: _DS.border), borderRadius: BorderRadius.circular(_DS.radiusSm)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _DS.textPrimary), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(meta, style: const TextStyle(fontSize: 10, color: _DS.textMuted)),
              ],
            ),
          ),
          // View/Action trigger
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: _DS.primary, size: 20),
            onPressed: () {
              Get.snackbar('Document View', 'Opening $fileName preview window...', backgroundColor: _DS.primarySoft, colorText: _DS.primary);
            },
          ),
        ],
      ),
    );
  }

  // ─── TAB 5: ACADEMIC HISTORY SUMMARY (ADDITIONAL VALUE) ───────────────────
  Widget _buildAcademicsTab(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(_Responsive.padding(context)),
      children: [
        Text('QUICK MARKS PERFORMANCE INDEX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _DS.textMuted, letterSpacing: 1.0)),
        const SizedBox(height: 10),
        _buildAcademicCardItem('Mathematics Terminal Assessment', '94 / 100', 'Grade A+', _DS.success),
        _buildAcademicCardItem('General Science Assessment', '88 / 100', 'Grade A', _DS.success),
        _buildAcademicCardItem('Social Science Evaluation', '76 / 100', 'Grade B', _DS.warning),
        _buildAcademicCardItem('English Literature & Grammar', '91 / 100', 'Grade A+', _DS.success),
      ],
    );
  }

  Widget _buildAcademicCardItem(String subject, String marks, String grade, Color gradeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _DS.surface, border: Border.all(color: _DS.border), borderRadius: BorderRadius.circular(_DS.radiusSm)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _DS.textPrimary)),
                const SizedBox(height: 3),
                Text('Marks Earned: $marks', style: const TextStyle(fontSize: 11, color: _DS.textSecondary)),
              ],
            ),
          ),
          Text(grade, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: gradeColor)),
        ],
      ),
    );
  }

  // ─── HELPER REUSABLE PROFILE CONTAINER ───────────────────────────────────
  Widget _buildInfoCard({required String title, required IconData icon, required Map<String, String> items}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(color: _DS.surface, border: Border.all(color: _DS.border), borderRadius: BorderRadius.circular(_DS.radius), boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subcard Heading section
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: _DS.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _DS.textPrimary, letterSpacing: -0.1)),
              ],
            ),
          ),
          const Divider(height: 1, color: _DS.border),
          // Property list mapping loop
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: items.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(entry.key, style: const TextStyle(fontSize: 12, color: _DS.textSecondary, fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: Text(entry.value, style: const TextStyle(fontSize: 12, color: _DS.textPrimary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}