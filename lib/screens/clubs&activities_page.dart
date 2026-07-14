import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../controllers/auth_controller.dart';
import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../controllers/school_controller.dart';
import '../core/theme/app_theme.dart';
import '../services/user_session.dart';
import 'club_gallery.dart';


class ClubAndActivitiesPage extends StatefulWidget {
  const ClubAndActivitiesPage({super.key});

  @override
  State<ClubAndActivitiesPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubAndActivitiesPage> {
  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;
  final AuthController _authController = Get.find<AuthController>();

  MyChildrenController? get _childrenController =>
      Get.isRegistered<MyChildrenController>()
          ? Get.find<MyChildrenController>()
          : null;

  List<ClubsAndActivitiesStrings> apiClubs = [];
  bool isLoading = true;
 // final auth_ctrl = Get.find<AuthController>();

  // ── Quiz state ──
  List<ClubQuiz> _quizzes = [];
  bool _quizzesLoading = true;


  final List<String> clubNames = ['Music', 'Dance', 'Science & Technology', 'Theatre', 'Arts & Culture', 'Dance', 'Science & Technology', 'Theatre' 'Music', 'Dance', 'Science & Technology', 'Theatre'];

  bool _isFetching = false;
  String? _lastFetchedSchoolId;
  // ------------------------------------THE  CLUBS&ACTIVITIES FUNCTION -----------------------------


  Future<void> fetchClubsAndActivities() async {
    if (_isFetching) {
      debugPrint('⏭️ Skipping duplicate fetchClubsAndActivities — one is already in flight');
      return;
    }


    String baseUrl = ApiConstants.baseUrl;
    final String? token = _authController.storage.read('token');

    // Always get schoolId from selected school in controller
    String? schoolId;
    final role = _authController.user.value?.role?.toLowerCase() ?? '';

    if (role == 'correspondent') {
      schoolId = _school?.selectedSchool.value?.id;
    } else {
      schoolId =  _authController.user.value?.schoolId;
    }

    if (schoolId == null || schoolId.isEmpty) {
      setState(() {
        isLoading = false;
        _quizzesLoading = false;
      });
      debugPrint('⚠️ No schoolId available for clubs fetch');
      _isFetching = false;
      return;
    }
    if (schoolId == _lastFetchedSchoolId && apiClubs.isNotEmpty) {
      debugPrint('⏭️ Skipping fetch — already have data for schoolId $schoolId');
      return;
    }
    final queryParameters = {
      "schoolId": schoolId,
      "page": "1",
      "limit": "10"
    };

    final uri = Uri.parse('$baseUrl/api/club/getall')
        .replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final List<dynamic> list = decodedData['data'] ?? [];
        setState(() {
          apiClubs = list
              .map((data) => ClubsAndActivitiesStrings.fromJson(data))
              .toList();
          isLoading = false;
        });
        _lastFetchedSchoolId = schoolId;
        // Clubs are in — now pull in the quizzes that belong to them.
        await _fetchAllClubQuizzes();
      } else {
        setState(() {
          isLoading = false;
          _quizzesLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _quizzesLoading = false;
      });
      print("Error fetching clubs: $e");
    }finally {
      _isFetching = false; // NEW — always release, success or failure
    }
  }

  // ------------------------------------ QUIZZES ---------------------------------------------------

  Future<void> _fetchAllClubQuizzes() async {
    if (apiClubs.isEmpty) {
      setState(() {
        _quizzes = [];
        _quizzesLoading = false;
      });
      return;
    }

    setState(() => _quizzesLoading = true);
    final String? token = _authController.storage.read('token');

    // NEW: bail early with a clear log if there's no token — this is
    // the #1 suspect for "works for correspondent, not other roles".
    if (token == null || token.isEmpty) {
      print('⚠️ No token available when fetching club quizzes');
      if (mounted) {
        setState(() {
          _quizzes = [];
          _quizzesLoading = false;
        });
      }
      return;
    }

    final List<ClubQuiz> collected = [];

    for (final club in apiClubs) {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getQuizzesByClub}')
          .replace(queryParameters: {'clubId': club.id});
      try {
        final res = await http.get(uri, headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final list = (body['data'] as List? ?? []);
          print('✅ Quiz fetch for club ${club.id} (${club.name}): '
              '${list.length} quizzes returned. Raw: ${res.body}');
          print('➡️ Fetching quizzes for club ${club.id} (${club.name})');
          collected.addAll(list.map(
                  (e) => ClubQuiz.fromJson(e, clubNameFallback: club.name)));
        } else {
          // NEW: this was previously silent. Now we can actually see
          // why quizzes aren't showing up for a given role/club.
          print(
              '⚠️ Quiz fetch failed for club ${club.id} (${club.name}): '
                  'status=${res.statusCode} body=${res.body}');
        }
      } catch (e) {
        print('⚠️ Error fetching quizzes for club ${club.id}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _quizzes = collected;
        _quizzesLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // 1. Initial attempt to fetch data
    fetchClubsAndActivities();

    final role = _authController.user.value?.role?.toLowerCase() ?? '';

    // 2. Re-fetch when correspondent switches school from sidebar
    if (role == 'correspondent') {
      ever(_school!.selectedSchool, (_) {
        if (mounted) {
          // setState(() {
          //   isLoading = true;
          //   _quizzesLoading = true;
          // });
          fetchClubsAndActivities();
        }
      });
    } else {
      // 3. FIX FOR OTHER ROLES: Listen to user data loading/updates
      ever(_authController.user, (user) {
        if (mounted && user?.schoolId != null && user!.schoolId!.isNotEmpty && apiClubs.isEmpty) {
          setState(() {
            isLoading = true;
            _quizzesLoading = true;
          });
          fetchClubsAndActivities();
        }
      });
    }
  }


  // --------------------------------------------- BUILD METHOD ----------------------------------------


  @override
  Widget build(BuildContext context) {

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFEEF3FB),
        statusBarIconBrightness: Brightness.dark, // white icons
        statusBarBrightness: Brightness.dark,       // iOS
      ),
      child: Scaffold(
        backgroundColor: Color(0xFFEEF3FB),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _header(),
                  const SizedBox(height: 20),
                  _gridCards(),
                  const SizedBox(height: 24),
                  _quizzesSection(),
                  SizedBox(height: AppTheme.navBarPadding(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // -------------------------- HEADER FOR UNIVERSITY OR SCHOOL NAME --------------------------------------

  Widget _buildSchoolLogo() {
    try {
      final school = _authController.userSchool.value;
      if (school != null && school['logo'] != null && school['logo']['url'] != null) {
        return GestureDetector(
          onTap: () => _showFullScreenSchoolLogo(school['logo']['url']),
          child: Image.network(
            school['logo']['url'],
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.school_rounded,
                color: Color(0xFF2563EB),
                size: 30,
              );
            },
          ),
        );
      }
    } catch (e) {
      // Handle error silently
    }

    return const Icon(
      Icons.school_rounded,
      color: Color(0xFF2563EB),
      size: 30,
    );
  }
  void _showFullScreenSchoolLogo(String logoUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        Get.back();
                        Get.snackbar(
                          'Error',
                          'Failed to load logo',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _header() {
    return Obx(() {
      final role = _authController.user.value?.role?.toLowerCase() ?? '';
      final schoolName = role == 'correspondent'
          ? (_school?.selectedSchool.value?.name ?? '')
          : (_authController.user.value?.schoolName ?? _authController.user.value?.schoolName ?? '');

      return Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              schoolName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.search),
          ),
        ],
      );
    });
  }


  // -------------------------------------- CLUB CARDS (now vertical) ------------------------------------


  Widget _gridCards() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (apiClubs.isEmpty) return const Center(child: Text("No clubs found"));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: apiClubs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (BuildContext context, int index) {
        final club = apiClubs[index];
        final clubId = apiClubs[index].id;
        return _BounceCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SchoolGalleryPage(clubName: club.name, description: club.description, clubId: clubId,)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xff4A90E2), Color(0xff6FD3F7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff4A90E2).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club.name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              ],
            ),
          ),
        );
      },
    );
  }


  // ------------------------------------------- QUIZZES SECTION -----------------------------------------


  Widget _quizzesSection() {
    if (_quizzesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text("Quizzes",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        if (_quizzes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.quiz_outlined, size: 36, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text('No quizzes available yet.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quizzes.length,
            itemBuilder: (context, index) => _quizCard(_quizzes[index]),
          ),
      ],
    );
  }

  Widget _quizCard(ClubQuiz quiz) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuizAttemptPage(quiz: quiz)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.quiz_outlined, color: Colors.blue[700], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${quiz.clubName} · ${quiz.questions.length} questions',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------- MODEL CLASS TO GET THE DATA FOR UI NEED not in use ------------------------------------


class ClubsAndActivitiesStrings1{
  final String universityName;
  final String clubName;
  final String studentName;
  final String videoURL;
  final String description;

  ClubsAndActivitiesStrings1({required this.universityName, required this. clubName, required this.studentName, required this.videoURL, required this.description});


  factory ClubsAndActivitiesStrings1.fromJson(Map<String, dynamic> json) {
    return ClubsAndActivitiesStrings1(

      universityName: json['universityName'] ?? "Unknown",
      clubName: json['clubName'] ?? "Unknown",
      studentName: json['studentName'] ?? "Unknown",
      videoURL: json['videoURL']?? "Unknown",
      description: json['description'] ?? "Unknown",
    );
  }
}


// ---------------------------------------- MODEL CLASS TO GET THE DATA WHICH IS PRESENT IN DATABASE ------------------


class ClubsAndActivitiesStrings {
  final String id;
  final String name;
  final String description;
  final String? thumbnail;

  ClubsAndActivitiesStrings({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnail,
  });

  factory ClubsAndActivitiesStrings.fromJson(Map<String, dynamic> json) {
    return ClubsAndActivitiesStrings(
      id: json['_id'] ?? "",
      name: json['name'] ?? "Unknown Club",
      description: json['description'] ?? "",
      thumbnail: json['thumbnail'],
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
//  QUIZ MODELS
// ═════════════════════════════════════════════════════════════════════════════

class ClubQuizQuestion {
  final String questionText;
  final List<String> options;

  const ClubQuizQuestion({required this.questionText, required this.options});

  factory ClubQuizQuestion.fromJson(Map<String, dynamic> j) => ClubQuizQuestion(
    questionText: j['questionText'] ?? j['question'] ?? '',
    options: (j['options'] as List? ?? []).map((e) => '$e').toList(),
  );
}

class ClubQuiz {
  final String id;
  final String title;
  final String? description;
  final String clubId;
  final String clubName;
  final List<ClubQuizQuestion> questions;

  const ClubQuiz({
    required this.id,
    required this.title,
    this.description,
    required this.clubId,
    required this.clubName,
    required this.questions,
  });

  factory ClubQuiz.fromJson(Map<String, dynamic> j, {required String clubNameFallback}) {
    final rawClubId = j['clubId'];
    return ClubQuiz(
      id: j['_id'] ?? '',
      title: j['title'] ?? 'Untitled quiz',
      description: j['description'],
      clubId: rawClubId is Map ? (rawClubId['_id'] ?? '') : (rawClubId?.toString() ?? ''),
      clubName: rawClubId is Map ? (rawClubId['name'] ?? clubNameFallback) : clubNameFallback,
      questions: (j['questions'] as List? ?? [])
          .map((q) => ClubQuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
//  QUIZ ATTEMPT PAGE — student answers each question, submits for auto-grading
//  (POST /api/club/quiz/attempt/create), then sees score + correct answers.
// ═════════════════════════════════════════════════════════════════════════════

class QuizAttemptPage extends StatefulWidget {
  final ClubQuiz quiz;
  const QuizAttemptPage({super.key, required this.quiz});

  @override
  State<QuizAttemptPage> createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends State<QuizAttemptPage> {
  final auth_ctrl = Get.find<AuthController>();

  late List<int?> _selected;
  bool _submitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _selected = List<int?>.filled(widget.quiz.questions.length, null);
  }

  bool get _allAnswered => _selected.every((s) => s != null);

  Future<void> _submit() async {
    if (!_allAnswered) {
      Get.snackbar('Incomplete', 'Please answer every question before submitting',
          backgroundColor: Colors.orange, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _submitting = true);
    final String? token = auth_ctrl.storage.read('token');
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.SubmitQuiz}');

    final payload = {
      'quizId': widget.quiz.id,
      'studentAnswers': List.generate(_selected.length, (i) => {
        'index': i,
        'selectedOptionIndex': _selected[i],
      }),
      'academicYear': '2025-2026',
      // classId / sectionId are optional on this endpoint — wire them in
      // here once the logged-in student's classId & sectionId are exposed
      // on AuthController, so attempts can be filtered by class/section.
    };

    try {
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['ok'] == true) {
        setState(() {
          _result = body;
          _submitting = false;
        });
      } else {
        setState(() => _submitting = false);
        Get.snackbar('Error', body['message'] ?? 'Failed to submit quiz',
            backgroundColor: Colors.red, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      setState(() => _submitting = false);
      Get.snackbar('Error', 'Failed to submit quiz',
          backgroundColor: Colors.red, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _buildResultView();

    final quiz = widget.quiz;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(quiz.title,
            style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quiz.questions.length + 1,
        itemBuilder: (ctx, i) {
          if (i == quiz.questions.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit quiz'),
              ),
            );
          }

          final q = quiz.questions[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. ${q.questionText}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                for (int oi = 0; oi < q.options.length; oi++)
                  GestureDetector(
                    onTap: () => setState(() => _selected[i] = oi),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selected[i] == oi ? Colors.blue.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _selected[i] == oi ? Colors.blue.shade300 : Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selected[i] == oi ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 18,
                            color: _selected[i] == oi ? Colors.blue[700] : Colors.grey[400],
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(q.options[oi], style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultView() {
    final score = _result!['score'];
    final percentage = _result!['percentage'];
    final answers = ((_result!['data'] ?? {})['answers'] as List? ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Quiz result',
            style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue[700], borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text('$score / ${answers.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$percentage%', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < answers.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ${answers[i]['questionText']}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  for (int oi = 0; oi < (answers[i]['options'] as List).length; oi++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            oi == answers[i]['correctOptionIndex']
                                ? Icons.check_circle
                                : (oi == _selected[i] ? Icons.cancel : Icons.circle_outlined),
                            size: 16,
                            color: oi == answers[i]['correctOptionIndex']
                                ? Colors.green
                                : (oi == _selected[i] ? Colors.red : Colors.grey[400]),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${answers[i]['options'][oi]}', style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}


// -------------------------------------------- BOUNCE CARD ---------------------------------------------


class _BounceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _BounceCard({required this.child, required this.onTap});

  @override
  State<_BounceCard> createState() => _BounceCardState();
}

class _BounceCardState extends State<_BounceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) async {
        await _controller.reverse();
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}