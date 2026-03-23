import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ConcessionDetailView extends StatelessWidget {
  final Map<String, dynamic> concessionData;

  const ConcessionDetailView({Key? key, required this.concessionData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final student = concessionData['studentId'] ?? {};
    final concession = concessionData['concession'] ?? {};
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Concession Details'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isTablet ? 800 : double.infinity),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.orange[50]!],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 32.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isTablet, student, concession),
                      const SizedBox(height: 24),
                      _buildStudentInfo(isTablet, student),
                      const SizedBox(height: 24),
                      _buildConcessionDetails(isTablet, concession),
                      if (concession['proof'] != null) ...[
                        const SizedBox(height: 24),
                        _buildProofSection(isTablet, concession['proof']),
                      ],
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

  Widget _buildHeader(bool isTablet, Map<String, dynamic> student, Map<String, dynamic> concession) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[600],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.discount, color: Colors.white, size: isTablet ? 32 : 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Concession Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Student: ${student['studentName'] ?? 'Unknown'}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                Text(
                  'Class: ${concessionData['className']} - ${concessionData['sectionName']}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: concession['approvedBy'] != null ? Colors.green : Colors.orange[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              concession['approvedBy'] != null ? 'APPROVED' : 'PENDING',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(bool isTablet, Map<String, dynamic> student) {
    return _buildSection(
      'Student Information',
      Icons.person,
      isTablet,
      [
        _buildInfoRow('Student Name', student['studentName'] ?? 'N/A', isTablet),
        _buildInfoRow('SR ID', student['srId'] ?? 'N/A', isTablet),
        _buildInfoRow('Academic Year', concessionData['academicYear'] ?? 'N/A', isTablet),
        _buildInfoRow('Roll Number', concessionData['rollNumber']?.toString() ?? 'N/A', isTablet),
        _buildInfoRow('Student Type', concessionData['newOld'] ?? 'N/A', isTablet),
        _buildInfoRow('Bus Applicable', concessionData['isBusApplicable'] == true ? 'Yes' : 'No', isTablet),
      ],
    );
  }

  Widget _buildConcessionDetails(bool isTablet, Map<String, dynamic> concession) {
    return _buildSection(
      'Concession Details',
      Icons.discount,
      isTablet,
      [
        _buildInfoRow('Type', concession['type']?.toString().toUpperCase() ?? 'N/A', isTablet),
        _buildInfoRow('Value', '${concession['value'] ?? 0}${concession['type'] == 'percentage' ? '%' : ''}', isTablet),
        _buildInfoRow('Amount', '₹${concession['inAmount'] ?? 0}', isTablet, valueColor: Colors.green[700]),
        _buildInfoRow('Applied Date', _formatDate(concessionData['createdAt']), isTablet),
        _buildInfoRow('Last Updated', _formatDate(concessionData['updatedAt']), isTablet),
        _buildInfoRow('Status', concession['approvedBy'] != null ? 'Approved' : 'Pending Approval', isTablet,
            valueColor: concession['approvedBy'] != null ? Colors.green : Colors.orange),
        if (concession['approvedBy'] != null)
          _buildInfoRow('Approved By', concession['approvedBy'] ?? 'N/A', isTablet),
        if (concession['remark'] != null)
          _buildInfoRow('Remarks', concession['remark'], isTablet),
      ],
    );
  }

  Widget _buildProofSection(bool isTablet, Map<String, dynamic> proof) {

    final fileType = proof['type']?.toString().toLowerCase() ?? '';
    final url = proof['url']?.toString();
    final originalName = proof['originalName'] ?? 'N/A';

    return _buildSection(
      'Proof Document',
      Icons.attachment,
      isTablet,
      [
        _buildInfoRow('File Name', originalName, isTablet),
        _buildInfoRow('File Type', proof['type'] ?? 'N/A', isTablet),
        _buildInfoRow('Upload Date', _formatDate(proof['uploadedAt']), isTablet),
        const SizedBox(height: 16),
        // Show different UI based on file type
        if (fileType.contains('image'))
          _buildImagePreview(url, originalName, isTablet)
        else if (fileType.contains('pdf'))
          _buildPdfPreview(url, originalName, isTablet)
        else
          _buildGenericDocumentPreview(url, originalName, isTablet),
      ],
    );
  }

  Widget _buildImagePreview(String? url, String originalName, bool isTablet) {
    if (url == null || url.isEmpty) {
      return _buildGenericDocumentPreview(url, originalName, isTablet);
    }

    return Column(
      children: [
        Container(
          height: isTablet ? 200 : 150,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () => _showFullScreenImage(url, originalName),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap image to view fullscreen',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _launchUrl(url),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in Browser'),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfPreview(String? url, String originalName, bool isTablet) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, size: 40, color: Colors.red[600]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      originalName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF Document',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(url),
                icon: const Icon(Icons.visibility),
                label: const Text('View PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _launchUrl(url),
                icon: const Icon(Icons.download),
                label: const Text('Download'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenericDocumentPreview(String? url, String originalName, bool isTablet) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.insert_drive_file, size: 40, color: Colors.blue[600]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      originalName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Document',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _launchUrl(url),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _launchUrl(String? url) async {

    if (url == null || url.isEmpty) {
      
      Get.snackbar('Error', 'Document URL not available');
      return;
    }

    try {
      
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
      } else {
        
        Get.snackbar('Error', 'Cannot open this document type');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to open document: ${e.toString()}');
    }
  }

  void _showFullScreenImage(String url, String originalName) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            originalName,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(
              url,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 64, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      transition: Transition.fade,
    );
  }

  Widget _buildSection(String title, IconData icon, bool isTablet, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.orange[600], size: isTablet ? 24 : 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isTablet, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: valueColor ?? Colors.grey[800],
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}