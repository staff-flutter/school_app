import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:school_app/core/utils/academic_year_utils.dart';
import '../constants/api_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/my_children_controller.dart';
import '../core/theme/app_theme.dart';
import 'package:school_app/controllers/school_controller.dart';
// If url_launcher isn't already a dependency, add it to pubspec.yaml:
//   url_launcher: ^6.2.0
import 'package:url_launcher/url_launcher.dart';

class AssignmentUI extends StatefulWidget {
  const AssignmentUI({super.key});

  @override
  State<AssignmentUI> createState() => _AssignmentUIState();
}

class _AssignmentUIState extends State<AssignmentUI> {
  final Map<int, Future<List<AssignmentListStrings>>> _assignmentFutures = {};
  final auth_ctrl = Get.find<AuthController>();

  int selectedIndex = 0;
  late final List<Map<String, String>> dates;
  late final PageController _pageController;

  static String _currentAcademicYear() {
    final now = DateTime.now();
    final startYear = now.month >= 6 ? now.year : now.year - 1;
    return '$startYear-${startYear + 1}';
  }

  @override
  void initState() {
    super.initState();
    dates = _buildDates(); // Computed once safely
    selectedIndex = DateTime.now().weekday % 7;

    _pageController = PageController(initialPage: selectedIndex);
    _assignmentFutures[selectedIndex] = fetchAssignments(selectedIndex);
  }

  List<Map<String, String>> _buildDates() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final dayNames     = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
    final fullDayNames = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"];
    return List.generate(7, (i) {
      final day = startOfWeek.add(Duration(days: i));
      return {
        "day":     dayNames[i],
        "date":    day.day.toString(),
        "fullDay": fullDayNames[i],
        "isoDate": "${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}",
      };
    });
  }

  void onDateTap(int index) {
    setState(() {
      selectedIndex = index;
      _assignmentFutures[index] = fetchAssignments(index);
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onRefresh(int index) async {
    setState(() {
      _assignmentFutures[index] = fetchAssignments(index);
    });
    await _assignmentFutures[index];
  }

  Future<String> _resolveAcademicYear() async {
    final schoolController = Get.find<SchoolController>();

    if (schoolController.selectedSchool.value == null) {
      await schoolController.getAllSchools();
    }

    final year = schoolController.selectedSchool.value?.currentAcademicYear;
    if (year != null && year.trim().isNotEmpty) {
      return year;
    }

    final now = DateTime.now();
    final startYear = now.month >= 6 ? now.year : now.year - 1;
    return '$startYear-${startYear + 1}';
  }

  Future<List<AssignmentListStrings>> fetchAssignments(int dayIndex) async {
    String baseUrl = ApiConstants.baseUrl;
    final controller = Get.find<MyChildrenController>();
    final selectedStudent = controller.selectedChild;
    final String? token = auth_ctrl.storage.read('token');

    final String? schoolId = auth_ctrl.user.value?.schoolId;
    final String? classId = controller.selectedChild['classId'] ?? 'null';
    final String? sectionId = selectedStudent['sectionId'] ?? 'null';
    final academicYear = AcademicYearUtils.getCurrentAcademicYear();

    final Map<String, String> queryParameters = {
      if (schoolId != null) "schoolId": '$schoolId',
      "classId": '$classId',
      "sectionId": '$sectionId',
      "academicYear": academicYear,
      "page": "1",
      "limit": "100"
    };

    final uri = Uri.parse('$baseUrl/api/homework/getall').replace(queryParameters: queryParameters);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        final List<AssignmentListStrings> allAssignments = [];
        final homeworkData = decodedData['homework'] ?? decodedData['data'];
        final selectedIsoDate = dates[dayIndex]["isoDate"]!;

        if (homeworkData is List) {
          for (var homeworkDay in homeworkData) {
            String dateStr = homeworkDay['homeworkDate'] ?? "";
            if (!dateStr.startsWith(selectedIsoDate)) continue;

            // The whole-day homework document's own _id — this is what
            // GET /api/homework/getsingle/:homeworkId expects.
            final homeworkId = homeworkDay['_id']?.toString() ?? '';

            List subjects = homeworkDay['subjects'] ?? [];
            for (var subjectJson in subjects) {
              allAssignments.add(AssignmentListStrings.fromJson(
                subjectJson,
                dateStr,
                homeworkId,
              ));
            }
          }
        }
        return allAssignments;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFEEF3FB),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        bottomNavigationBar: SizedBox(
          height: MediaQuery.of(context).viewPadding.bottom,
        ),
        backgroundColor: const Color(0xFFEEF3FB),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, left: 10, right: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_shouldShowBack())
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 15),
                        color: Colors.black,
                        onPressed: () => Get.back(),
                      ),
                    if (_shouldShowBack()) const SizedBox(width: 10),
                    const Text(
                      "Assignments",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => onDateTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 55,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: selectedIndex == index ? Colors.blue : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dates[index]["day"]!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selectedIndex == index ? Colors.white : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                dates[index]["date"]!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selectedIndex == index ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        selectedIndex = index;
                        _assignmentFutures[index] = fetchAssignments(index);
                      });
                    },
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      _assignmentFutures[index] ??= fetchAssignments(index);
                      return RefreshIndicator(
                        color: Colors.blue,
                        onRefresh: () => _onRefresh(index),
                        child: FutureBuilder<List<AssignmentListStrings>>(
                          future: _assignmentFutures[index],
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.assignment_outlined, size: 60, color: Colors.grey.shade300),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No assignments today!',
                                            style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            final assignments = snapshot.data!;
                            return ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(16, 12, 16, AppTheme.navBarPadding(context)),
                              itemCount: assignments.length,
                              itemBuilder: (ctx, i) {
                                final item = assignments[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AssignmentDetailPage(
                                            homeworkId: item.homeworkId,
                                            subjectId: item.subjectId,
                                            fallback: item,
                                          ),
                                        ),
                                      );
                                    },
                                    child: AssignmentContainer(
                                      subject: item.subject,
                                      title: item.description,
                                      pages: "View Attachments (${item.imageUrls.length})",
                                      date: item.date.split('T')[0],
                                      color: Colors.blue,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowBack() {
    try {
      final role = Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
      const sidebarRoles = {'correspondent', 'administrator', 'principal', 'viceprincipal', 'teacher', 'accountant'};
      return !sidebarRoles.contains(role);
    } catch (_) {
      return true;
    }
  }
}

class AssignmentListStrings {
  final String subject;
  final String description;
  final String date;
  final List<String> imageUrls;
  final String homeworkId; // the whole-day homework document's _id
  final String? subjectId; // this specific subject entry's _id, if present

  const AssignmentListStrings({
    required this.subject,
    required this.description,
    required this.date,
    required this.imageUrls,
    required this.homeworkId,
    this.subjectId,
  });

  factory AssignmentListStrings.fromJson(
      Map<String, dynamic> json, String homeworkDate, String homeworkId) {
    return AssignmentListStrings(
      subject: json['subjectName'] ?? "Unknown",
      description: json['description'] ?? "No description provided",
      date: homeworkDate,
      imageUrls: (json['attachments'] as List?)?.map((e) => e['url'] as String).toList() ?? [],
      homeworkId: homeworkId,
      subjectId: json['_id']?.toString(),
    );
  }
}

class AssignmentContainer extends StatelessWidget {
  final String subject;
  final String title;
  final String pages;
  final String date;
  final Color color;

  const AssignmentContainer({
    super.key,
    required this.subject,
    required this.title,
    required this.pages,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subject,
              style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(pages, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(date, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DETAIL PAGE — GET /api/homework/getsingle/:homeworkId
// =============================================================================

class AssignmentDetailPage extends StatefulWidget {
  final String homeworkId;
  final String? subjectId;
  /// Used as an immediate fallback so the page has something to show while
  /// the network call is in flight, and as a last resort if the detail
  /// fetch fails entirely.
  final AssignmentListStrings fallback;

  const AssignmentDetailPage({
    super.key,
    required this.homeworkId,
    required this.fallback,
    this.subjectId,
  });

  @override
  State<AssignmentDetailPage> createState() => _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends State<AssignmentDetailPage> {
  final _auth = Get.find<AuthController>();
  bool _loading = true;
  String? _error;

  // Resolved display fields
  String _subjectName = '';
  String _description = '';
  String _date = '';
  String? _teacherName;
  List<Map<String, dynamic>> _attachments = [];

  @override
  void initState() {
    super.initState();
    // Seed with what we already know so the page isn't blank while loading.
    _subjectName = widget.fallback.subject;
    _description = widget.fallback.description;
    _date = widget.fallback.date;
    _attachments = widget.fallback.imageUrls
        .map((u) => {'url': u, 'originalName': null})
        .toList();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (widget.homeworkId.isEmpty) {
      setState(() {
        _loading = false;
        _error = null; // fall back silently to the seeded values
      });
      return;
    }

    final baseUrl = ApiConstants.baseUrl;
    final token = _auth.storage.read('token');
    final uri = Uri.parse('$baseUrl/api/homework/getsingle/${widget.homeworkId}');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = null; // keep showing the fallback values, just quietly
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      // ⚠️ Defensive parsing — exact shape not confirmed, adjust keys below
      // if your real response differs.
      final doc = (decoded is Map)
          ? (decoded['data'] ?? decoded['homework'] ?? decoded)
          : null;
      if (doc is! Map) {
        setState(() => _loading = false);
        return;
      }

      // Find the specific subject entry within this day's homework doc.
      final subjectsRaw = doc['subjects'];
      Map<String, dynamic>? subjectDoc;
      if (subjectsRaw is List) {
        if (widget.subjectId != null) {
          subjectDoc = subjectsRaw.cast<Map<String, dynamic>>().firstWhere(
                (s) => s['_id']?.toString() == widget.subjectId,
            orElse: () => subjectsRaw.first as Map<String, dynamic>,
          );
        } else if (subjectsRaw.isNotEmpty) {
          subjectDoc = subjectsRaw.first as Map<String, dynamic>;
        }
      }

      // Teacher details may live at the day level or the subject level —
      // check a few common shapes.
      String? teacherName;
      final rawTeacher = doc['teacherId'] ?? doc['assignedBy'] ??
          subjectDoc?['teacherId'] ?? subjectDoc?['assignedBy'];
      if (rawTeacher is Map) {
        teacherName = rawTeacher['name']?.toString() ??
            rawTeacher['userName']?.toString() ??
            rawTeacher['teacherName']?.toString();
      } else if (rawTeacher is String) {
        teacherName = rawTeacher;
      }
      teacherName ??= doc['teacherName']?.toString() ??
          subjectDoc?['teacherName']?.toString();

      final attachmentsRaw = subjectDoc?['attachments'] ?? doc['attachments'];
      final attachments = (attachmentsRaw as List? ?? [])
          .whereType<Map>()
          .map((a) => {
        'url': a['url']?.toString() ?? '',
        'originalName': a['originalName']?.toString(),
      })
          .where((a) => (a['url'] as String).isNotEmpty)
          .toList();

      setState(() {
        _subjectName = subjectDoc?['subjectName']?.toString() ?? _subjectName;
        _description = subjectDoc?['description']?.toString() ?? _description;
        _date = doc['homeworkDate']?.toString() ?? _date;
        _teacherName = teacherName;
        if (attachments.isNotEmpty) _attachments = attachments;
        _loading = false;
      });
    } catch (e) {
      // Quiet failure — the seeded fallback values stay on screen.
      setState(() => _loading = false);
    }
  }

  bool _isImage(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
        lower.endsWith('.png') || lower.endsWith('.gif') || lower.endsWith('.webp');
  }

  Future<void> _openAttachment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      Get.snackbar('Error', 'Could not open this file',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _openImageViewer(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(24),
              child: Icon(Icons.broken_image, color: Colors.white, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Assignment',
            style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _subjectName,
                    style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _description.isNotEmpty ? _description : 'No description provided',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.calendar_today, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(_date.split('T').first,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
                if (_teacherName != null && _teacherName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 15, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(_teacherName!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Attachments (${_attachments.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_attachments.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(children: [
                  Icon(Icons.attach_file, color: Colors.grey.shade300, size: 36),
                  const SizedBox(height: 8),
                  Text('No attachments for this assignment',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ]),
              ),
            )
          else
            ..._attachments.map((a) {
              final url = a['url'] as String;
              final name = a['originalName'] as String? ??
                  url.split('/').last;
              final isImg = _isImage(url);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: isImg
                    ? GestureDetector(
                  onTap: () => _openImageViewer(url),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                  ),
                )
                    : ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insert_drive_file_rounded, color: Colors.blue),
                  ),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                  onTap: () => _openAttachment(url),
                ),
              );
            }),
        ],
      ),
    );
  }
}