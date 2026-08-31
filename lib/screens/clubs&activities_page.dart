import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:school_app/core/utils/academic_year_utils.dart';
import 'package:school_app/screens/quiz_leaderboard_page.dart';

import '../controllers/auth_controller.dart';
import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../controllers/school_controller.dart';
import '../core/theme/app_theme.dart';
import '../services/user_session.dart';
import 'club_gallery.dart';
import 'club_quiz_attempt_page.dart';


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

  // ── Quiz state ──
  List<ClubQuiz> _quizzes = [];
  bool _quizzesLoading = true;
  String? get _schoolId {
    final role = _authController.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') {
      return _school?.selectedSchool.value?.id;
    }
    return _authController.user.value?.schoolId;
  }
  // 🌟 NEW: State tracking for selected club dropdown filter
  ClubsAndActivitiesStrings? _selectedClubFilter;

  final List<String> clubNames = ['Music', 'Dance', 'Science & Technology', 'Theatre', 'Arts & Culture', 'Dance', 'Science & Technology', 'Theatre' 'Music', 'Dance', 'Science & Technology', 'Theatre'];

  bool _isFetching = false;
  String? _lastFetchedSchoolId;

  // ------------------------------------THE  CLUBS&ACTIVITIES FUNCTION -----------------------------

  Future<void> fetchClubsAndActivities({bool isRefresh = false}) async {
    print('🟢 fetchClubsAndActivities called, isRefresh=$isRefresh');
    if (_isFetching) {
      print('🔴 skipped — already fetching');
      return;
    }

    if (isRefresh) {
      _lastFetchedSchoolId = null;
    }

    String baseUrl = ApiConstants.baseUrl;
    final String? token = _authController.storage.read('token');

    String? schoolId;
    final role = _authController.user.value?.role?.toLowerCase() ?? '';

    if (role == 'correspondent') {
      schoolId = _school?.selectedSchool.value?.id;
    } else {
      schoolId = _authController.user.value?.schoolId;
    }

    print('🟡 role=$role schoolId=$schoolId token=${token != null ? "present" : "NULL"}');

    if (schoolId == null || schoolId.isEmpty) {
      print('🔴 schoolId empty — bailing out early');
      setState(() {
        isLoading = false;
        _quizzesLoading = false;
      });
      _isFetching = false;
      return;
    }
    if (!isRefresh && schoolId == _lastFetchedSchoolId && apiClubs.isNotEmpty) {
      print('🔴 skipped — same schoolId already fetched, apiClubs.length=${apiClubs.length}');
      return;
    }

    _isFetching = true;
    final queryParameters = {
      "schoolId": schoolId,
      "page": "1",
      "limit": "10"
    };

    final uri = Uri.parse('$baseUrl/api/club/getall')
        .replace(queryParameters: queryParameters);

    print('🟣 calling $uri');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      print('🟣 response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final List<dynamic> list = decodedData['data'] ?? [];
        final parsed = list.map((data) => ClubsAndActivitiesStrings.fromJson(data)).toList();

        final Map<String, ClubsAndActivitiesStrings> uniqueMap = {
          for (var c in parsed) c.id: c
        };

        setState(() {
          apiClubs = uniqueMap.values.toList();
          isLoading = false;
        });

        print('🔵 apiClubs: ${apiClubs.length} — ${apiClubs.map((c) => c.name).toList()}');

        _lastFetchedSchoolId = schoolId;
        await _fetchAllClubQuizzes();
      } else {
        print('🔴 non-200 response: ${response.body}');
        setState(() {
          isLoading = false;
          _quizzesLoading = false;
        });
      }
    } catch (e, st) {
      print('🔴 EXCEPTION: $e');
      print(st);
      setState(() {
        isLoading = false;
        _quizzesLoading = false;
      });
    } finally {
      _isFetching = false;
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

    if (token == null || token.isEmpty) {
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
          .replace(queryParameters: {'clubId': club.id,'schoolId': _schoolId,'academicYear': AcademicYearUtils.getCurrentAcademicYear()});
      try {
        final res = await http.get(uri, headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);

          final list = (body['data'] as List? ?? []);

          collected.addAll(list.map(
                  (e) => ClubQuiz.fromJson(e, clubNameFallback: club.name)));
        } else {
        }
      } catch (e) {
      }
    }

    if (mounted) {
      setState(() {
        final Map<String, ClubQuiz> uniqueQuizzesMap = {};

        for (var quiz in collected) {
          if (quiz.id.isNotEmpty) {
            uniqueQuizzesMap[quiz.id] = quiz;
          }
        }

        _quizzes = uniqueQuizzesMap.values.toList();
        print('🟠 quizzes: ${_quizzes.length} — ${_quizzes.map((q) => q.title).toList()}');
        _quizzesLoading = false;
      });
    }
  }
  @override
  void initState() {
    super.initState();
    fetchClubsAndActivities();

    final role = _authController.user.value?.role?.toLowerCase() ?? '';

    if (role == 'correspondent') {
      final school = _school;
      if (school != null) {
        ever(school.selectedSchool, (_) {
          if (mounted) fetchClubsAndActivities();
        });
      }
    } else {
      String? _lastEverSchoolId = _authController.user.value?.schoolId;
      ever(_authController.user, (user) {
        final newSchoolId = user?.schoolId;
        if (mounted &&
            newSchoolId != null &&
            newSchoolId.isNotEmpty &&
            newSchoolId != _lastEverSchoolId) {   // ← only fetch if it actually changed
          _lastEverSchoolId = newSchoolId;
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
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: MediaQuery.removePadding(   // ← add this
        context: context,
        removeBottom: true,              // ← strips ambient bottom inset from MainWrapper
        child: Scaffold(
          backgroundColor: const Color(0xFFEEF3FB),
          body: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: RefreshIndicator(
                onRefresh: () => fetchClubsAndActivities(isRefresh: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
        ),
      ),
    );
  }

  Widget _header() {
    return Obx(() {
      final role = _authController.user.value?.role?.toLowerCase() ?? '';
      final schoolName = role == 'correspondent'
          ? (_school?.selectedSchool.value?.name ?? '')
          : (_authController.user.value?.schoolName ?? '');

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
        final bool hasThumbnail = club.thumbnail != null && club.thumbnail!.isNotEmpty;
        return _BounceCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SchoolGalleryPage(clubName: club.name, description: club.description, clubId: clubId,)),
            );
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: hasThumbnail
                      ? Image.network(
                    club.thumbnail!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xff4A90E2), Color(0xff6FD3F7)]),
                      ),
                    ),
                  )
                      : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xff4A90E2), Color(0xff6FD3F7)]),
                    ),
                  ),
                ),
              ),
              if (hasThumbnail)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(color: Colors.black.withOpacity(0.45)),
                  ),
                ),
              // ── Member count badge (top-right) ──
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClubMembersPage(clubId: club.id, clubName: club.name),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_alt_rounded, size: 12, color: Colors.black87),
                        const SizedBox(width: 4),
                        Text(
                          '${club.memberCount}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      club.name,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
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

    final filteredQuizzes = _selectedClubFilter == null
        ? _quizzes
        : _quizzes.where((quiz) => quiz.clubId == _selectedClubFilter!.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Quizzes",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ClubsAndActivitiesStrings?>(
                    value: _selectedClubFilter,
                    hint: const Text(
                      "All Clubs",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    isDense: true,
                    isExpanded: true, // 👈 FIX: Allow content to wrap/truncate safely inside bounds
                    style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700], size: 18),
                    items: [
                      const DropdownMenuItem<ClubsAndActivitiesStrings?>(
                        value: null,
                        child: Text("All Clubs", overflow: TextOverflow.ellipsis),
                      ),
                      ...apiClubs.map((club) {
                        return DropdownMenuItem<ClubsAndActivitiesStrings?>(
                          value: club,
                          child: Text(
                            club.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (ClubsAndActivitiesStrings? newValue) {
                      setState(() {
                        _selectedClubFilter = newValue;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredQuizzes.isEmpty)
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
                Text('No quizzes available yet for this selection.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredQuizzes.length,
            itemBuilder: (context, index) => _quizCard(filteredQuizzes[index]),
          ),
      ],
    );
  }
  Widget _quizCard(ClubQuiz quiz) {
    return GestureDetector(
      onTap: () => _onQuizTap(quiz),
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

  Future<void> _onQuizTap(ClubQuiz quiz) async {
    final role = _authController.user.value?.role?.toLowerCase() ?? '';
    final isParent = role == 'parent';

    // if (!isParent) {
    //   // Every other role: view the leaderboard only, never attempt.
    //   Navigator.push(context, MaterialPageRoute(
    //     builder: (_) => QuizLeaderboardPage(
    //       quizId: quiz.id,
    //       quizTitle: quiz.title,
    //       canDelete: role == 'correspondent' || role == 'administrator',
    //     ),
    //   ));
    //   return;
    // }

    if (!isParent) {
      // Admin/correspondent/others: view the quiz content only, never attempt.
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => QuizViewOnlyPage(
          quiz: quiz,
          schoolId: _schoolId ?? '',
          canDelete: role == 'correspondent' || role == 'administrator',
        ),
      ));
      return;
    }

    final child = _childrenController?.selectedChild;
    final studentId = (child?['_id'] ?? '').toString();
    if (studentId.isEmpty) {
      Get.snackbar('Select a child', 'Please select a child before attempting a quiz',
          backgroundColor: Colors.orange, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final classId = (child?['classId'] ?? '').toString();
    final sectionId = (child?['sectionId'] ?? '').toString();

    // ⚠️ FALLBACK: this can't actually detect a prior attempt yet, since the
    // backend returns studentId: null on every stored attempt. It's wired up
    // so it starts working the moment that's fixed — no client change needed.
    final token = _authController.storage.read('token') ?? '';
    final existing = await QuizAttemptApi.fetchAttempts(
      token: token, quizId: quiz.id, studentId: studentId,
    );
    final mine = existing.where((a) => a.studentId == studentId).toList();

    if (mine.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => QuizAttemptSummaryPage(attempt: mine.first, quiz: quiz),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => QuizAttemptPage(
          quiz: quiz,
          studentId: studentId,
          classId: classId.isEmpty ? null : classId,
          sectionId: sectionId.isEmpty ? null : sectionId,
        ),
      ));
    }
  }
}

class QuizViewOnlyPage extends StatelessWidget {
  final ClubQuiz quiz;
  final String schoolId;
  final bool canDelete;

  const QuizViewOnlyPage({super.key, required this.quiz,required this.schoolId,  this.canDelete = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quiz.title,
                style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
            Text(quiz.clubName, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
      body: quiz.questions.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(children: [
            Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No questions in this quiz.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quiz.questions.length + 1,
        itemBuilder: (ctx, i) {
          if (i == quiz.questions.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizLeaderboardPage(
                        quizId: quiz.id,
                        quizTitle: quiz.title,
                        schoolId: schoolId,
                        canDelete: canDelete,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.leaderboard_outlined),
                label: const Text('View leaderboard'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. ${q.questionText}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                for (int oi = 0; oi < q.options.length; oi++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: oi == q.correctOptionIndex ? Colors.green.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: oi == q.correctOptionIndex ? Colors.green.shade300 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            oi == q.correctOptionIndex ? Icons.check_circle : Icons.circle_outlined,
                            size: 18,
                            color: oi == q.correctOptionIndex ? Colors.green : Colors.grey[400],
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
}
class ClubMembersPage extends StatefulWidget {
  final String clubId;
  final String clubName;
  const ClubMembersPage({super.key, required this.clubId, required this.clubName});

  @override
  State<ClubMembersPage> createState() => _ClubMembersPageState();
}

class _ClubMembersPageState extends State<ClubMembersPage> {
  final AuthController _authController = Get.find<AuthController>();
  List<ClubMember> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = _authController.storage.read('token') ?? '';
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getClub}/${widget.clubId}');
    try {
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final rawStudents = (body['data'] as Map?)?['studentId'];
        final members = rawStudents is List
            ? rawStudents
            .whereType<Map>()
            .map((m) => ClubMember.fromJson(Map<String, dynamic>.from(m)))
            .toList()
            : <ClubMember>[];
        if (mounted) setState(() { _members = members; _loading = false; });
      } else {
        if (mounted) setState(() { _members = []; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _members = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Club Members',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
            Text(widget.clubName, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No members in this club yet.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final m = _members[i];
            final hasImage = m.imageUrl != null && m.imageUrl!.isNotEmpty;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: hasImage ? NetworkImage(m.imageUrl!) : null,
                  child: hasImage
                      ? null
                      : Text(
                    m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                    style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                      if (m.rollNumber != null && m.rollNumber!.isNotEmpty)
                        Text('Roll: ${m.rollNumber}', style: TextStyle(fontSize: 11, color: Colors.grey[500]))
                      else if (m.srId != null)
                        Text(m.srId!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
class QuizAttemptSummaryPage extends StatelessWidget {
  final ClubQuizAttempt attempt;
  final ClubQuiz quiz;
  const QuizAttemptSummaryPage({super.key, required this.attempt, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(quiz.title,
            style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue[700], borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Text('${attempt.score} / ${attempt.answers.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${attempt.percentage}%', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Already attempted on ${attempt.completedAt.split('T').first}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < attempt.answers.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ${attempt.answers[i]['questionText'] ?? ''}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  for (int oi = 0; oi < (attempt.answers[i]['options'] as List? ?? []).length; oi++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Icon(
                          oi == attempt.answers[i]['correctOptionIndex'] ? Icons.check_circle : Icons.circle_outlined,
                          size: 16,
                          color: oi == attempt.answers[i]['correctOptionIndex'] ? Colors.green : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${attempt.answers[i]['options'][oi]}', style: const TextStyle(fontSize: 12))),
                      ]),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------- MODEL CLASSES & ATTEMPT PAGE REMAIN UNCHANGED ------------------------------------

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

class ClubsAndActivitiesStrings {
  final String id;
  final String name;
  final String description;
  final String? thumbnail;
  final int memberCount;

  ClubsAndActivitiesStrings({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnail,
    this.memberCount = 0,
  });

  factory ClubsAndActivitiesStrings.fromJson(Map<String, dynamic> json) {
    String? thumbnailUrl;
    if (json['thumbnail'] is Map) {
      thumbnailUrl = json['thumbnail']['url']?.toString();
    } else if (json['thumbnail'] is String) {
      thumbnailUrl = json['thumbnail'];
    }
    int memberCount = 0;
    // studentId is the membership array on the club document — count its length.
    // Falls back to an explicit memberCount field if the backend ever sends one instead.
    final rawStudents = json['studentId'];
    if (rawStudents is List) {
      memberCount = rawStudents.length;
    } else {
      final rawCount = json['memberCount'];
      if (rawCount is num) {
        memberCount = rawCount.toInt();
      }
    }
    return ClubsAndActivitiesStrings(
      id: json['_id'] ?? "",
      name: json['name'] ?? "Unknown Club",
      description: json['description'] ?? "",
      thumbnail: thumbnailUrl,
      memberCount: memberCount,
    );
  }
}

class ClubQuizQuestion {
  final String questionText;
  final List<String> options;

  final int? correctOptionIndex;

  const ClubQuizQuestion({this.correctOptionIndex,required this.questionText, required this.options});

  factory ClubQuizQuestion.fromJson(Map<String, dynamic> j) {
    final rawCorrect = j['correctOptionIndex'] ?? j['correctAnswerIndex'] ?? j['answerIndex'];
    return ClubQuizQuestion(
      questionText: j['questionText'] ?? j['question'] ?? '',
      options: (j['options'] as List? ?? []).map((e) => '$e').toList(),
      correctOptionIndex: rawCorrect is num ? rawCorrect.toInt() : null,
    );
  }
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

class QuizAttemptPage extends StatefulWidget {
  final ClubQuiz quiz;
  final String studentId;
  final String? classId;
  final String? sectionId;

  const QuizAttemptPage({
    super.key,
    required this.quiz,
    required this.studentId,
    this.classId,
    this.sectionId,
  });

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
      'studentId': widget.studentId,

      'studentAnswers': List.generate(_selected.length, (i) => {
        'index': i,
        'selectedOptionIndex': _selected[i],
      }),
      if (widget.classId != null) 'classId': widget.classId,
      if (widget.sectionId != null) 'sectionId': widget.sectionId,
      'academicYear': AcademicYearUtils.getCurrentAcademicYear(),
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
class ClubMember {
  final String id;
  final String name;
  final String? imageUrl;
  final String? rollNumber;
  final String? srId;

  ClubMember({
    required this.id,
    required this.name,
    this.imageUrl,
    this.rollNumber,
    this.srId,
  });

  factory ClubMember.fromJson(Map<String, dynamic> j) {
    final nonMandatory = j['nonMandatory'];
    return ClubMember(
      id: j['_id']?.toString() ?? '',
      name: j['studentName']?.toString() ?? 'Unknown',
      imageUrl: j['studentImage']?.toString(),
      rollNumber: nonMandatory is Map ? nonMandatory['rollNumber']?.toString() : null,
      srId: j['srId']?.toString(),
    );
  }
}
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