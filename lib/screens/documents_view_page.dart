import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/constants/api_constants.dart';

class DocumentsViewPage extends StatefulWidget {
  final String studentId;
  const DocumentsViewPage({super.key, required this.studentId});

  @override
  State<DocumentsViewPage> createState() => _DocumentsViewPageState();
}

class _DocumentsViewPageState extends State<DocumentsViewPage> {
  bool _isLoading = true;
  String? _profileImageUrl;
  List<Map<String, dynamic>> _documents = [];

  String? _getToken() {
    try {
      return Get.find<AuthController>().storage.read('token');
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final token = _getToken();
    if (token == null || widget.studentId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/student/get/${widget.studentId}');
    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final decoded = jsonDecode(response.body);
      final Map<String, dynamic> doc = decoded is Map<String, dynamic>
          ? (decoded['data'] ?? decoded['student'] ?? decoded)
          : {};

      final rawDocs = (doc['documents'] as List?) ?? [];
      final parsedDocs = rawDocs.whereType<Map>().map((d) => Map<String, dynamic>.from(d)).toList();

      final studentImageMap = doc['studentImage'] as Map<String, dynamic>?;
      final imageUrl = studentImageMap?['url']?.toString();

      if (mounted) {
        setState(() {
          _documents = parsedDocs;
          _profileImageUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _profileImageUrl != null && _profileImageUrl!.isNotEmpty;
    final hasDocs = _documents.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: const Color(0xff4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (!hasImage && !hasDocs)
          ? _emptyState()
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (hasImage) ...[
              const Text('Student Photo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    _profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ],
            if (hasDocs) ...[
              const Text('Uploaded Documents',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ..._documents.map((doc) {
                final name = doc['originalName']?.toString() ??
                    doc['name']?.toString() ??
                    'Document';
                final url = doc['url']?.toString() ?? '';
                final type = doc['type']?.toString() ?? '';
                final isImage = type == 'image';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                      color: const Color(0xff4A90E2),
                    ),
                    title: Text(name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.open_in_new_rounded,
                        size: 18, color: Colors.grey),
                    onTap: url.isEmpty ? null : () => _openDocument(url),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Icons.folder_off_outlined, size: 36, color: Colors.blue.shade400),
            ),
            const SizedBox(height: 14),
            const Text('No Documents', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('No photo or documents have been uploaded yet.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}