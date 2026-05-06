import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class NoticeModel {
  final String title;
  final String description;
  final String date;
  final String category;
  final bool isPinned;

  NoticeModel({
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    this.isPinned = false,
  });
}

class NoticeBoardScreenUi extends StatefulWidget {
  const NoticeBoardScreenUi({super.key});

  @override
  State<NoticeBoardScreenUi> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreenUi> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _tabs = ['All', 'Exams', 'Events', 'Holidays', 'Urgent', 'General'];
  final ScrollController _tabScrollController = ScrollController();

  static const double _tabWidth = 90.0;
  static const double _tabMargin = 6.0;

  final List<NoticeModel> _notices = [
    NoticeModel(
      title: 'Annual Exam Schedule Released',
      description: 'Final exams begin May 12. Check your individual timetable for subject-wise slots and hall numbers.',
      date: 'May 1, 2026',
      category: 'exam',
      isPinned: true,
    ),
    NoticeModel(
      title: 'Mid-term Results Declared',
      description: 'Mid-term result cards will be distributed on May 6th. Parents are requested to collect them.',
      date: 'Apr 28, 2026',
      category: 'exam',
    ),
    NoticeModel(
      title: 'Practical Exam Schedule',
      description: 'Lab practical exams for Science & Computer Science are scheduled from May 14 to May 16.',
      date: 'Apr 25, 2026',
      category: 'exam',
    ),
    NoticeModel(
      title: 'Sports Day — Registration Open',
      description: 'Register your child for inter-house sports events. Deadline: May 8th.',
      date: 'Apr 30, 2026',
      category: 'event',
      isPinned: true,
    ),
    NoticeModel(
      title: 'Annual Day Celebration',
      description: 'Annual day cultural program will be held on May 20. Students are requested to rehearse their acts.',
      date: 'Apr 27, 2026',
      category: 'event',
    ),
    NoticeModel(
      title: 'Science Exhibition',
      description: 'Inter-school science exhibition on May 15. Selected students will represent our school.',
      date: 'Apr 24, 2026',
      category: 'event',
    ),
    NoticeModel(
      title: 'School Closed — Eid Holiday',
      description: 'School will remain closed on May 3rd & 4th on account of Eid celebration.',
      date: 'Apr 29, 2026',
      category: 'holiday',
    ),
    NoticeModel(
      title: 'Summer Vacation Notice',
      description: 'Summer vacation from May 25 to June 15. School reopens June 16.',
      date: 'Apr 26, 2026',
      category: 'holiday',
    ),
    NoticeModel(
      title: 'Fee Payment Reminder',
      description: 'Last date to pay Term 2 fees without late charges is May 5, 2026.',
      date: 'Apr 28, 2026',
      category: 'urgent',
    ),
    NoticeModel(
      title: 'Uniform Compliance Notice',
      description: 'All students must wear proper uniform from May 3rd. Strict action will be taken.',
      date: 'Apr 26, 2026',
      category: 'urgent',
    ),
    NoticeModel(
      title: 'Parent-Teacher Meeting',
      description: 'PTM scheduled for May 10, 2026. Slots can be booked via the app.',
      date: 'Apr 27, 2026',
      category: 'general',
    ),
    NoticeModel(
      title: 'Library Books Return',
      description: 'All borrowed library books must be returned by May 9th to avoid fines.',
      date: 'Apr 25, 2026',
      category: 'general',
    ),
  ];

  // ✅ Map each tab index to filtered notices
  List<NoticeModel> _getNoticesForTab(int tabIndex) {
    if (tabIndex == 0) return _notices;

    const tabToCategory = {
      1: 'exam',
      2: 'event',
      3: 'holiday',
      4: 'urgent',
      5: 'general',
    };

    final category = tabToCategory[tabIndex];
    return _notices.where((n) => n.category == category).toList();
  }

  void _scrollTabIntoView(int index) {
    if (!_tabScrollController.hasClients) return;
    final viewportWidth = _tabScrollController.position.viewportDimension;
    final maxScroll = _tabScrollController.position.maxScrollExtent;
    final itemOffset = index * (_tabWidth + _tabMargin * 2);
    final centeredOffset = itemOffset - (viewportWidth - _tabWidth) / 2;
    _tabScrollController.animateTo(
      centeredOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // white icons
        statusBarBrightness: Brightness.dark,       // iOS
      ),
      child: Scaffold(
        bottomNavigationBar: SizedBox(height: bottomPadding),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: (screenHeight * 0.18).clamp(100.0, 160.0),
              pinned: true,
              backgroundColor: const Color(0xFF2B5BA8),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Get.back(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {},
                ),
              ],
              title: const Text(
                'Notice Board',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              centerTitle: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/Scientific UI background design header.png',
                      fit: BoxFit.cover,
                    ),
                    Container(color: Colors.black.withOpacity(0.1)),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF3FB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      controller: _tabScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _tabs.length,
                      itemBuilder: (context, i) {
                        final isActive = _currentPage == i;
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                            _scrollTabIntoView(i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _tabWidth,
                            margin: const EdgeInsets.symmetric(horizontal: _tabMargin),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF2B5BA8) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF2B5BA8)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _tabs[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                  color: isActive ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
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
          ],

          // ✅ PageView as the body — each tab is a swipeable page
          body: PageView.builder(
            controller: _pageController,
            itemCount: _tabs.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _scrollTabIntoView(index);
            },
            itemBuilder: (context, pageIndex) {
              final notices = _getNoticesForTab(pageIndex);
              final pinned = notices.where((n) => n.isPinned).toList();
              final recent = notices.where((n) => !n.isPinned).toList();

              if (notices.isEmpty) {
                return Container(
                  color: const Color(0xFFEEF3FB),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No notices here yet',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Check back later',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                color: const Color(0xFFEEF3FB),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding:  EdgeInsets.fromLTRB(12, 8, 12, 80),
                  children: [
                    if (pinned.isNotEmpty) ...[
                      _sectionLabel('📌  Pinned'),
                      ...pinned.map((n) => _NoticeCard(notice: n)),
                    ],
                    if (recent.isNotEmpty) ...[
                      _sectionLabel('Recent'),
                      ...recent.map((n) => _NoticeCard(notice: n)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF7A8BA8),
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _NoticeCard extends StatelessWidget {
  final NoticeModel notice;
  const _NoticeCard({required this.notice});
  @override
  Widget build(BuildContext context) {
    final badge = _badge(notice.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          // ✅ White card — always full rounded corners, no border conflict
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100, width: 0.5),
            ),
            padding: EdgeInsets.fromLTRB(
                notice.isPinned ? 18 : 14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (notice.isPinned)
                      Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.only(top: 4, right: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2B5BA8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(notice.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2540),
                            height: 1.3,
                          )),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badge['bg'],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(badge['label']!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: badge['text'],
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(notice.description,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF7A8BA8), height: 1.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(notice.date,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Read more',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2B5BA8),
                            )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ✅ Left blue bar — Positioned overlay, no border radius conflict
          if (notice.isPinned)
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF2B5BA8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  Map<String, dynamic> _badge(String category) {
    switch (category) {
      case 'exam':   return {'label': 'Exam',    'bg': const Color(0xFFEDE9FF), 'text': const Color(0xFF534AB7)};
      case 'event':  return {'label': 'Event',   'bg': const Color(0xFFE1F5EE), 'text': const Color(0xFF0F6E56)};
      case 'holiday':return {'label': 'Holiday', 'bg': const Color(0xFFFAEEDA), 'text': const Color(0xFF854F0B)};
      case 'urgent': return {'label': 'Urgent',  'bg': const Color(0xFFFCEBEB), 'text': const Color(0xFFA32D2D)};
      default:       return {'label': 'General', 'bg': const Color(0xFFE6F1FB), 'text': const Color(0xFF185FA5)};
    }
  }
}