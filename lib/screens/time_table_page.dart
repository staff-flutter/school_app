import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth_controller.dart';
import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../services/user_session.dart';

// ─── Design System: Light Blue Professional Theme (Shared) ───────────────────
class _DS {
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0284C7);
  static const primaryLight = Color(0xFF7DD3FC);
  static const primarySoft = Color(0xFFE0F2FE);
  static const primaryMuted = Color(0xFFBAE6FD);
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
  static const dangerSoft = Color(0xFFFEE2E2);
  static const border = Color(0xFFE2E8F0);
  static const shadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const radius = 16.0;
  static const radiusSm = 10.0;
  static const radiusLg = 24.0;
  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 24.0;
  static const spacingXxl = 32.0;
  static double get mobile => 600;
  static double get tablet => 900;
}

class _Responsive {
  static double padding(BuildContext context) =>
      MediaQuery.of(context).size.width < _DS.tablet ? _DS.spacingLg : _DS.spacingXl;
  static double fontSize(BuildContext context, {double mobile = 14, double tablet = 16}) =>
      MediaQuery.of(context).size.width < _DS.tablet ? mobile : tablet;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= _DS.tablet;
  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.symmetric(horizontal: padding(context));
}

// ─── Model ──────────────────────────────────────────────────────────────────
class TimetableListStrings {
  final String subjectName;
  final String time;
  final String teacherName;
  final String periodNumber;
  final bool isBreak;

  TimetableListStrings({
    required this.subjectName,
    required this.time,
    required this.teacherName,
    required this.periodNumber,
    required this.isBreak,
  });

  factory TimetableListStrings.fromJson(Map<String, dynamic> json) {
    final teacherRaw = json['teacherId'];
    final String teacherName;
    if (teacherRaw is Map) {
      teacherName = (teacherRaw['userName'] ?? 'N/A').toString();
    } else {
      teacherName = (teacherRaw ?? 'N/A').toString();
    }
    return TimetableListStrings(
      subjectName: json['isBreak'] == true ? "Break" : (json['subjectName'] ?? "Unknown").toString(),
      time: (json['timeRange'] ?? "00:00 - 00:00").toString(),
      teacherName: teacherName,
      periodNumber: json['periodNumber']?.toString() ?? "-",
      isBreak: json['isBreak'] ?? false,
    );
  }
}

// ─── MAIN PAGE ──────────────────────────────────────────────────────────────
class TimeTablePage extends StatefulWidget {
  const TimeTablePage({super.key});

  @override
  State<TimeTablePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<TimeTablePage> {
  static const double _chipWidth = 100.0;
  static const double _chipMargin = 6.0;
  late final MyChildrenController controller;
  final session = Get.find<UserSession>();
  final PageController _pageController = PageController();
  final ScrollController _dayScrollController = ScrollController();
  int _currentPageIndex = 0;
  final Map<int, Future<List<TimetableListStrings>>> _timetableFutures = {};
  final List<String> days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    controller = Get.put(MyChildrenController());
    _currentPageIndex = DateTime.now().weekday % 7;
    _timetableFutures[_currentPageIndex] = fetchTimetable(days[_currentPageIndex]);
    _preloadNearbyDays();
  }

  void _preloadNearbyDays() {
    for (int i = -1; i <= 1; i++) {
      int idx = (_currentPageIndex + i + 7) % 7;
      _timetableFutures[idx] ??= fetchTimetable(days[idx]);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dayScrollController.dispose();
    super.dispose();
  }

  Future<List<TimetableListStrings>> fetchTimetable(String day) async {
    final String baseUrl = ApiConstants.baseUrl;
    final selectedStudent = controller.selectedChild;
    final String? token = session.token;
    final String? schoolId = session.schoolId;
    final String? classId = selectedStudent['classId'] ?? 'null';
    final String? sectionId = selectedStudent['sectionId'] ?? 'null';

    final uri = Uri.parse('$baseUrl/api/timetable/getall').replace(queryParameters: {
      "schoolId": schoolId ?? "null",
      "classId": '$classId',
      "SectionId": '$sectionId',
      "day": day.toLowerCase(),
    });

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final List<dynamic> scheduleList = (decodedData is Map ? (decodedData['data'] ?? []) : decodedData) as List;

        for (final schedule in scheduleList) {
          final weeklySchedule = (schedule['weeklySchedule'] as List?) ?? [];
          for (final dayEntry in weeklySchedule) {
            final entryDay = (dayEntry['day'] as String? ?? '').toLowerCase();
            if (entryDay == day.toLowerCase()) {
              final periods = (dayEntry['periods'] as List?) ?? [];
              return periods.map((p) => TimetableListStrings.fromJson(p as Map<String, dynamic>)).toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Timetable fetch exception: $e");
    }
    return [];
  }

  void _scrollDayIntoView(int index) {
    if (!_dayScrollController.hasClients) return;
    final viewportWidth = _dayScrollController.position.viewportDimension;
    final maxScroll = _dayScrollController.position.maxScrollExtent;
    final itemOffset = index * (_chipWidth + _chipMargin * 2);
    final centeredOffset = itemOffset - (viewportWidth - _chipWidth) / 2;
    _dayScrollController.animateTo(
      centeredOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
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

  @override
  Widget build(BuildContext context) {
    final isTablet = _Responsive.isTablet(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppBarTheme(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: _DS.bg,
        body: SafeArea(
          top: false,
          bottom: false,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: (screenHeight * 0.18).clamp(100.0, 180.0),
                  floating: false,
                  pinned: true,
                  backgroundColor: _DS.primary,
                  leading: _shouldShowBack()
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                          onPressed: () => Get.back(),
                        )
                      : const SizedBox.shrink(),
                  title: const Text('Timetable', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  centerTitle: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_DS.primary, _DS.primaryDark]),
                          ),
                        ),
                        Positioned(
                          right: -50,
                          bottom: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      decoration: const BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 44,
                        child: ListView.builder(
                          controller: _dayScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: days.length,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemBuilder: (context, index) {
                            final isSelected = _currentPageIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _currentPageIndex = index);
                                _pageController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                                _scrollDayIntoView(index);
                                _timetableFutures[index] ??= fetchTimetable(days[index]);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _chipWidth,
                                margin: const EdgeInsets.symmetric(horizontal: _chipMargin),
                                decoration: BoxDecoration(
                                  color: isSelected ? _DS.primary : _DS.surfaceAlt,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: isSelected ? _DS.shadow : null,
                                ),
                                child: Center(
                                  child: Text(
                                    days[index].substring(0, 3),
                                    style: TextStyle(
                                      fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13),
                                      color: isSelected ? Colors.white : _DS.textSecondary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: Stack(
              children: [
                Positioned.fill(
                  top: 5,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: days.length,
                          onPageChanged: (index) {
                            setState(() => _currentPageIndex = index);
                            if (_dayScrollController.hasClients) _scrollDayIntoView(index);
                            _timetableFutures[index] ??= fetchTimetable(days[index]);
                            _preloadNearbyDays();
                          },
                          itemBuilder: (context, pageIndex) {
                            _timetableFutures[pageIndex] ??= fetchTimetable(days[pageIndex]);
                            return FutureBuilder<List<TimetableListStrings>>(
                              future: _timetableFutures[pageIndex],
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: Padding(padding: EdgeInsets.all(_DS.spacingXl), child: CircularProgressIndicator(color: _DS.primary, strokeWidth: 2)));
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: _DS.textMuted)));
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return _emptyState(context, icon: Icons.calendar_today_outlined, title: 'No classes', subtitle: 'No classes scheduled for ${days[pageIndex]}');
                                }
                                final items = snapshot.data!;
                                return ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  padding: _Responsive.pagePadding(context).copyWith(bottom: _DS.spacingXl),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) => TimeTableTile(item: items[index], context: context),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_DS.spacingXxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 70, height: 70, decoration: BoxDecoration(color: _DS.primarySoft, shape: BoxShape.circle), child: Icon(icon, size: 32, color: _DS.primary)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 16, tablet: 17), fontWeight: FontWeight.w700, color: _DS.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13), color: _DS.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─── TILE WIDGET ────────────────────────────────────────────────────────────
class TimeTableTile extends StatelessWidget {
  final TimetableListStrings item;
  final BuildContext context;

  const TimeTableTile({Key? key, required this.item, required this.context}) : super(key: key);

  static const List<Color> _subjectColors = [
    Color(0xFF0EA5E9),
    Color(0xFF7C3AED),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    if (item.isBreak) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: _DS.spacingSm, horizontal: _DS.spacingXs),
        padding: EdgeInsets.symmetric(vertical: _DS.spacingMd, horizontal: _DS.spacingLg),
        decoration: BoxDecoration(color: _DS.warningSoft, borderRadius: BorderRadius.circular(_DS.radius), border: Border.all(color: _DS.warning.withOpacity(0.3))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.free_breakfast_rounded, color: _DS.warning, size: 16),
            const SizedBox(width: 8),
            Text('Break', style: TextStyle(color: _DS.warning, fontWeight: FontWeight.w600, fontSize: _Responsive.fontSize(context, mobile: 13, tablet: 14))),
            const SizedBox(width: 8),
            Text(item.time, style: TextStyle(color: _DS.textMuted, fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12))),
          ],
        ),
      );
    }

    final colorIndex = int.tryParse(item.periodNumber) ?? 0;
    final accent = _subjectColors[colorIndex % _subjectColors.length];
    final isTablet = _Responsive.isTablet(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: _DS.spacingSm, horizontal: _DS.spacingXs),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radius),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: _DS.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Period badge
            Container(
              width: isTablet ? 70 : 55,
              padding: EdgeInsets.symmetric(vertical: _DS.spacingLg),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(_DS.radius), bottomLeft: Radius.circular(_DS.radius)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Period', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 9, tablet: 10), color: accent, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(item.periodNumber, style: TextStyle(fontSize: isTablet ? 20 : 17, color: accent, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: _DS.spacingLg, vertical: _DS.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.subjectName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: _Responsive.fontSize(context, mobile: 14, tablet: 15), color: _DS.textPrimary)),
                    const SizedBox(height: 6),
                    _infoRow(Icons.access_time_rounded, item.time, context),
                    const SizedBox(height: 4),
                    _infoRow(Icons.person_outline_rounded, item.teacherName, context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _DS.textMuted),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12), color: _DS.textSecondary))),
      ],
    );
  }
}