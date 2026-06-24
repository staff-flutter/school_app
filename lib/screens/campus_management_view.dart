import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../constants/api_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/school_controller.dart';
import '../services/user_session.dart';


// ─── Role helper ─────────────────────────────────────────────────────────────

bool _canEdit(String role) =>
    role == 'correspondent' || role == 'administrator';

// ─── Logging helper ──────────────────────────────────────────────────────────
// Centralized so every club/video API call logs the same way.
// Truncates long bodies (e.g. base64-ish / huge JSON) so logs stay readable.

void _logRequest(String method, Uri uri, {Map<String, String>? fields}) {
  debugPrint('▶️ [CLUB API] $method $uri'
      '${fields != null ? '\n   fields: $fields' : ''}');
}

void _logResponse(String method, Uri uri, http.Response res) {
  final body = res.body.length > 1200 ? '${res.body.substring(0, 1200)}…(truncated)' : res.body;
  debugPrint('◀️ [CLUB API] $method $uri -> ${res.statusCode}\n   body: $body');
}

void _logError(String method, Uri uri, Object e) {
  debugPrint('❌ [CLUB API] $method $uri -> ERROR: $e');
}


// ═════════════════════════════════════════════════════════════════════════════
//  MODELS
// ═════════════════════════════════════════════════════════════════════════════

class ClubCategory {
  final String  id;
  final String  name;
  final String  description;
  final String? thumbnailUrl;
  final bool    isActive;

  const ClubCategory({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnailUrl,
    required this.isActive,
  });

  factory ClubCategory.fromJson(Map<String, dynamic> j) => ClubCategory(
    id:           j['_id']         ?? '',
    name:         j['name']        ?? '',
    description:  j['description'] ?? '',
    thumbnailUrl: j['thumbnail'] is Map
        ? j['thumbnail']['url']
        : j['thumbnail'],
    isActive:     j['isActive']    ?? true,
  );
}

class ClubVideo {
  final String id;
  final String title;
  final String topic;
  final String level;
  final String academicYear;
  final String videoUrl;
  final String originalName;
  final List<Map<String, String>> pdfs;

  const ClubVideo({
    required this.id,
    required this.title,
    required this.topic,
    required this.level,
    required this.academicYear,
    required this.videoUrl,
    required this.originalName,
    required this.pdfs,
  });

  factory ClubVideo.fromJson(Map<String, dynamic> j) {
    final v = j['video'] as Map<String, dynamic>? ?? {};
    return ClubVideo(
      id:           j['_id']          ?? '',
      title:        j['title']        ?? '',
      topic:        j['topic']        ?? '',
      level:        j['level']        ?? 'general',
      academicYear: j['academicYear'] ?? '',
      videoUrl:     v['url']          ?? '',
      originalName: v['originalName'] ?? '',
      pdfs: (j['pdfs'] as List? ?? []).map((p) => {
        'id':  (p['_id']          ?? '') as String,
        'url': (p['url']          ?? '') as String,
        'name':(p['originalName'] ?? '') as String,
      }).toList(),
    );
  }
}

// Dummy models (APIs not ready)
class CampusStar {
  String id, name, role, photoUrl, club, bio;
  CampusStar({required this.id, required this.name, required this.role,
    required this.photoUrl, required this.club, required this.bio});
}

class CampusPost {
  String id, authorName, authorPhotoUrl, caption,
      mediaUrl, thumbnailUrl, mediaType, clubTag, timeAgo;
  CampusPost({required this.id, required this.authorName,
    required this.authorPhotoUrl, required this.caption,
    required this.mediaUrl, required this.thumbnailUrl,
    required this.mediaType, required this.clubTag, required this.timeAgo});
}


// ═════════════════════════════════════════════════════════════════════════════
//  ROOT VIEW
// ═════════════════════════════════════════════════════════════════════════════

class CampusManagementView extends StatefulWidget {
  const CampusManagementView({super.key});

  @override
  State<CampusManagementView> createState() => _CampusManagementViewState();
}

class _CampusManagementViewState extends State<CampusManagementView>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  final _auth    = Get.find<AuthController>();
  final _session = Get.find<UserSession>();
  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;

  String get _role  => _auth.user.value?.role?.toLowerCase() ?? '';
  String? get _schoolId {
    if (_role == 'correspondent') return _school?.selectedSchool.value?.id;
    return _session.schoolId ?? _auth.user.value?.schoolId;
  }
  String? get _token => _session.token;
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
  };

  // ── Club state ──
  List<ClubCategory> _clubs        = [];
  bool               _clubsLoading = true;
  int                _clubPage     = 1;
  int                _clubTotal    = 1;

  // ── Dummy data ──
  final List<CampusStar> _stars = [
    CampusStar(id:'1', name:'Timothy White', role:'Student leader', photoUrl:'', club:'Music', bio:''),
    CampusStar(id:'2', name:'Anthony Clark', role:'Student leader', photoUrl:'', club:'Dance',  bio:''),
  ];
  final List<CampusPost> _posts = [
    CampusPost(id:'1', authorName:'Cynthia Hall', authorPhotoUrl:'',
        caption:'The 2019 Christmas and New Year party has started.',
        mediaUrl:'', thumbnailUrl:'', mediaType:'video', clubTag:'Music', timeAgo:'5 min ago'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchClubs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── API: clubs ────────────────────────────────────────────────────────────

  Future<void> _fetchClubs({int page = 1}) async {
    if (_schoolId == null) {
      debugPrint('⚠️ [CLUB API] GET getAllClubs skipped — schoolId is null');
      setState(() => _clubsLoading = false);
      return;
    }
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllClubs}')
        .replace(queryParameters: {'schoolId': _schoolId!, 'page': '$page', 'limit': '20'});
    _logRequest('GET', uri);
    try {
      final res = await http.get(uri, headers: _headers);
      _logResponse('GET', uri, res);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] as List).map((e) => ClubCategory.fromJson(e)).toList();
        final pg   = body['pagination'];
        setState(() {
          _clubs      = page == 1 ? list : [..._clubs, ...list];
          _clubPage   = page;
          _clubTotal  = pg['totalPages'] ?? 1;
          _clubsLoading = false;
        });
      } else {
        setState(() => _clubsLoading = false);
      }
    } catch (e) {
      _logError('GET', uri, e);
      setState(() => _clubsLoading = false);
    }
  }

  Future<void> _createClub(String name, String desc, dynamic thumb) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createClub}');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..fields['name']        = name
      ..fields['description'] = desc
      ..fields['schoolId']    = _schoolId!;
    if (thumb != null) {
      req.files.add(await http.MultipartFile.fromPath('thumbnail', thumb.path,
          contentType: MediaType('image', _ext(thumb.path))));
    }
    _logRequest('POST', uri, fields: req.fields);
    try {
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      _logResponse('POST', uri, res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack('Club created', success: true);
        setState(() { _clubs = []; _clubsLoading = true; });
        _fetchClubs();
      } else {
        _snack('Failed: ${_msg(res)}');
      }
    } catch (e) {
      _logError('POST', uri, e);
      _snack('Error: $e');
    }
  }

  Future<void> _updateClubText(ClubCategory c, String name, String desc, bool active) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateClubText}/${c.id}');
    final payload = {'name': name, 'description': desc, 'isActive': active};
    _logRequest('PUT', uri, fields: payload.map((k, v) => MapEntry(k, '$v')));
    try {
      final res = await http.put(uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      _logResponse('PUT', uri, res);
      if (res.statusCode == 200) {
        _snack('Club updated', success: true);
        setState(() { _clubs = []; _clubsLoading = true; });
        _fetchClubs();
      } else {
        _snack('Failed: ${_msg(res)}');
      }
    } catch (e) {
      _logError('PUT', uri, e);
      _snack('Error: $e');
    }
  }

  Future<void> _updateClubThumbnail(ClubCategory c, dynamic thumb) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateClubThumbnail}/${c.id}');
    final req = http.MultipartRequest('PUT', uri)
      ..headers.addAll(_headers)
      ..files.add(await http.MultipartFile.fromPath('thumbnail', thumb.path,
          contentType: MediaType('image', _ext(thumb.path))));
    _logRequest('PUT', uri, fields: {'thumbnail': thumb.path});
    try {
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      _logResponse('PUT', uri, res);
      if (res.statusCode != 200) _snack('Thumbnail update failed: ${_msg(res)}');
    } catch (e) {
      _logError('PUT', uri, e);
      _snack('Error: $e');
    }
  }

  Future<void> _deleteClub(ClubCategory c) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteClub}/${c.id}');
    _logRequest('DELETE', uri);
    try {
      final res = await http.delete(uri, headers: _headers);
      _logResponse('DELETE', uri, res);
      if (res.statusCode == 200) {
        _snack('Club deleted', success: true);
        setState(() => _clubs.removeWhere((x) => x.id == c.id));
      } else {
        _snack('Failed: ${_msg(res)}');
      }
    } catch (e) {
      _logError('DELETE', uri, e);
      _snack('Error: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _ext(String path) => path.split('.').last.toLowerCase();
  String _msg(http.Response r) {
    try { return jsonDecode(r.body)['message'] ?? '${r.statusCode}'; } catch (_) { return '${r.statusCode}'; }
  }
  void _snack(String msg, {bool success = false}) {
    Get.snackbar(success ? 'Success' : 'Error', msg,
      backgroundColor: success ? const Color(0xFF22C55E) : Colors.redAccent,
      colorText: Colors.white, snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12), borderRadius: 12,
    );
  }
  void _confirm(String msg, VoidCallback onConfirm) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () { Get.back(); onConfirm(); },
          child: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

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
                  isLoading: _clubsLoading,
                  canEdit: _canEdit(_role),
                  hasMore: _clubPage < _clubTotal,
                  onLoadMore: () => _fetchClubs(page: _clubPage + 1),
                  onTapClub: (club) => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _ClubVideosScreen(
                      club: club,
                      token: _token ?? '',
                      schoolId: _schoolId ?? '',
                      canEdit: _canEdit(_role),
                    ),
                  )),
                  onCreate: (name, desc, thumb) => _createClub(name, desc, thumb),
                  onEdit: (c, name, desc, active, thumb) async {
                    if (thumb != null) await _updateClubThumbnail(c, thumb);
                    await _updateClubText(c, name, desc, active);
                  },
                  onDelete: (c) => _confirm('Delete "${c.name}"?', () => _deleteClub(c)),
                ),
                _StarsTab(stars: _stars, clubs: _clubs.map((c) => c.name).toList(),
                  onAdd: (s) => setState(() => _stars.add(s)),
                  onEdit: (s) { final i = _stars.indexWhere((x) => x.id == s.id); if (i >= 0) setState(() => _stars[i] = s); },
                  onDelete: (id) => setState(() => _stars.removeWhere((s) => s.id == id)),
                ),
                _PostsTab(posts: _posts, clubs: _clubs.map((c) => c.name).toList(),
                  onAdd: (p) => setState(() => _posts.add(p)),
                  onEdit: (p) { final i = _posts.indexWhere((x) => x.id == p.id); if (i >= 0) setState(() => _posts[i] = p); },
                  onDelete: (id) => setState(() => _posts.removeWhere((p) => p.id == id)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.groups, color: Colors.blue[700], size: 20),
      ),
      const SizedBox(width: 12),
      const Text('Clubs & Activities',
          style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 17, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _buildTabBar() => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
    ),
    child: TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 3, color: Colors.blue[700]!),
        insets: const EdgeInsets.symmetric(horizontal: 16),
      ),
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: Colors.blue[700],
      unselectedLabelColor: Colors.grey[500],
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabs: const [
        Tab(child: Row(children: [Icon(Icons.group_outlined, size: 18), SizedBox(width: 8), Text('Clubs')])),
        Tab(child: Row(children: [Icon(Icons.star_outline,   size: 18), SizedBox(width: 8), Text('Campus stars')])),
        Tab(child: Row(children: [Icon(Icons.videocam_outlined, size: 18), SizedBox(width: 8), Text('Posts')])),
      ],
    ),
  );
}


// ═════════════════════════════════════════════════════════════════════════════
//  CLUBS TAB
// ═════════════════════════════════════════════════════════════════════════════

class _ClubsTab extends StatefulWidget {
  final List<ClubCategory> clubs;
  final bool isLoading;
  final bool canEdit;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final void Function(ClubCategory) onTapClub;
  final Future<void> Function(String name, String desc, dynamic thumb) onCreate;
  final Future<void> Function(ClubCategory, String name, String desc, bool active, dynamic thumb) onEdit;
  final void Function(ClubCategory) onDelete;

  const _ClubsTab({
    required this.clubs, required this.isLoading, required this.canEdit,
    required this.hasMore, required this.onLoadMore, required this.onTapClub,
    required this.onCreate, required this.onEdit, required this.onDelete,
  });

  @override
  State<_ClubsTab> createState() => _ClubsTabState();
}

class _ClubsTabState extends State<_ClubsTab> {
  bool _showForm = false;
  ClubCategory? _editTarget;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool  _isActive = true;
  dynamic _pickedThumb; // XFile

  void _resetForm() {
    _nameCtrl.clear(); _descCtrl.clear();
    _isActive = true; _pickedThumb = null; _editTarget = null;
  }

  void _startEdit(ClubCategory c) {
    _nameCtrl.text = c.name;
    _descCtrl.text = c.description;
    _isActive      = c.isActive;
    _pickedThumb   = null;
    _editTarget    = c;
    setState(() => _showForm = true);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    if (_editTarget != null) {
      await widget.onEdit(_editTarget!, _nameCtrl.text.trim(), _descCtrl.text.trim(), _isActive, _pickedThumb);
    } else {
      await widget.onCreate(_nameCtrl.text.trim(), _descCtrl.text.trim(), _pickedThumb);
    }
    setState(() { _showForm = false; _resetForm(); });
  }

  Future<void> _pickThumb() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => _pickedThumb = f);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _SectionHeader(
          title: 'Club categories',
          addLabel: 'Add club',
          showAdd: widget.canEdit,
          onAdd: () { _resetForm(); setState(() => _showForm = !_showForm); },
        ),
        if (_showForm && widget.canEdit) _buildForm(),
        if (widget.isLoading)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
        else if (widget.clubs.isEmpty)
          const _EmptyState(message: 'No clubs yet. Add one!', icon: Icons.groups_outlined)
        else
          _buildList(),
        if (widget.hasMore)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TextButton(onPressed: widget.onLoadMore,
                child: Text('Load more', style: TextStyle(color: Colors.blue[700], fontSize: 13))),
          )),
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
      child: StatefulBuilder(builder: (ctx, setS) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_editTarget != null ? 'Edit club' : 'New club',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _StyledInput(ctrl: _nameCtrl, label: 'Club name', hint: 'e.g. Music, Dance…'),
          const SizedBox(height: 12),
          _StyledInput(ctrl: _descCtrl, label: 'Description', hint: 'Brief description…', maxLines: 3),
          const SizedBox(height: 12),
          // Thumbnail picker (phone only)
          _ImagePickerTile(
            label: 'Thumbnail',
            pickedFile: _pickedThumb,
            existingUrl: _editTarget?.thumbnailUrl,
            onPick: () async {
              final f = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (f != null) setS(() => _pickedThumb = f);
            },
          ),
          if (_editTarget != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Text('Active', style: TextStyle(fontSize: 13)),
              const Spacer(),
              Switch(
                value: _isActive,
                onChanged: (v) => setS(() => _isActive = v),
                activeColor: Colors.blue[700],
              ),
            ]),
          ],
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () { setState(() { _showForm = false; _resetForm(); }); },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700], foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
              ),
              child: Text(_editTarget != null ? 'Update club' : 'Save club', style: const TextStyle(fontSize: 13)),
            ),
          ]),
        ],
      )),
    );
  }

  Widget _buildList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: widget.clubs.map((c) => _ClubListTile(
            club: c,
            canEdit: widget.canEdit,
            onTap: () => widget.onTapClub(c),
            onEdit: () => _startEdit(c),
            onDelete: () => widget.onDelete(c),
          )).toList(),
        ),
      ),
    );
  }
}

class _ClubListTile extends StatelessWidget {
  final ClubCategory club;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClubListTile({
    required this.club, required this.canEdit,
    required this.onTap, required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
        ),
        child: Row(children: [
          // Gradient icon / thumbnail
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF26C6DA)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: club.thumbnailUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(club.thumbnailUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.groups, color: Colors.white, size: 20)),
            )
                : const Icon(Icons.groups, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(child: Text(club.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                    overflow: TextOverflow.ellipsis)),
                if (!club.isActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Inactive', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                ],
              ]),
              if (club.description.isNotEmpty)
                Text(club.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          // Videos arrow — always visible
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          if (canEdit) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: Colors.blue[700]),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ]),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
//  CLUB VIDEOS SCREEN  (full screen opened on club tap)
// ═════════════════════════════════════════════════════════════════════════════

class _ClubVideosScreen extends StatefulWidget {
  final ClubCategory club;
  final String token;
  final String schoolId;
  final bool canEdit;

  const _ClubVideosScreen({
    required this.club, required this.token,
    required this.schoolId, required this.canEdit,
  });

  @override
  State<_ClubVideosScreen> createState() => _ClubVideosScreenState();
}

class _ClubVideosScreenState extends State<_ClubVideosScreen> {

  List<ClubVideo> _videos      = [];
  bool            _loading     = true;
  int             _page        = 1;
  int             _totalPages  = 1;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.token}',
    'Accept': 'application/json',
  };

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos({int page = 1}) async {
    setState(() => _loading = true);
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllClubVideos}')
        .replace(queryParameters: {'clubId': widget.club.id, 'page': '$page', 'limit': '20'});
    _logRequest('GET', uri);
    try {
      final res = await http.get(uri, headers: _headers);
      _logResponse('GET', uri, res);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] as List).map((e) => ClubVideo.fromJson(e)).toList();
        final pg   = body['pagination'];
        setState(() {
          _videos     = page == 1 ? list : [..._videos, ...list];
          _page       = page;
          _totalPages = pg['totalPages'] ?? 1;
          _loading    = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      _logError('GET', uri, e);
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadVideo({
    required String title, required String topic,
    required String level, required String academicYear, required dynamic videoFile,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadClubVideo}');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..fields['schoolId']     = widget.schoolId
      ..fields['clubId']       = widget.club.id
      ..fields['title']        = title
      ..fields['topic']        = topic
      ..fields['level']        = level
      ..fields['academicYear'] = academicYear;
    req.files.add(await http.MultipartFile.fromPath('video', videoFile.path,
        contentType: MediaType('video', _ext(videoFile.path))));
    _logRequest('POST', uri, fields: {...req.fields, 'video': videoFile.path});
    try {
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      _logResponse('POST', uri, res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack('Video uploaded', success: true);
        _fetchVideos();
      } else {
        _snack('Failed: ${_msg(res)}');
      }
    } catch (e) {
      _logError('POST', uri, e);
      _snack('Error: $e');
    }
  }

  Future<void> _updateVideoDetails(ClubVideo v, String title, String topic, String level, String year) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateClubVideoDetails}/${v.id}');
    final payload = {'title': title, 'topic': topic, 'level': level, 'academicYear': year};
    _logRequest('PUT', uri, fields: payload);
    try {
      final res = await http.put(uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      _logResponse('PUT', uri, res);
      if (res.statusCode == 200) { _snack('Updated', success: true); _fetchVideos(); }
      else _snack('Failed: ${_msg(res)}');
    } catch (e) {
      _logError('PUT', uri, e);
      _snack('Error: $e');
    }
  }

  Future<void> _replaceVideoFile(ClubVideo v, dynamic file) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateClubVideoFile}/${v.id}');
    final req = http.MultipartRequest('PUT', uri)
      ..headers.addAll(_headers)
      ..files.add(await http.MultipartFile.fromPath('video', file.path,
          contentType: MediaType('video', _ext(file.path))));
    _logRequest('PUT', uri, fields: {'video': file.path});
    try {
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      _logResponse('PUT', uri, res);
      if (res.statusCode == 200) { _snack('Video replaced', success: true); _fetchVideos(); }
      else _snack('Failed: ${_msg(res)}');
    } catch (e) {
      _logError('PUT', uri, e);
      _snack('Error: $e');
    }
  }

  Future<void> _deleteVideo(ClubVideo v) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteClubVideo}/${v.id}');
    _logRequest('DELETE', uri);
    try {
      final res = await http.delete(uri, headers: _headers);
      _logResponse('DELETE', uri, res);
      if (res.statusCode == 200) {
        _snack('Deleted', success: true);
        setState(() => _videos.removeWhere((x) => x.id == v.id));
      } else {
        _snack('Failed: ${_msg(res)}');
      }
    } catch (e) {
      _logError('DELETE', uri, e);
      _snack('Error: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _ext(String path) => path.split('.').last.toLowerCase();
  String _msg(http.Response r) {
    try { return jsonDecode(r.body)['message'] ?? '${r.statusCode}'; } catch (_) { return '${r.statusCode}'; }
  }
  void _snack(String msg, {bool success = false}) {
    Get.snackbar(success ? 'Success' : 'Error', msg,
      backgroundColor: success ? const Color(0xFF22C55E) : Colors.redAccent,
      colorText: Colors.white, snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12), borderRadius: 12,
    );
  }
  void _confirm(String msg, VoidCallback onConfirm) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () { Get.back(); onConfirm(); },
          child: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    ));
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showUploadDialog() {
    final titleCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final yearCtrl  = TextEditingController(text: '2025-2026');
    String level    = 'general';
    dynamic videoFile;
    const levels = ['general', 'beginner', 'intermediate', 'advanced'];

    Get.dialog(StatefulBuilder(builder: (ctx, setS) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Upload video', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _StyledInput(ctrl: titleCtrl, label: 'Title', hint: 'Video title'),
          const SizedBox(height: 10),
          _StyledInput(ctrl: topicCtrl, label: 'Topic', hint: 'e.g. Aerodynamics'),
          const SizedBox(height: 10),
          _StyledInput(ctrl: yearCtrl, label: 'Academic year', hint: '2025-2026'),
          const SizedBox(height: 10),
          _StyledDropdown(
            label: 'Level', value: level, items: levels,
            onChanged: (v) => setS(() => level = v!),
          ),
          const SizedBox(height: 10),
          // Video picker from phone
          _VideoPickerTile(
            pickedFile: videoFile,
            onPick: () async {
              final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
              if (f != null) setS(() => videoFile = f);
            },
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || videoFile == null) return;
                Get.back();
                await _uploadVideo(title: titleCtrl.text.trim(), topic: topicCtrl.text.trim(),
                    level: level, academicYear: yearCtrl.text.trim(), videoFile: videoFile);
              },
              child: const Text('Upload', style: TextStyle(fontSize: 13)),
            ),
          ]),
        ]),
      ),
    )));
  }

  void _showEditDialog(ClubVideo v) {
    final titleCtrl = TextEditingController(text: v.title);
    final topicCtrl = TextEditingController(text: v.topic);
    final yearCtrl  = TextEditingController(text: v.academicYear);
    String level    = v.level;
    const levels    = ['general', 'beginner', 'intermediate', 'advanced'];

    Get.dialog(StatefulBuilder(builder: (ctx, setS) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Edit video', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _StyledInput(ctrl: titleCtrl, label: 'Title', hint: 'Video title'),
          const SizedBox(height: 10),
          _StyledInput(ctrl: topicCtrl, label: 'Topic', hint: 'Topic'),
          const SizedBox(height: 10),
          _StyledInput(ctrl: yearCtrl, label: 'Academic year', hint: '2025-2026'),
          const SizedBox(height: 10),
          _StyledDropdown(label: 'Level', value: level, items: levels,
              onChanged: (v) => setS(() => level = v!)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Get.back();
                _updateVideoDetails(v, titleCtrl.text.trim(), topicCtrl.text.trim(), level, yearCtrl.text.trim());
              },
              child: const Text('Save', style: TextStyle(fontSize: 13)),
            ),
          ]),
        ]),
      ),
    )));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.club.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            if (widget.club.description.isNotEmpty)
              Text(widget.club.description,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          if (widget.canEdit)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: _showUploadDialog,
                icon: const Icon(Icons.upload, size: 15),
                label: const Text('Upload', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700], foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
          ? const _EmptyState(message: 'No videos uploaded yet.', icon: Icons.videocam_off_outlined)
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _videos.length + (_page < _totalPages ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == _videos.length) {
            return Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextButton(
                onPressed: () => _fetchVideos(page: _page + 1),
                child: Text('Load more', style: TextStyle(color: Colors.blue[700], fontSize: 13)),
              ),
            ));
          }
          return _VideoCard(
            video: _videos[i],
            canEdit: widget.canEdit,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => _VideoPlayerScreen(video: _videos[i]),
            )),
            onEdit: () => _showEditDialog(_videos[i]),
            onReplaceFile: () async {
              final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
              if (f != null) _replaceVideoFile(_videos[i], f);
            },
            onDelete: () => _confirm('Delete "${_videos[i].title}"?', () => _deleteVideo(_videos[i])),
          );
        },
      ),
    );
  }
}


// ─── Video card ───────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final ClubVideo video;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onReplaceFile;
  final VoidCallback onDelete;

  const _VideoCard({
    required this.video, required this.canEdit, required this.onTap,
    required this.onEdit, required this.onReplaceFile, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Play icon area
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF26C6DA)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), bottomLeft: Radius.circular(16),
              ),
            ),
            child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(video.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(video.topic, style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                _LevelChip(video.level),
                const SizedBox(width: 8),
                Text(video.academicYear, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ]),
            ]),
          )),
          if (canEdit)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'edit')    onEdit();
                if (val == 'replace') onReplaceFile();
                if (val == 'delete')  onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit',    child: _PopupRow(Icons.edit_outlined,    'Edit details')),
                PopupMenuItem(value: 'replace', child: _PopupRow(Icons.upload_file,       'Replace file')),
                PopupMenuItem(value: 'delete',  child: _PopupRow(Icons.delete_outline,    'Delete', isDestructive: true)),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ),
        ]),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
//  VIDEO PLAYER SCREEN  (full screen)
// ═════════════════════════════════════════════════════════════════════════════

class _VideoPlayerScreen extends StatefulWidget {
  final ClubVideo video;
  const _VideoPlayerScreen({required this.video});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _ctrl;
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    debugPrint('▶️ [CLUB VIDEO PLAYER] loading ${widget.video.videoUrl}');
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));
    _initFuture = _ctrl.initialize().then((_) {
      debugPrint('✅ [CLUB VIDEO PLAYER] initialized — duration: ${_ctrl.value.duration}');
      _ctrl.play();
    }).catchError((e) {
      debugPrint('❌ [CLUB VIDEO PLAYER] failed to initialize: $e');
    });
    _ctrl.setLooping(false);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.video.title,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        // Video player
        FutureBuilder(
          future: _initFuture,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const AspectRatio(aspectRatio: 16/9,
                  child: Center(child: CircularProgressIndicator(color: Colors.white)));
            }
            return GestureDetector(
              onTap: () {
                if (_ctrl.value.isPlaying) {
                  _ctrl.pause();
                } else {
                  _ctrl.play();
                }
                // No setState needed here — ValueListenableBuilder below
                // already rebuilds the play/pause overlay off _ctrl's own
                // notifications. Calling setState with an async closure is
                // what caused the "returned a Future" FlutterError.
              },
              child: Stack(alignment: Alignment.center, children: [
                AspectRatio(aspectRatio: _ctrl.value.aspectRatio, child: VideoPlayer(_ctrl)),
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _ctrl,
                  builder: (_, val, __) => AnimatedOpacity(
                    opacity: val.isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                    ),
                  ),
                ),
                // Progress bar
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: VideoProgressIndicator(_ctrl, allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF42A5F5),
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
        // Metadata
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.video.title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              _LevelChip(widget.video.level),
              const SizedBox(width: 10),
              Text(widget.video.academicYear,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            Text('Topic: ${widget.video.topic}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (widget.video.pdfs.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Attachments', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...widget.video.pdfs.map((pdf) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(pdf['name'] ?? 'PDF',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis)),
                ]),
              )),
            ],
          ]),
        )),
      ]),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
//  CAMPUS STARS TAB  (dummy — APIs not ready)
// ═════════════════════════════════════════════════════════════════════════════

class _StarsTab extends StatefulWidget {
  final List<CampusStar> stars;
  final List<String> clubs;
  final void Function(CampusStar) onAdd;
  final void Function(CampusStar) onEdit;
  final void Function(String) onDelete;

  const _StarsTab({required this.stars, required this.clubs,
    required this.onAdd, required this.onEdit, required this.onDelete});

  @override
  State<_StarsTab> createState() => _StarsTabState();
}

class _StarsTabState extends State<_StarsTab> {
  bool _showForm = false;
  final _nameCtrl  = TextEditingController();
  final _roleCtrl  = TextEditingController();
  final _bioCtrl   = TextEditingController();
  String _selectedClub = '';
  String? _editId;
  dynamic _pickedPhoto;

  void _resetForm() {
    _nameCtrl.clear(); _roleCtrl.clear(); _bioCtrl.clear();
    _selectedClub = ''; _editId = null; _pickedPhoto = null;
  }

  void _startEdit(CampusStar s) {
    _nameCtrl.text = s.name; _roleCtrl.text = s.role;
    _bioCtrl.text  = s.bio;  _selectedClub  = s.club;
    _editId = s.id; _pickedPhoto = null;
    setState(() => _showForm = true);
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final star = CampusStar(
      id: _editId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(), role: _roleCtrl.text.trim(),
      photoUrl: '', club: _selectedClub, bio: _bioCtrl.text.trim(),
    );
    _editId != null ? widget.onEdit(star) : widget.onAdd(star);
    setState(() { _showForm = false; _resetForm(); });
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase() : name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      _SectionHeader(title: 'Campus stars', addLabel: 'Add star', showAdd: true,
          onAdd: () { _resetForm(); setState(() => _showForm = !_showForm); }),
      if (_showForm) _buildForm(),
      if (widget.stars.isEmpty)
        const _EmptyState(message: 'No campus stars yet. Add one!', icon: Icons.star_outline)
      else
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(children: widget.stars.map((s) => _ItemCard(
              leading: CircleAvatar(radius: 20, backgroundColor: Colors.blue.shade100,
                  child: Text(_initials(s.name),
                      style: TextStyle(color: Colors.blue[700], fontSize: 13, fontWeight: FontWeight.w600))),
              title: s.name,
              subtitle: '${s.role} · ${s.club}',
              onEdit: () => _startEdit(s),
              onDelete: () => widget.onDelete(s.id),
            )).toList()),
          ),
        ),
    ]);
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade100)),
      child: StatefulBuilder(builder: (ctx, setS) => Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_editId != null ? 'Edit star' : 'New campus star',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 12),
        _StyledInput(ctrl: _nameCtrl, label: 'Full name', hint: 'e.g. Timothy White'),
        const SizedBox(height: 12),
        _StyledInput(ctrl: _roleCtrl, label: 'Role / Title', hint: 'e.g. Student leader'),
        const SizedBox(height: 12),
        _ImagePickerTile(label: 'Profile photo', pickedFile: _pickedPhoto, existingUrl: null,
            onPick: () async {
              final f = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (f != null) setS(() => _pickedPhoto = f);
            }),
        const SizedBox(height: 12),
        if (widget.clubs.isNotEmpty)
          _StyledDropdown(label: 'Club', value: _selectedClub, items: widget.clubs,
              onChanged: (v) => setS(() => _selectedClub = v ?? '')),
        const SizedBox(height: 12),
        _StyledInput(ctrl: _bioCtrl, label: 'Bio (optional)', hint: 'Short bio…', maxLines: 3),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: () { setState(() { _showForm = false; _resetForm(); }); }, child: const Text('Cancel')),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: Text(_editId != null ? 'Update star' : 'Save star', style: const TextStyle(fontSize: 13)),
          ),
        ]),
      ],
      )),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
//  POSTS TAB  (dummy — APIs not ready)
// ═════════════════════════════════════════════════════════════════════════════

class _PostsTab extends StatefulWidget {
  final List<CampusPost> posts;
  final List<String> clubs;
  final void Function(CampusPost) onAdd;
  final void Function(CampusPost) onEdit;
  final void Function(String) onDelete;

  const _PostsTab({required this.posts, required this.clubs,
    required this.onAdd, required this.onEdit, required this.onDelete});

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  bool _showForm = false;
  final _authorCtrl  = TextEditingController();
  final _captionCtrl = TextEditingController();
  String _mediaType    = 'video';
  String _selectedClub = '';
  String? _editId;
  dynamic _pickedMedia;

  void _resetForm() {
    _authorCtrl.clear(); _captionCtrl.clear();
    _mediaType = 'video'; _selectedClub = ''; _editId = null; _pickedMedia = null;
  }

  void _startEdit(CampusPost p) {
    _authorCtrl.text  = p.authorName;
    _captionCtrl.text = p.caption;
    _mediaType    = p.mediaType;
    _selectedClub = p.clubTag;
    _editId = p.id; _pickedMedia = null;
    setState(() => _showForm = true);
  }

  void _submit() {
    if (_authorCtrl.text.trim().isEmpty) return;
    final post = CampusPost(
      id: _editId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: _authorCtrl.text.trim(), authorPhotoUrl: '',
      caption: _captionCtrl.text.trim(), mediaUrl: '', thumbnailUrl: '',
      mediaType: _mediaType, clubTag: _selectedClub, timeAgo: 'Just now',
    );
    _editId != null ? widget.onEdit(post) : widget.onAdd(post);
    setState(() { _showForm = false; _resetForm(); });
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase() : name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      _SectionHeader(title: 'Campus posts', addLabel: 'Add post', showAdd: true,
          onAdd: () { _resetForm(); setState(() => _showForm = !_showForm); }),
      if (_showForm) _buildForm(),
      if (widget.posts.isEmpty)
        const _EmptyState(message: 'No posts yet. Add one!', icon: Icons.article_outlined)
      else
        ...widget.posts.map((p) => Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 10), child: Row(children: [
              CircleAvatar(radius: 18, backgroundColor: Colors.pink.shade100,
                  child: Text(_initials(p.authorName),
                      style: TextStyle(color: Colors.pink[700], fontSize: 12, fontWeight: FontWeight.w600))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.authorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(p.timeAgo, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ])),
              if (p.clubTag.isNotEmpty)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Text(p.clubTag, style: TextStyle(fontSize: 10, color: Colors.blue[700]))),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) { if (v == 'edit') _startEdit(p); if (v == 'delete') widget.onDelete(p.id); },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit',   child: _PopupRow(Icons.edit_outlined,   'Edit')),
                  PopupMenuItem(value: 'delete', child: _PopupRow(Icons.delete_outline,   'Delete', isDestructive: true)),
                ],
              ),
            ])),
            if (p.caption.isNotEmpty)
              Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Text(p.caption, style: const TextStyle(fontSize: 13, height: 1.5))),
            Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(height: 80, decoration: BoxDecoration(color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(p.mediaType == 'video' ? Icons.play_circle_outline : Icons.image_outlined,
                        color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    Text(p.mediaType == 'video' ? 'Video attached' : 'Image attached',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ])),
                )),
          ]),
        )),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade100)),
      child: StatefulBuilder(builder: (ctx, setS) => Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_editId != null ? 'Edit post' : 'New post',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 12),
        _StyledInput(ctrl: _authorCtrl, label: 'Author name', hint: 'e.g. Cynthia Hall'),
        const SizedBox(height: 12),
        _StyledInput(ctrl: _captionCtrl, label: 'Caption', hint: 'Write about the event…', maxLines: 3),
        const SizedBox(height: 12),
        // Media type toggle
        Text('Media type', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Row(children: ['image', 'video'].map((type) => Expanded(child: Padding(
          padding: EdgeInsets.only(right: type == 'image' ? 6 : 0),
          child: GestureDetector(
            onTap: () => setS(() => _mediaType = type),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _mediaType == type ? Colors.blue[700] : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(type == 'video' ? Icons.videocam_outlined : Icons.image_outlined,
                    size: 16, color: _mediaType == type ? Colors.white : Colors.grey[600]),
                const SizedBox(width: 6),
                Text(type == 'video' ? 'Video' : 'Image',
                    style: TextStyle(fontSize: 13,
                        color: _mediaType == type ? Colors.white : Colors.grey[600])),
              ]),
            ),
          ),
        ))).toList()),
        const SizedBox(height: 12),
        // Pick from phone
        _mediaType == 'video'
            ? _VideoPickerTile(pickedFile: _pickedMedia, onPick: () async {
          final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
          if (f != null) setS(() => _pickedMedia = f);
        })
            : _ImagePickerTile(label: 'Pick image', pickedFile: _pickedMedia, existingUrl: null,
            onPick: () async {
              final f = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (f != null) setS(() => _pickedMedia = f);
            }),
        const SizedBox(height: 12),
        if (widget.clubs.isNotEmpty)
          _StyledDropdown(label: 'Club tag', value: _selectedClub, items: widget.clubs,
              onChanged: (v) => setS(() => _selectedClub = v ?? '')),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: () { setState(() { _showForm = false; _resetForm(); }); }, child: const Text('Cancel')),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: Text(_editId != null ? 'Update post' : 'Publish post', style: const TextStyle(fontSize: 13)),
          ),
        ]),
      ],
      )),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title, addLabel;
  final bool showAdd;
  final VoidCallback onAdd;

  const _SectionHeader({required this.title, required this.addLabel,
    required this.showAdd, required this.onAdd});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
      if (showAdd)
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16),
          label: Text(addLabel, style: const TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700], foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
          ),
        ),
    ]),
  );
}

class _ItemCard extends StatelessWidget {
  final Widget leading;
  final String title, subtitle;
  final VoidCallback onEdit, onDelete;

  const _ItemCard({required this.leading, required this.title, required this.subtitle,
    required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
    child: Row(children: [
      leading, const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: Colors.blue[700]),
          onPressed: onEdit, padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          onPressed: onDelete, padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(children: [
      Icon(icon, size: 48, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13)),
    ]),
  ));
}

class _LevelChip extends StatelessWidget {
  final String level;
  const _LevelChip(this.level);

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> colors = {
      'beginner':     const Color(0xFF22C55E),
      'intermediate': const Color(0xFFF59E0B),
      'advanced':     const Color(0xFFEF4444),
      'general':      const Color(0xFF42A5F5),
    };
    final color = colors[level.toLowerCase()] ?? const Color(0xFF42A5F5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(level, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _PopupRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  const _PopupRow(this.icon, this.label, {this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : Colors.black87;
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 12, color: color)),
    ]);
  }
}

// ─── Styled form inputs ───────────────────────────────────────────────────────

class _StyledInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final int maxLines;
  final TextInputType keyboardType;

  const _StyledInput({
    required this.ctrl, required this.label, required this.hint,
    this.maxLines = 1, this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl, maxLines: maxLines, keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          filled: true, fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 1)),
        ),
      ),
    ],
  );
}

class _StyledDropdown extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown({required this.label, required this.value,
    required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true, fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
        ),
        hint: Text('Select…', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        items: items.map((e) => DropdownMenuItem(value: e,
            child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
      ),
    ],
  );
}

class _ImagePickerTile extends StatelessWidget {
  final String label;
  final dynamic pickedFile;
  final String? existingUrl;
  final VoidCallback onPick;

  const _ImagePickerTile({required this.label, required this.pickedFile,
    required this.existingUrl, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final hasFile = pickedFile != null;
    final hasExisting = existingUrl != null && existingUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasFile ? Colors.blue.shade300 : Colors.grey.shade300, width: 0.5),
        ),
        child: Row(children: [
          Icon(hasFile ? Icons.check_circle : Icons.image_outlined,
              size: 18, color: hasFile ? Colors.blue[700] : Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(child: Text(
            hasFile
                ? (pickedFile.name as String)
                : (hasExisting ? 'Change $label' : 'Pick $label from gallery'),
            style: TextStyle(fontSize: 12, color: hasFile ? Colors.blue[700] : Colors.grey[500]),
            overflow: TextOverflow.ellipsis,
          )),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}

class _VideoPickerTile extends StatelessWidget {
  final dynamic pickedFile;
  final VoidCallback onPick;

  const _VideoPickerTile({required this.pickedFile, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final hasFile = pickedFile != null;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: hasFile ? Colors.blue.shade300 : Colors.red.shade200, width: 0.5),
        ),
        child: Row(children: [
          Icon(hasFile ? Icons.check_circle : Icons.videocam_outlined,
              size: 18, color: hasFile ? Colors.blue[700] : Colors.red[400]),
          const SizedBox(width: 10),
          Expanded(child: Text(
            hasFile ? (pickedFile.name as String) : 'Pick video from gallery *',
            style: TextStyle(fontSize: 12, color: hasFile ? Colors.blue[700] : Colors.red[400]),
            overflow: TextOverflow.ellipsis,
          )),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}