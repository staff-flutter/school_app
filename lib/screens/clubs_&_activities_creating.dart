import 'package:flutter/material.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ClubCategory {
  String id;
  String name;
  String description;
  String bannerUrl;
  Color colorFrom;
  Color colorTo;

  ClubCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.bannerUrl,
    required this.colorFrom,
    required this.colorTo,
  });
}

class CampusStar {
  String id;
  String name;
  String role;
  String photoUrl;
  String club;
  String bio;

  CampusStar({
    required this.id,
    required this.name,
    required this.role,
    required this.photoUrl,
    required this.club,
    required this.bio,
  });
}

class CampusPost {
  String id;
  String authorName;
  String authorPhotoUrl;
  String caption;
  String mediaUrl;
  String thumbnailUrl;
  String mediaType; // 'image' or 'video'
  String clubTag;
  String timeAgo;

  CampusPost({
    required this.id,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.caption,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.mediaType,
    required this.clubTag,
    required this.timeAgo,
  });
}

// ─── Main View ────────────────────────────────────────────────────────────────

class CampusManagementView extends StatefulWidget {
  const CampusManagementView({super.key});

  @override
  State<CampusManagementView> createState() => _CampusManagementViewState();
}

class _CampusManagementViewState extends State<CampusManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Sample data ──
  final List<ClubCategory> _clubs = [
    ClubCategory(
      id: '1',
      name: 'Music',
      description: 'Band, choir, instruments',
      bannerUrl: '',
      colorFrom: const Color(0xFF42A5F5),
      colorTo: const Color(0xFF26C6DA),
    ),
    ClubCategory(
      id: '2',
      name: 'Science & Technology',
      description: 'STEM, robotics, coding',
      bannerUrl: '',
      colorFrom: const Color(0xFF29B6F6),
      colorTo: const Color(0xFF26C6DA),
    ),
    ClubCategory(
      id: '3',
      name: 'Dance',
      description: 'Contemporary, hip-hop',
      bannerUrl: '',
      colorFrom: const Color(0xFF42A5F5),
      colorTo: const Color(0xFF4DD0E1),
    ),
    ClubCategory(
      id: '4',
      name: 'Theatre',
      description: 'Drama, stage, productions',
      bannerUrl: '',
      colorFrom: const Color(0xFF29B6F6),
      colorTo: const Color(0xFF4FC3F7),
    ),
  ];

  final List<CampusStar> _stars = [
    CampusStar(
      id: '1',
      name: 'Timothy White',
      role: 'Student leader',
      photoUrl: '',
      club: 'Music',
      bio: '',
    ),
    CampusStar(
      id: '2',
      name: 'Anthony Clark',
      role: 'Student leader',
      photoUrl: '',
      club: 'Dance',
      bio: '',
    ),
    CampusStar(
      id: '3',
      name: 'James Morgan',
      role: 'Student leader',
      photoUrl: '',
      club: 'Theatre',
      bio: '',
    ),
  ];

  final List<CampusPost> _posts = [
    CampusPost(
      id: '1',
      authorName: 'Cynthia Hall',
      authorPhotoUrl: '',
      caption:
      'The 2019 Christmas and New Year party has started. New Year\'s eve party, wonderful.',
      mediaUrl: '',
      thumbnailUrl: '',
      mediaType: 'video',
      clubTag: 'Music',
      timeAgo: '5 minutes ago',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ClubsTab(
                  clubs: _clubs,
                  onAdd: _addClub,
                  onEdit: _editClub,
                  onDelete: _deleteClub,
                ),
                _StarsTab(
                  stars: _stars,
                  clubs: _clubs.map((c) => c.name).toList(),
                  onAdd: _addStar,
                  onEdit: _editStar,
                  onDelete: _deleteStar,
                ),
                _PostsTab(
                  posts: _posts,
                  clubs: _clubs.map((c) => c.name).toList(),
                  onAdd: _addPost,
                  onEdit: _editPost,
                  onDelete: _deletePost,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      // leading: IconButton(
      //   icon: Icon(Icons.arrow_back_ios_new,size: 20,), // Your custom icon
      //   onPressed: () {
      //     Navigator.pop(context); // Manually handle the back action
      //   },
      // ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.groups,
                color: Colors.blue[700], size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Clubs & Activities',
            style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      // We remove the internal padding so the indicator line touches the bottom
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: const BoxDecoration(
        color: Colors.transparent, // Transparent looks cleaner for line indicators
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1), // Optional: background bottom line
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,

        // ─── THE NEW INDICATOR STYLE ──────────────────────────
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 3.0,
            color: Colors.blue[700]!,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16.0), // Adjusts line length
        ),
        indicatorSize: TabBarIndicatorSize.label, // Line only as wide as the text/icon
        // ──────────────────────────────────────────────────────

        labelColor: Colors.blue[700], // Active color
        unselectedLabelColor: Colors.grey[500], // Inactive color
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),

        // Remove any splash/highlight for a very "flat" professional look
        overlayColor: WidgetStateProperty.all(Colors.transparent),

        tabs: const [
          Tab(
            child: Row(
              children: [
                Icon(Icons.group_outlined, size: 18),
                SizedBox(width: 8),
                Text('Clubs'),
              ],
            ),
          ),
          Tab(
            child: Row(
              children: [
                Icon(Icons.star_outline, size: 18),
                SizedBox(width: 8),
                Text('Campus stars'),
              ],
            ),
          ),
          Tab(
            child: Row(
              children: [
                Icon(Icons.videocam_outlined, size: 18),
                SizedBox(width: 8),
                Text('Posts'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ── CRUD placeholders – wire to your controllers ──

  void _addClub(ClubCategory club) =>
      setState(() => _clubs.add(club));
  void _editClub(ClubCategory club) {
    setState(() {
      final i = _clubs.indexWhere((c) => c.id == club.id);
      if (i >= 0) _clubs[i] = club;
    });
  }
  void _deleteClub(String id) =>
      setState(() => _clubs.removeWhere((c) => c.id == id));

  void _addStar(CampusStar star) =>
      setState(() => _stars.add(star));
  void _editStar(CampusStar star) {
    setState(() {
      final i = _stars.indexWhere((s) => s.id == star.id);
      if (i >= 0) _stars[i] = star;
    });
  }
  void _deleteStar(String id) =>
      setState(() => _stars.removeWhere((s) => s.id == id));

  void _addPost(CampusPost post) =>
      setState(() => _posts.add(post));
  void _editPost(CampusPost post) {
    setState(() {
      final i = _posts.indexWhere((p) => p.id == post.id);
      if (i >= 0) _posts[i] = post;
    });
  }
  void _deletePost(String id) =>
      setState(() => _posts.removeWhere((p) => p.id == id));
}

// ─── Shared helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  final String addLabel;

  const _SectionHeader({
    required this.title,
    required this.onAdd,
    required this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: Text(addLabel, style: const TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined,
                size: 18, color: Colors.blue[700]),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
                minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Colors.red),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
                minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

Widget _buildStyledInput(
    TextEditingController ctrl, String label, String hint,
    {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style:
          TextStyle(fontSize: 12, color: Colors.grey[700])),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(color: Colors.grey[400], fontSize: 13),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: Colors.blue.shade400, width: 1),
          ),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    ],
  );
}

Widget _buildStyledDropdown(
    String label, String value, List<String> items,
    ValueChanged<String?> onChanged) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style:
          TextStyle(fontSize: 12, color: Colors.grey[700])),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        hint: Text('Select…',
            style:
            TextStyle(color: Colors.grey[400], fontSize: 13)),
        items: items
            .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: const TextStyle(fontSize: 13))))
            .toList(),
        onChanged: onChanged,
        style: const TextStyle(
            fontSize: 13, color: Color(0xFF1A1A2E)),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        icon: Icon(Icons.keyboard_arrow_down,
            color: Colors.blue[700]),
      ),
    ],
  );
}

Widget _buildUrlPreviewBox(IconData icon, String hint) {
  return Container(
    height: 72,
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5,
          style: BorderStyle.solid),
    ),
    child: Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text(hint,
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    ),
  );
}

// ─── CLUBS TAB ────────────────────────────────────────────────────────────────

class _ClubsTab extends StatefulWidget {
  final List<ClubCategory> clubs;
  final void Function(ClubCategory) onAdd;
  final void Function(ClubCategory) onEdit;
  final void Function(String) onDelete;

  const _ClubsTab({
    required this.clubs,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ClubsTab> createState() => _ClubsTabState();
}

class _ClubsTabState extends State<_ClubsTab> {
  bool _showForm = false;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _bannerCtrl = TextEditingController();
  String? _editId;

  void _resetForm() {
    _nameCtrl.clear();
    _descCtrl.clear();
    _bannerCtrl.clear();
    _editId = null;
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final club = ClubCategory(
      id: _editId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      bannerUrl: _bannerCtrl.text.trim(),
      colorFrom: const Color(0xFF42A5F5),
      colorTo: const Color(0xFF26C6DA),
    );
    if (_editId != null) {
      widget.onEdit(club);
    } else {
      widget.onAdd(club);
    }
    setState(() => _showForm = false);
    _resetForm();
  }

  void _startEdit(ClubCategory club) {
    _nameCtrl.text = club.name;
    _descCtrl.text = club.description;
    _bannerCtrl.text = club.bannerUrl;
    _editId = club.id;
    setState(() => _showForm = true);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _SectionHeader(
          title: 'Club categories',
          addLabel: 'Add club',
          onAdd: () {
            _resetForm();
            setState(() => _showForm = !_showForm);
          },
        ),
        if (_showForm) _buildForm(),
        _buildList(),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editId != null ? 'Edit club' : 'New club',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 12),
          _buildStyledInput(_nameCtrl, 'Club name',
              'e.g. Music, Dance, Theatre…'),
          const SizedBox(height: 12),
          _buildStyledInput(_descCtrl, 'Description',
              'Brief description of the club…',
              maxLines: 3),
          const SizedBox(height: 12),
          _buildStyledInput(_bannerCtrl, 'Banner image URL',
              'https://…/image.jpg',
              keyboardType: TextInputType.url),
          const SizedBox(height: 8),
          _buildUrlPreviewBox(Icons.image_outlined, 'Image preview'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => _showForm = false);
                  _resetForm();
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(_editId != null ? 'Update club' : 'Save club'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (widget.clubs.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No clubs yet. Add one!',
                style: TextStyle(color: Colors.grey)),
          ));
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: widget.clubs
              .map(
                (c) => _ItemCard(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [c.colorFrom, c.colorTo]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.group_outlined,
                    color: Colors.white, size: 20),
              ),
              title: c.name,
              subtitle: c.description,
              onEdit: () => _startEdit(c),
              onDelete: () => widget.onDelete(c.id),
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}

// ─── CAMPUS STARS TAB ─────────────────────────────────────────────────────────

class _StarsTab extends StatefulWidget {
  final List<CampusStar> stars;
  final List<String> clubs;
  final void Function(CampusStar) onAdd;
  final void Function(CampusStar) onEdit;
  final void Function(String) onDelete;

  const _StarsTab({
    required this.stars,
    required this.clubs,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_StarsTab> createState() => _StarsTabState();
}

class _StarsTabState extends State<_StarsTab> {
  bool _showForm = false;
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String _selectedClub = '';
  String? _editId;

  void _resetForm() {
    _nameCtrl.clear();
    _roleCtrl.clear();
    _photoCtrl.clear();
    _bioCtrl.clear();
    _selectedClub = '';
    _editId = null;
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final star = CampusStar(
      id: _editId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      role: _roleCtrl.text.trim(),
      photoUrl: _photoCtrl.text.trim(),
      club: _selectedClub,
      bio: _bioCtrl.text.trim(),
    );
    if (_editId != null) {
      widget.onEdit(star);
    } else {
      widget.onAdd(star);
    }
    setState(() => _showForm = false);
    _resetForm();
  }

  void _startEdit(CampusStar s) {
    _nameCtrl.text = s.name;
    _roleCtrl.text = s.role;
    _photoCtrl.text = s.photoUrl;
    _bioCtrl.text = s.bio;
    _selectedClub = s.club;
    _editId = s.id;
    setState(() => _showForm = true);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _SectionHeader(
          title: 'Campus stars',
          addLabel: 'Add star',
          onAdd: () {
            _resetForm();
            setState(() => _showForm = !_showForm);
          },
        ),
        if (_showForm) _buildForm(),
        _buildList(),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editId != null ? 'Edit star' : 'New campus star',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 12),
          _buildStyledInput(
              _nameCtrl, 'Full name', 'e.g. Timothy White'),
          const SizedBox(height: 12),
          _buildStyledInput(
              _roleCtrl, 'Role / Title', 'e.g. Student leader'),
          const SizedBox(height: 12),
          _buildStyledInput(
              _photoCtrl, 'Profile photo URL', 'https://…/photo.jpg',
              keyboardType: TextInputType.url),
          const SizedBox(height: 8),
          _buildUrlPreviewBox(
              Icons.account_circle_outlined, 'Photo preview'),
          const SizedBox(height: 12),
          _buildStyledDropdown(
            'Club / Category',
            _selectedClub,
            widget.clubs,
                (v) => setState(() => _selectedClub = v ?? ''),
          ),
          const SizedBox(height: 12),
          _buildStyledInput(
              _bioCtrl, 'Bio (optional)', 'Short bio…',
              maxLines: 3),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => _showForm = false);
                  _resetForm();
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(_editId != null ? 'Update star' : 'Save star'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (widget.stars.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No campus stars yet. Add one!',
                style: TextStyle(color: Colors.grey)),
          ));
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: widget.stars
              .map(
                (s) => _ItemCard(
              leading: s.photoUrl.isNotEmpty
                  ? CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(s.photoUrl),
              )
                  : CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  _initials(s.name),
                  style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              title: s.name,
              subtitle: '${s.role} · ${s.club}',
              onEdit: () => _startEdit(s),
              onDelete: () => widget.onDelete(s.id),
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}

// ─── POSTS TAB ────────────────────────────────────────────────────────────────

class _PostsTab extends StatefulWidget {
  final List<CampusPost> posts;
  final List<String> clubs;
  final void Function(CampusPost) onAdd;
  final void Function(CampusPost) onEdit;
  final void Function(String) onDelete;

  const _PostsTab({
    required this.posts,
    required this.clubs,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  bool _showForm = false;
  final _authorCtrl = TextEditingController();
  final _authorPhotoCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  final _mediaCtrl = TextEditingController();
  final _thumbCtrl = TextEditingController();
  String _mediaType = 'video';
  String _selectedClub = '';
  String? _editId;

  void _resetForm() {
    _authorCtrl.clear();
    _authorPhotoCtrl.clear();
    _captionCtrl.clear();
    _mediaCtrl.clear();
    _thumbCtrl.clear();
    _mediaType = 'video';
    _selectedClub = '';
    _editId = null;
  }

  void _submit() {
    if (_authorCtrl.text.trim().isEmpty) return;
    final post = CampusPost(
      id: _editId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: _authorCtrl.text.trim(),
      authorPhotoUrl: _authorPhotoCtrl.text.trim(),
      caption: _captionCtrl.text.trim(),
      mediaUrl: _mediaCtrl.text.trim(),
      thumbnailUrl: _thumbCtrl.text.trim(),
      mediaType: _mediaType,
      clubTag: _selectedClub,
      timeAgo: 'Just now',
    );
    if (_editId != null) {
      widget.onEdit(post);
    } else {
      widget.onAdd(post);
    }
    setState(() => _showForm = false);
    _resetForm();
  }

  void _startEdit(CampusPost p) {
    _authorCtrl.text = p.authorName;
    _authorPhotoCtrl.text = p.authorPhotoUrl;
    _captionCtrl.text = p.caption;
    _mediaCtrl.text = p.mediaUrl;
    _thumbCtrl.text = p.thumbnailUrl;
    _mediaType = p.mediaType;
    _selectedClub = p.clubTag;
    _editId = p.id;
    setState(() => _showForm = true);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _SectionHeader(
          title: 'Campus posts',
          addLabel: 'Add post',
          onAdd: () {
            _resetForm();
            setState(() => _showForm = !_showForm);
          },
        ),
        if (_showForm) _buildForm(),
        _buildList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editId != null ? 'Edit post' : 'New post',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 12),
          _buildStyledInput(
              _authorCtrl, 'Author name', 'e.g. Cynthia Hall'),
          const SizedBox(height: 12),
          _buildStyledInput(_authorPhotoCtrl, 'Author photo URL',
              'https://…/avatar.jpg',
              keyboardType: TextInputType.url),
          const SizedBox(height: 12),
          _buildStyledInput(_captionCtrl, 'Post caption / text',
              'Write something about the event…',
              maxLines: 3),
          const SizedBox(height: 12),
          // Media type toggle
          Text('Media type',
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _mediaType = 'image'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _mediaType == 'image'
                          ? Colors.blue[700]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined,
                            size: 16,
                            color: _mediaType == 'image'
                                ? Colors.white
                                : Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text('Image',
                            style: TextStyle(
                                fontSize: 13,
                                color: _mediaType == 'image'
                                    ? Colors.white
                                    : Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _mediaType = 'video'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _mediaType == 'video'
                          ? Colors.blue[700]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_outlined,
                            size: 16,
                            color: _mediaType == 'video'
                                ? Colors.white
                                : Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text('Video',
                            style: TextStyle(
                                fontSize: 13,
                                color: _mediaType == 'video'
                                    ? Colors.white
                                    : Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStyledInput(
            _mediaCtrl,
            _mediaType == 'video' ? 'Video URL' : 'Image URL',
            _mediaType == 'video'
                ? 'https://…/video.mp4 or YouTube link'
                : 'https://…/image.jpg',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          _buildStyledInput(_thumbCtrl, 'Thumbnail image URL',
              'https://…/thumb.jpg',
              keyboardType: TextInputType.url),
          const SizedBox(height: 8),
          _buildUrlPreviewBox(
              Icons.play_circle_outline, 'Thumbnail preview'),
          const SizedBox(height: 12),
          _buildStyledDropdown(
            'Club tag',
            _selectedClub,
            widget.clubs,
                (v) => setState(() => _selectedClub = v ?? ''),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => _showForm = false);
                  _resetForm();
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                    _editId != null ? 'Update post' : 'Publish post'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (widget.posts.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No posts yet. Add one!',
                style: TextStyle(color: Colors.grey)),
          ));
    }
    return Column(
      children: widget.posts
          .map(
            (p) => Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    p.authorPhotoUrl.isNotEmpty
                        ? CircleAvatar(
                      radius: 18,
                      backgroundImage:
                      NetworkImage(p.authorPhotoUrl),
                    )
                        : CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.pink.shade100,
                      child: Text(
                        _initials(p.authorName),
                        style: TextStyle(
                            color: Colors.pink[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.authorName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          Text(p.timeAgo,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    // Club tag
                    if (p.clubTag.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(p.clubTag,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[700])),
                      ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          size: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete',
                                style:
                                TextStyle(color: Colors.red)),
                          ]),
                        ),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') _startEdit(p);
                        if (v == 'delete') widget.onDelete(p.id);
                      },
                    ),
                  ],
                ),
              ),
              // Caption
              if (p.caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Text(p.caption,
                      style: const TextStyle(
                          fontSize: 13, height: 1.5)),
                ),
              // Media thumbnail
              if (p.thumbnailUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(p.thumbnailUrl,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: Colors.grey.shade200,
                          )),
                      if (p.mediaType == 'video')
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 28),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  margin:
                  const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          p.mediaType == 'video'
                              ? Icons.play_circle_outline
                              : Icons.image_outlined,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          p.mediaType == 'video'
                              ? 'Video attached'
                              : 'Image attached',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}