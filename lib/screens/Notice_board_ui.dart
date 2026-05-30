import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/announcement_controller.dart';

import 'announcement_detail_page.dart'; // your existing controller

class NoticeBoardScreenUi extends StatefulWidget {
  const NoticeBoardScreenUi({super.key});

  @override
  State<NoticeBoardScreenUi> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreenUi> {
  late final AnnouncementController _controller;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _tabs = ['All', 'Events', 'Holidays', 'Urgent', 'General'];
  final ScrollController _tabScrollController = ScrollController();
  static const double _tabWidth = 90.0;
  static const double _tabMargin = 6.0;

  @override
  void initState() {
    super.initState();
    // Use existing controller — don't create a new one
    _controller = Get.find<AnnouncementController>();
  }

  // Map tab index to announcement 'type' field from API
  List<Map<String, dynamic>> _getNoticesForTab(
      int tabIndex, List<Map<String, dynamic>> all) {
    if (tabIndex == 0) return all;

    const tabToType = {
      1: 'event',
      2: 'holiday',
      3: 'urgent',
      4: 'general',
    };

    final type = tabToType[tabIndex];
    return all.where((n) {
      final t = (n['type'] ?? '').toString().toLowerCase();
      return t == type;
    }).toList();
  }

  bool _isPinned(Map<String, dynamic> n) {
    final priority = (n['priority'] ?? '').toString().toLowerCase();
    return priority == 'high' || priority == 'urgent';
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
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        bottomNavigationBar: SizedBox(height: bottomPadding),
        body: Obx(() {
          // Full screen loader on first load
          if (_controller.isLoading.value &&
              _controller.filteredAnnouncements.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2B5BA8)),
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                expandedHeight: (screenHeight * 0.18).clamp(100.0, 160.0),
                pinned: true,
                backgroundColor: const Color(0xFF2B5BA8),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: () => Get.back(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      final schoolId = _controller.selectedSchool.value?.id;
                      if (schoolId != null) {
                        _controller.getAllAnnouncements(schoolId);
                      }
                    },
                  ),
                ],
                title: const Text(
                  'Notice Board',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
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
                              _pageController.animateToPage(i,
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut);
                              _scrollTabIntoView(i);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _tabWidth,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: _tabMargin),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF2B5BA8)
                                    : Colors.white,
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
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.black87,
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
            body: PageView.builder(
              controller: _pageController,
              itemCount: _tabs.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _scrollTabIntoView(index);
              },
              itemBuilder: (context, pageIndex) {
                // Use filteredAnnouncements (already role-filtered by controller)
                final notices = _getNoticesForTab(
                    pageIndex, _controller.filteredAnnouncements);
                final pinned = notices.where(_isPinned).toList();
                final recent = notices.where((n) => !_isPinned(n)).toList();

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
                          Text('No notices here yet',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500)),
                          Text('Check back later',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF2B5BA8),
                  onRefresh: () async {
                    final schoolId = _controller.selectedSchool.value?.id;
                    if (schoolId != null) {
                      await _controller.getAllAnnouncements(schoolId);
                    }
                  },
                  child: Container(
                    color: const Color(0xFFEEF3FB),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
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
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
    child: Text(text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7A8BA8),
          letterSpacing: 0.5,
        )),
  );
}

// ─── Notice Card ──────────────────────────────────────────────────────────────

class _NoticeCard extends StatelessWidget {
  final Map<String, dynamic> notice;
  const _NoticeCard({required this.notice});

  bool get _isPinned {
    final priority = (notice['priority'] ?? '').toString().toLowerCase();
    return priority == 'high' || priority == 'urgent';
  }

  @override
  Widget build(BuildContext context) {
    final category = (notice['type'] ?? 'general').toString().toLowerCase();
    final badge = _badge(category);
    final targetAudience = (notice['targetAudience'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [];
    final targetClasses = (notice['targetClasses'] as List?)
        ?.map((e) => e is Map ? e['name']?.toString() ?? '' : e.toString())
        .where((e) => e.isNotEmpty)
        .toList() ??
        [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Get.to(
                    () => AnnouncementDetailPage(notice: notice),
                transition: Transition.fadeIn,
              ),
              child: Container(
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
                padding:
                EdgeInsets.fromLTRB(_isPinned ? 18 : 14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isPinned)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4, right: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2B5BA8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notice['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A2540),
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badge['bg'],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge['label']!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: badge['text'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notice['description'] ?? '',
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF7A8BA8),
                          height: 1.5),
                    ),
                    // Target classes chips
                    if (targetClasses.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: targetClasses
                            .map((cls) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF3FB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(cls,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF2B5BA8),
                                fontWeight: FontWeight.w500,
                              )),
                        ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (targetAudience.isNotEmpty) ...[
                          Icon(Icons.people_outline,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              targetAudience.join(', '),
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade400),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const Spacer(),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF3FB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Attachments',
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
            ),
          ),
          if (_isPinned)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
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
      case 'exam':
        return {
          'label': 'Exam',
          'bg': const Color(0xFFEDE9FF),
          'text': const Color(0xFF534AB7)
        };
      case 'event':
        return {
          'label': 'Event',
          'bg': const Color(0xFFE1F5EE),
          'text': const Color(0xFF0F6E56)
        };
      case 'holiday':
        return {
          'label': 'Holiday',
          'bg': const Color(0xFFFAEEDA),
          'text': const Color(0xFF854F0B)
        };
      case 'urgent':
        return {
          'label': 'Urgent',
          'bg': const Color(0xFFFCEBEB),
          'text': const Color(0xFFA32D2D)
        };
      default:
        return {
          'label': 'General',
          'bg': const Color(0xFFE6F1FB),
          'text': const Color(0xFF185FA5)
        };
    }
  }
}