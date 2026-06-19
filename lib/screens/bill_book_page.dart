import 'package:flutter/material.dart';

class AdmissionBillBookView extends StatefulWidget {
  const AdmissionBillBookView({super.key});

  @override
  State<AdmissionBillBookView> createState() => _AdmissionBillBookViewState();
}

class _AdmissionBillBookViewState extends State<AdmissionBillBookView> {
  // Mock tracking variable requested by your boss to dynamically increments/links
  int _currentFormNumber = 101;

  // Form Field Controllers
  final _studentNameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _dobController = TextEditingController();
  final _parentsNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _studentIdController = TextEditingController();

  @override
  void dispose() {
    _studentNameController.dispose();
    _gradeController.dispose();
    _dobController.dispose();
    _parentsNameController.dispose();
    _addressController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  // Format form integer dynamically as a padded string (e.g., 000101)
  String get _formattedFormNumber => _currentFormNumber.toString().padLeft(6, '0');

  void _generateNextForm() {
    setState(() {
      _currentFormNumber++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Form Generated! Linked to Form No. $_formattedFormNumber')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCC2A8), // Warm realistic desk-wood background tint
      appBar: AppBar(
        title: const Text('Admission Book Registrar'),
        backgroundColor: const Color(0xFF0F2042),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () {}, // Printer integration stub
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 850),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                // Inner Book Layout Padding Frame
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBookHeader(),
                      const SizedBox(height: 20),
                      _buildAdmissionFormSection(),
                      const SizedBox(height: 20),
                      _buildStudentIDLinkingSection(),
                      const SizedBox(height: 24),

                      // Perforated Tear Line Separator Mock
                      Row(
                        children: List.generate(40, (index) => Expanded(
                          child: Container(
                            color: index % 2 == 0 ? Colors.transparent : Colors.grey.withOpacity(0.6),
                            height: 1.5,
                          ),
                        )),
                      ),

                      const SizedBox(height: 20),
                      _buildFeeReceiptSection(),
                    ],
                  ),
                ),
                _buildActionFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER SECTION (School Crest & Incremented Form Label) ---
  Widget _buildBookHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildFormNumberBadge(),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0F2042), width: 2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_rounded, size: 30, color: Color(0xFF0F2042)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ABC INTERNATIONAL SCHOOL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F2042), letterSpacing: 0.5),
                  ),
                  Text(
                    'A21 Basic Road, New Delhi, India | Contact: +91 9876543210',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'STUDENT ADMISSION BOOK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                  ),
                ],
              ),
            ),
            // Floating Top-Right Highlighted Form Serial Number
            //_buildFormNumberBadge(),
          ],
        ),
      ],
    );
  }

  Widget _buildFormNumberBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E3A8A), width: 1.5),
      ),
      child: Column(
        children: [
          const Text('Form No.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          Text(
            _formattedFormNumber,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  // --- 2. APPLICATION FOR ADMISSION FORM COMPONENT ---
  Widget _buildAdmissionFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionBanner('APPLICATION FOR ADMISSION'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 3, child: _buildUnderlinedField(_studentNameController, 'Student Name')),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: _buildUnderlinedField(_gradeController, 'Grade/Class')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildUnderlinedField(_dobController, 'Date of Birth (DD/MM/YYYY)')),
            const SizedBox(width: 16),
            Expanded(child: _buildUnderlinedField(_parentsNameController, 'Parents / Guardian Name')),
          ],
        ),
        const SizedBox(height: 12),
        _buildUnderlinedField(_addressController, 'Permanent Address'),
      ],
    );
  }

  // --- 3. STUDENT ID COUPLING BAR (The business logic linking segment) ---
  Widget _buildStudentIDLinkingSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Color(0xFF1E3A8A)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'LINKED TO STUDENT ID\nUse assigned Form No. to auto-generate system profiles.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
            ),
          ),
          SizedBox(
            width: 180,
            height: 40,
            child: TextField(
              controller: _studentIdController,
              decoration: InputDecoration(
                hintText: 'Generated Student ID',
                hintStyle: const TextStyle(fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. FEE PAYMENT RECEIPT COMPONENT ---
  Widget _buildFeeReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionBanner('FEE PAYMENT RECEIPT'),
        const SizedBox(height: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Form Association Ref: #$_formattedFormNumber', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            Text('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 12),

        // Fee Breakdown Matrix Table
        Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(2),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                Padding(padding: EdgeInsets.all(8.0), child: Text('Particulars', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            _buildTableRow('Admission Registration Fee', '2,500.00'),
            _buildTableRow('Term 1 Tuition Base dues', '12,000.00'),
            _buildTableRow('School Uniform & Apparel Set', '3,500.00'),
            _buildTableRow('Textbooks & Stationary Kit Pack', '1,800.00'),
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // Fixed: Changed 'Alignment' to 'Align' and added missing closing parenthesis
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: const Text('TOTAL PAYABLE:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('₹ 19,800.00', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Payment Method: Cash / Online Bank Check', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        // Column(
        //   children: [
        //     SizedBox(width: 140, child: Divider(color: Colors.black87, thickness: 1)),
        //     Text('Authorized Desk Signatory', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        //   ],

      ],
    );
  }

  // --- REUSABLE UTILITY ELEMENT BUILDERS ---
  Widget _buildSectionBanner(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      color: const Color(0xFF0F2042),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildUnderlinedField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38, width: 1)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E3A8A), width: 1.8)),
        contentPadding: const EdgeInsets.only(top: 14, bottom: 4),
      ),
    );
  }

  TableRow _buildTableRow(String particular, String amount) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text(particular, style: const TextStyle(fontSize: 13))),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(amount, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: _generateNextForm,
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('Save Form & Issue Next Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        ],
      ),
    );
  }
}