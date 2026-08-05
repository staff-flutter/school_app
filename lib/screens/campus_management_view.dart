import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // NOTE: add file_picker to pubspec.yaml
import 'package:video_player/video_player.dart';

import '../constants/api_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/school_controller.dart';
import '../core/utils/academic_year_utils.dart';
import '../services/user_session.dart';
import 'dart:io';
import 'package:collection/collection.dart';
import 'quiz_leaderboard_page.dart';
// ─── Role helper ─────────────────────────────────────────────────────────────

bool _canEdit(String role) =>
    role == 'correspondent' || role == 'administrator';

// ─── Logging helper ──────────────────────────────────────────────────────────
// Centralized so every club/video/quiz API call logs the same way.
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

  factory ClubCategory.fromJson(Map<String, dynamic> j) {
    debugPrint('🖼️ [LIST TILE] raw thumbnail json: ${j['thumbnail']}');
    debugPrint('🖼️ [LIST TILE] resolved thumbnailUrl: ${j['thumbnail'] is Map ? j['thumbnail']['url'] : j['thumbnail']}');

    return ClubCategory(
      id:           j['_id']         ?? '',
      name:         j['name']        ?? '',
      description:  j['description'] ?? '',
      thumbnailUrl: j['thumbnail'] is Map
          ? j['thumbnail']['url']
          : j['thumbnail'],
      isActive:     j['isActive']    ?? true,
    );
  }
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

// ─── Quiz models ──────────────────────────────────────────────────────────────

class QuizQuestion {
  String id;
  String text;
  List<String> options;
  int correctIndex;
  int points; // NEW — backend expects this per question

  QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.points = 1,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
    id: (j['_id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString(),
    text: j['questionText'] ?? j['question'] ?? j['text'] ?? '', // questionText first
    options: (j['options'] as List? ?? []).map((e) => e.toString()).toList(),
    correctIndex: j['correctOptionIndex'] ?? j['correctIndex'] ?? 0, // correctOptionIndex first
    points: j['points'] ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'questionText': text,          // was 'question'
    'options': options,
    'correctOptionIndex': correctIndex, // was 'correctIndex'
    'points': points,
  };

  QuizQuestion copy() => QuizQuestion(
    id: id, text: text, options: [...options], correctIndex: correctIndex, points: points,
  );
}
class Quiz {
  final String id;
  final String title;
  final String clubId;
  final String clubVideoId;
  final bool isGeneratedByAi; // 'manual' | 'ai'
  final List<QuizQuestion> questions;
  final String createdAt;

  const Quiz({
    required this.id,
    required this.title,
    required this.clubId,
    required this.clubVideoId,
    required this.isGeneratedByAi,
    required this.questions,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> j) => Quiz(
    id: j['_id'] ?? '',
    title: j['title'] ?? 'Untitled quiz',
    clubId: j['clubId'] is Map ? (j['clubId']['_id'] ?? '') : (j['clubId'] ?? ''),
    clubVideoId: j['clubVideoId'] is Map                              // 👈 NEW
        ? (j['clubVideoId']['_id'] ?? '')
        : (j['clubVideoId']?.toString() ?? ''),
    isGeneratedByAi: j['isGeneratedByAi'] ?? false,
    questions: (j['questions'] as List? ?? [])
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList(),
    createdAt: (j['createdAt'] ?? '').toString().split('T').first,
  );
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
  bool _isFetchingClubs = false;
  String? _lastFetchedSchoolId;
  late TabController _tabController;

  final _auth    = Get.find<AuthController>();
  //final _session = Get.find<UserSession>();
  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;

  String get _role  => _auth.user.value?.role?.toLowerCase() ?? '';
  String? get _schoolId {
    // Correspondents can switch between schools via SchoolController, so
    // prefer their explicitly selected school — but if none has been picked
    // yet (e.g. this tab renders before that selection happens), fall back
    // to the session's schoolId instead of returning null and silently
    // skipping the clubs fetch.
    if (_role == 'correspondent') {
      final selected = _school?.selectedSchool.value?.id;
      if (selected != null && selected.isNotEmpty) return selected;
    }
    return  _auth.user.value?.schoolId;
  }
  String? get _token => _auth.storage.read('token');
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
  };

  // ── Club state ──
  List<ClubCategory> _clubs        = [];
  bool               _clubsLoading = true;
  int                _clubPage     = 1;
  int                _clubTotal    = 1;

  Worker? _schoolWorker;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchClubs();


    // If a correspondent picks/changes their school *after* this screen has
    // already loaded, re-fetch clubs so this view doesn't stay stuck on
    // whatever schoolId (or empty state) it started with.
    if (_school != null) {
      _schoolWorker = ever(_school!.selectedSchool, (_) {
        //setState(() { _clubs = []; _clubsLoading = true; });
        _fetchClubs();
      });
    }
  }

  @override
  void dispose() {
    _schoolWorker?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── API: clubs ────────────────────────────────────────────────────────────

  Future<void> _fetchClubs({int page = 1, bool forceRefresh = false}) async {
    if (_schoolId == null) {
      debugPrint('⚠️ [CLUB API] GET getAllClubs skipped — schoolId is null');
      setState(() => _clubsLoading = false);
      return;
    }
    if (page == 1) {
      if (_isFetchingClubs) {
        debugPrint('⏭️ Skipping duplicate _fetchClubs — one already in flight');
        return;
      }
      if (_schoolId == _lastFetchedSchoolId && _clubs.isNotEmpty) {
        debugPrint('⏭️ Skipping _fetchClubs — already have data for schoolId $_schoolId');
        return;
      }
    }

    _isFetchingClubs = true;
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
      } if (page == 1) _lastFetchedSchoolId = _schoolId;
      else {
        setState(() => _clubsLoading = false);
      }
    } catch (e) {
      _logError('GET', uri, e);
      setState(() => _clubsLoading = false);
    }finally {
      _isFetchingClubs = false;
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
                  onRefresh: () => _fetchClubs(page: 1, forceRefresh: true),
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
                _QuizTab(
                  clubs: _clubs,
                  clubsLoading: _clubsLoading,
                  token: _token ?? '',
                  schoolId: _schoolId ?? '',
                  canEdit: _canEdit(_role),
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
        Tab(child: Row(children: [Icon(Icons.quiz_outlined, size: 18), SizedBox(width: 8), Text('Quiz')])),
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
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final void Function(ClubCategory) onTapClub;
  final Future<void> Function(String name, String desc, dynamic thumb) onCreate;
  final Future<void> Function(ClubCategory, String name, String desc, bool active, dynamic thumb) onEdit;
  final void Function(ClubCategory) onDelete;

  const _ClubsTab({
    required this.clubs, 
    required this.isLoading, 
    required this.canEdit,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore, 
    required this.onTapClub,
    required this.onCreate, 
    required this.onEdit, 
    required this.onDelete,
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
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
      ),
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
    required String title,
    required String topic,
    required String level,
    required String academicYear,
    required dynamic videoFile,
    List<PlatformFile>? pdfFiles,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadClubVideo}');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..fields['schoolId'] = widget.schoolId
      ..fields['clubId'] = widget.club.id
      ..fields['title'] = title
      ..fields['topic'] = topic
      ..fields['level'] = level
      ..fields['academicYear'] = academicYear;

    // 1. Dynamic video extension extraction
    final videoExt = videoFile.path.split('.').last.toLowerCase();
    req.files.add(
      await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        contentType: MediaType('video', videoExt.isEmpty ? 'mp4' : videoExt),
      ),
    );

    // 2. Attach PDFs via the exact verified backend key array structure
    if (pdfFiles != null) {
      for (final pdf in pdfFiles) {
        req.files.add(await http.MultipartFile.fromPath(
          'pdf',
          pdf.path!,
          contentType: MediaType('application', 'pdf'),
        ));
      }
    }

    // 3. Clean Fixed Logging (Removed the buggy collection-if condition)
    _logRequest('POST', uri, fields: {
      ...req.fields,
      'video': videoFile.path,
      'pdfs_attached': pdfFiles != null ? pdfFiles.length.toString() : '0',
    });

    print('Sending ${req.files.length} total files via multipart.');

    try {
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      _logResponse('POST', uri, res);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final jsonResponse = json.decode(res.body);
        if (jsonResponse['ok'] == true) {
          Get.snackbar('Success', 'Club video uploaded successfully!');
          _fetchVideos(); // Refresh video listing view
        } else {
          Get.snackbar('Failed', jsonResponse['message'] ?? 'Upload failed');
        }
      } else {
        debugPrint("❌ Server Error Body: ${res.body}");
        Get.snackbar('Server Error (${res.statusCode})', 'The server rejected the file combination.');
      }
    } catch (e) {
      debugPrint("❌ Exception during upload: $e");
      Get.snackbar('Error', 'An unexpected error occurred during submission.');
    }
  }


  Future<void> _updateVideoDetails(
      ClubVideo v,
      String title,
      String topic,
      String level,
      String year, {
        List<PlatformFile>? pdfFiles, // 🌟 Added optional PDF files parameter
      }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateClubVideoDetails}/${v.id}');

    // 1. Switch to MultipartRequest so we can handle binary file transmission
    final req = http.MultipartRequest('PUT', uri)
      ..headers.addAll(_headers)
      ..fields['title'] = title
      ..fields['topic'] = topic
      ..fields['level'] = level
      ..fields['academicYear'] = year;

    // 2. Attach the new PDFs to verify the update functionality
    if (pdfFiles != null && pdfFiles.isNotEmpty) {
      for (final pdf in pdfFiles) {
        req.files.add(await http.MultipartFile.fromPath(
          'files', // 🌟 Matches the verified backend array key string format
          pdf.path!,
          contentType: MediaType('application', 'pdf'),
        ));
      }
    }

    print('Sending update request with ${req.files.length} new PDF files.');

    try {
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      _logResponse('PUT', uri, res);

      if (res.statusCode == 200) {
        print('res:${res.body}');
        _snack('Updated details successfully!', success: true);
        _fetchVideos(); // Refresh listing
      } else {
        _snack('Failed to update details: ${_msg(res)}');
      }
    } catch (e) {
      _logError('PUT', uri, e);
      _snack('Error updating details: $e');
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
    final yearCtrl  = TextEditingController(text: AcademicYearUtils.getCurrentAcademicYear());
    String level    = 'general';
    dynamic videoFile;
    List<PlatformFile> pdfFiles = [];
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
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom, allowedExtensions: ['pdf'], allowMultiple: true,
              );
              if (result != null) setS(() => pdfFiles = result.files);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: pdfFiles.isNotEmpty ? Colors.blue.shade300 : Colors.grey.shade300, width: 0.5),
              ),
              child: Row(children: [
                Icon(pdfFiles.isNotEmpty ? Icons.check_circle : Icons.picture_as_pdf_outlined,
                    size: 18, color: pdfFiles.isNotEmpty ? Colors.blue[700] : Colors.grey[500]),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  pdfFiles.isEmpty ? 'Attach PDF(s) — optional, needed for AI quiz generation'
                      : '${pdfFiles.length} PDF(s) selected',
                  style: TextStyle(fontSize: 12, color: pdfFiles.isNotEmpty ? Colors.blue[700] : Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
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
                await _uploadVideo(
                  title: titleCtrl.text.trim(),
                  topic: topicCtrl.text.trim(),
                  level: level,
                  academicYear: yearCtrl.text.trim(),
                  videoFile: videoFile,
                  pdfFiles: pdfFiles.isEmpty ? null : pdfFiles,
                );
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
    String selectedLevel = v.level.isEmpty ? 'general' : v.level;
    String selectedYear = v.academicYear.isEmpty
        ? AcademicYearUtils.getCurrentAcademicYear()
        : v.academicYear;

    // Local state variable to temporarily hold newly selected PDF files for updating
    List<PlatformFile> selectedPdfs = [];

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Video Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title *'),
                  ),
                  TextField(
                    controller: topicCtrl,
                    decoration: const InputDecoration(labelText: 'Topic *'),
                  ),
                  const SizedBox(height: 16),

                  // --- 🌟 FIXED: Using your exact native file picker UI widget design ---
                  const Text(
                    'Add Documents (Optional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: () async {
                      final res = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                        allowMultiple: true,
                      );
                      if (res != null) {
                        setModalState(() {
                          selectedPdfs.addAll(res.files);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.file_present, size: 18, color: Colors.blue[700]),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Tap to attach new PDF files',
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Show selected files list below the input tile
                  if (selectedPdfs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(selectedPdfs.length, (index) {
                        final file = selectedPdfs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, size: 14, color: Colors.red),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  file.name,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                                onPressed: () {
                                  setModalState(() {
                                    selectedPdfs.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty ||
                              topicCtrl.text.trim().isEmpty) {
                            _snack('Please fill required fields');
                            return;
                          }
                          Get.back();
                          // Trigger update passing inputs along with new files
                          _updateVideoDetails(
                            v,
                            titleCtrl.text.trim(),
                            topicCtrl.text.trim(),
                            selectedLevel,
                            selectedYear,
                            pdfFiles: selectedPdfs.isEmpty ? null : selectedPdfs,
                          );
                        },
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
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
//  QUIZ TAB
//  Two ways to build a quiz for a club:
//   • Manual   — add questions & options by hand
//   • AI (PDF) — upload a PDF, backend generates questions, review + save
// ═════════════════════════════════════════════════════════════════════════════

class _QuizTab extends StatefulWidget {
  final List<ClubCategory> clubs;
  final bool clubsLoading;
  final String token;
  final String schoolId;
  final bool canEdit;

  const _QuizTab({
    required this.clubs, required this.clubsLoading,
    required this.token, required this.schoolId, required this.canEdit,
  });

  @override
  State<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<_QuizTab> {
  ClubCategory? _selectedClub;
  List<Quiz> _quizzes = [];
  bool _loading = false;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.token}',
    'Accept': 'application/json',
  };
  String _msg(http.Response r) {
    try { return jsonDecode(r.body)['message'] ?? '${r.statusCode}'; } catch (_) { return '${r.statusCode}'; }
  }
  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    _fetchQuizAttempts();
  }
  @override
  void didUpdateWidget(covariant _QuizTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // School changed (correspondent switched schools) — clubs/quizzes from
    // the old school are no longer valid, so reset and refetch everything.
    if (oldWidget.schoolId != widget.schoolId) {
      setState(() {
        _selectedClub = null;
        _quizzes = [];
      });
    }

    // Auto-select the first club once clubs finish loading (also covers
    // the case right after a school switch, once _selectedClub was reset above).
    if (_selectedClub == null && widget.clubs.isNotEmpty) {
      _selectedClub = widget.clubs.first;

      _fetchQuizzes();
    }
  }
  Future<void> _fetchQuizAttempts() async{
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllQuizAttempts}');

    try {
      final res = await http.get(uri, headers: _headers);
      _logResponse('GET', uri, res);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        print('getAllQuizAttempts:$body}');
        final list = (body['data'] as List? ?? []).map((e) => Quiz.fromJson(e)).toList();
        final Map<String, Quiz> uniqueMap = {
          for (final q in list) if (q.id.isNotEmpty) q.id: q,
        };
        setState(() { _quizzes = uniqueMap.values.toList(); _loading = false; });
      } else {
        setState(() { _quizzes = []; _loading = false; });
      }
    } catch (e) {
      _logError('GET', uri, e);
      setState(() { _quizzes = []; _loading = false; });
    }
  }
  Future<void> _fetchQuizzes() async {
    if (_selectedClub == null) return;
    setState(() => _loading = true);
    // NOTE: add `getQuizzesByClub` to ApiConstants pointing at your quiz-list endpoint.
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getQuizzesByClub}')
        .replace(queryParameters: {'clubId': _selectedClub!.id.toString(),'schoolId': widget.schoolId,});
    _logRequest('GET', uri);
    try {
      final res = await http.get(uri, headers: _headers);
      _logResponse('GET', uri, res);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] as List? ?? []).map((e) => Quiz.fromJson(e)).toList();
        final Map<String, Quiz> uniqueMap = {
          for (final q in list) if (q.id.isNotEmpty) q.id: q,
        };
        setState(() { _quizzes = uniqueMap.values.toList(); _loading = false; });
      } else {
        setState(() { _quizzes = []; _loading = false; });
      }
    } catch (e) {
      _logError('GET', uri, e);
      setState(() { _quizzes = []; _loading = false; });
    }
  }

  Future<void> _deleteQuiz(Quiz q) async {
    print('🗑️ Deleting quiz ${q.id} — quiz.clubId=${q.clubId}, current widget.schoolId=${widget.schoolId}');

    // NOTE: add `deleteQuiz` to ApiConstants pointing at your delete endpoint.
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteQuiz}/${q.id}').replace(queryParameters: {'schoolId': widget.schoolId});
    _logRequest('DELETE', uri);
    try {
      final res = await http.delete(uri, headers: _headers);
      _logResponse('DELETE', uri, res);
      if (res.statusCode == 200) {
        setState(() => _quizzes.removeWhere((x) => x.id == q.id));
        Get.snackbar('Success', 'Quiz deleted', backgroundColor: const Color(0xFF22C55E), colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Failed to delete quiz: ${_msg(res)}',
            backgroundColor: Colors.redAccent, colorText: Colors.white);      }
    } catch (e) {
      _logError('DELETE', uri, e);
      Get.snackbar('Error', 'Failed to delete quiz', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void _confirmDelete(Quiz q) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      content: Text('Delete "${q.title}"?', style: const TextStyle(fontSize: 13)),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () { Get.back(); _deleteQuiz(q); },
          child: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    ));
  }

  Future<void> _openManualBuilder({Quiz? editing}) async {
    if (_selectedClub == null) return;
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => _QuizBuilderScreen(
        schoolId: widget.schoolId,
        clubId: _selectedClub!.id,
        token: widget.token,
        source: 'manual',
        editingQuiz: editing,
      ),
    ));
    if (saved == true) _fetchQuizzes();
  }

  Future<void> _openAiGenerator() async {
    if (_selectedClub == null) return;
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => _AiQuizUploadScreen(
        clubId: _selectedClub!.id,
        token: widget.token, schoolId: widget.schoolId,
      ),
    ));
    if (saved == true) _fetchQuizzes();
  }

  Future<void> _openTakeQuiz(Quiz q) async {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _QuizPreviewScreen(quiz: q),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clubsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.clubs.isEmpty) {
      return const _EmptyState(
        message: 'Create a club first — quizzes are attached to a club.',
        icon: Icons.groups_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchQuizzes,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _StyledDropdown(
              label: 'Club',
              value: _selectedClub?.name ?? '',
              items: widget.clubs.map((c) => c.name).toList(),
              onChanged: (name) {
                final club = widget.clubs.firstWhere((c) => c.name == name);
                setState(() => _selectedClub = club);
                _fetchQuizzes();
              },
            ),
          ),
          if (widget.canEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(children: [
                Expanded(child: _QuizActionCard(
                  icon: Icons.edit_note,
                  title: 'Create manually',
                  subtitle: 'Add questions & options yourself',
                  color: Colors.blue,
                  onTap: () => _openManualBuilder(),
                )),
                const SizedBox(width: 12),
                Expanded(child: _QuizActionCard(
                  icon: Icons.auto_awesome,
                  title: 'Generate with AI',
                  subtitle: 'Upload a PDF, we\'ll build it',
                  color: Colors.purple,
                  onTap: _openAiGenerator,
                )),
              ]),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Quizzes', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          ),
          if (_loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_quizzes.isEmpty)
            const _EmptyState(message: 'No quizzes yet for this club.', icon: Icons.quiz_outlined)
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(children: _quizzes.map((q) => _QuizListTile(
                  quiz: q,
                  canEdit: widget.canEdit,
                  onTap: () => _openTakeQuiz(q),
                  onEdit: () => _openManualBuilder(editing: q),
                  onDelete: () => _confirmDelete(q),
                )).toList()),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuizActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final MaterialColor color;
  final VoidCallback onTap;

  const _QuizActionCard({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.shade100),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color[700], size: 22),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color[900])),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: color[700]), maxLines: 2),
        ]),
      ),
    );
  }
}

class _QuizListTile extends StatelessWidget {
  final Quiz quiz;
  final bool canEdit;
  final VoidCallback onTap, onEdit, onDelete;

  const _QuizListTile({
    required this.quiz,
    required this.canEdit,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAi = quiz.isGeneratedByAi;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Icon + Quiz Title & Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isAi ? Colors.purple : Colors.blue).shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAi ? Icons.auto_awesome : Icons.edit_note,
                    color: (isAi ? Colors.purple : Colors.blue)[700],
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                        // Removed maxLines limit so full text shows
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${quiz.questions.length} questions · ${isAi ? "AI generated" : "Manual"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Bottom Section: Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Leaderboard Button
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizLeaderboardPage(
                        quizId: quiz.id,
                        quizTitle: quiz.title,
                        canDelete: canEdit,
                      ),
                    ),
                  ),
                  icon: Icon(Icons.leaderboard_outlined, size: 16, color: Colors.blue[700]),
                  label: Text(
                    'Leaderboard',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                if (canEdit) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 18, color: Colors.blue[700]),
                    onPressed: onEdit,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: onDelete,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// ─── Manual quiz builder (also used to review/edit AI-generated questions) ───

class _QuizBuilderScreen extends StatefulWidget {
  final String clubId;
  final String token;
  final String schoolId;
  final String source; // 'manual' | 'ai'
  final Quiz? editingQuiz;
  final String? initialTitle;
  final List<QuizQuestion>? initialQuestions;
  final String? initialVideoId;

  const _QuizBuilderScreen({

    required this.clubId, required this.token,required this.schoolId, required this.source,
    this.editingQuiz, this.initialTitle, this.initialQuestions,this.initialVideoId,
  });

  @override
  State<_QuizBuilderScreen> createState() => _QuizBuilderScreenState();
}

class _QuizBuilderScreenState extends State<_QuizBuilderScreen> {
  late TextEditingController _titleCtrl;
  late List<QuizQuestion> _questions;
  bool _saving = false;

  List<ClubVideo> _videos = [];
  bool _videosLoading = true;
  String? _selectedVideoId;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.token}',
    'Accept': 'application/json',
  };

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: widget.editingQuiz?.title ?? widget.initialTitle ?? '',
    );
    _questions = widget.editingQuiz?.questions.map((q) => q.copy()).toList()
        ?? widget.initialQuestions?.map((q) => q.copy()).toList()
        ?? [_blankQuestion()];


    _selectedVideoId = (widget.editingQuiz?.clubVideoId.isNotEmpty ?? false)
        ? widget.editingQuiz!.clubVideoId
        : widget.initialVideoId;

    _fetchVideosForPicker();

  }
  Future<void> _fetchVideosForPicker() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllClubVideos}')
        .replace(queryParameters: {'clubId': widget.clubId, 'page': '1', 'limit': '50'});
    try {
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] as List).map((e) => ClubVideo.fromJson(e)).toList();
        setState(() {
          _videos = list;
          _videosLoading = false;
        });
      } else {
        setState(() => _videosLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Failed to load videos for quiz picker: $e');
      setState(() => _videosLoading = false);
    }
  }

  QuizQuestion _blankQuestion() => QuizQuestion(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    text: '',
    options: ['', ''],
    correctIndex: 0,
  );

  void _addQuestion() => setState(() => _questions.add(_blankQuestion()));
  void _removeQuestion(int i) => setState(() => _questions.removeAt(i));
  void _addOption(int qi) => setState(() => _questions[qi].options.add(''));
  void _removeOption(int qi, int oi) => setState(() {
    _questions[qi].options.removeAt(oi);
    if (_questions[qi].correctIndex >= _questions[qi].options.length) {
      _questions[qi].correctIndex = 0;
    }
  });

  bool get _isValid {
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_selectedVideoId == null || _selectedVideoId!.isEmpty) return false;
    if (_questions.isEmpty) return false;
    for (final q in _questions) {
      if (q.text.trim().isEmpty) return false;
      if (q.options.length < 2) return false;
      if (q.options.any((o) => o.trim().isEmpty)) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_isValid) {
      Get.snackbar('Missing info', 'Fill in the quiz title, every question, and at least 2 options each',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    setState(() => _saving = true);

    final payload = {
      'schoolId': widget.schoolId,
      'clubId': widget.clubId,
      'clubVideoId': _selectedVideoId,
      'title': _titleCtrl.text.trim(),
      'academicYear': AcademicYearUtils.getCurrentAcademicYear(),
      //'source': widget.source,
      'questions': _questions.map((q) => q.toJson()).toList(),
    };
    final year = AcademicYearUtils.getCurrentAcademicYear();
    print('📅 [QUIZ SAVE] computed academicYear = $year');
    final isEditing = widget.editingQuiz != null;
    // NOTE: add `createQuiz` / `updateQuiz` to ApiConstants pointing at your backend.
    final uri = isEditing
        ? Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateQuiz}/${widget.editingQuiz!.id}')
        : Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createQuiz}');

    _logRequest(isEditing ? 'PUT' : 'POST', uri, fields: {'title': payload['title'] as String});
    try {
      final res = isEditing
          ? await http.put(uri, headers: {..._headers, 'Content-Type': 'application/json'}, body: jsonEncode(payload))
          : await http.post(uri, headers: {..._headers, 'Content-Type': 'application/json'}, body: jsonEncode(payload));
      _logResponse(isEditing ? 'PUT' : 'POST', uri, res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        print('responseOfManualQuiz:${res.body}');
        Get.snackbar('Success', isEditing ? 'Quiz updated' : 'Quiz created',
            backgroundColor: const Color(0xFF22C55E), colorText: Colors.white);
        if (mounted) Navigator.pop(context, true);
      } else {
        Get.snackbar('Error', 'Failed to save quiz', backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      _logError(isEditing ? 'PUT' : 'POST', uri, e);
      Get.snackbar('Error', 'Failed to save quiz', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAi = widget.source == 'ai';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editingQuiz != null ? 'Edit quiz' : (isAi ? 'Review AI quiz' : 'New quiz'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isAi)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.auto_awesome, color: Colors.purple[700], size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Generated from your PDF — review and edit before saving.',
                    style: TextStyle(fontSize: 12, color: Colors.purple[700]))),
              ]),
            ),
          _StyledInput(ctrl: _titleCtrl, label: 'Quiz title', hint: 'e.g. Chapter 3 recap'),
          const SizedBox(height: 16),
          _videosLoading
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
              : _videos.isEmpty
              ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Text(
              'No videos found for this club — upload a video first, quizzes must be linked to one.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          )
              : _StyledDropdown(
            label: 'Video',
            value: _videos.firstWhereOrNull((v) => v.id == _selectedVideoId)?.title ?? '',
            items: _videos.map((v) => v.title).toList(),
            onChanged: (title) {
              final video = _videos.firstWhere((v) => v.title == title);
              setState(() => _selectedVideoId = video.id);
            },
          ),
          const SizedBox(height: 16),
          ...List.generate(_questions.length, (qi) => _QuestionEditorCard(
            index: qi,
            question: _questions[qi],
            canRemove: _questions.length > 1,
            onChanged: () => setState(() {}),
            onAddOption: () => _addOption(qi),
            onRemoveOption: (oi) => _removeOption(qi, oi),
            onRemoveQuestion: () => _removeQuestion(qi),
          )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add question', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              side: BorderSide(color: Colors.blue.shade200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700], foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
            ),
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.editingQuiz != null ? 'Update quiz' : 'Save quiz', style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuestionEditorCard extends StatelessWidget {
  final int index;
  final QuizQuestion question;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onAddOption;
  final void Function(int) onRemoveOption;
  final VoidCallback onRemoveQuestion;

  const _QuestionEditorCard({
    required this.index, required this.question, required this.canRemove,
    required this.onChanged, required this.onAddOption,
    required this.onRemoveOption, required this.onRemoveQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final textCtrl = TextEditingController(text: question.text)
      ..selection = TextSelection.collapsed(offset: question.text.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Question ${index + 1}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const Spacer(),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: onRemoveQuestion,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: textCtrl,
          onChanged: (v) { question.text = v; },
          maxLines: 2,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Type the question…',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true, fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        Text('Options (tap the circle to mark the correct answer)',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 6),
        ...List.generate(question.options.length, (oi) {
          final optCtrl = TextEditingController(text: question.options[oi])
            ..selection = TextSelection.collapsed(offset: question.options[oi].length);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              GestureDetector(
                onTap: () { question.correctIndex = oi; onChanged(); },
                child: Icon(
                  question.correctIndex == oi ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: question.correctIndex == oi ? const Color(0xFF22C55E) : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: TextField(
                controller: optCtrl,
                onChanged: (v) { question.options[oi] = v; },
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Option ${oi + 1}',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true, fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              )),
              if (question.options.length > 2)
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: Colors.grey[500]),
                  onPressed: () => onRemoveOption(oi),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
            ]),
          );
        }),
        TextButton.icon(
          onPressed: onAddOption,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Add option', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(foregroundColor: Colors.blue[700], padding: EdgeInsets.zero),
        ),
      ]),
    );
  }
}


// ─── AI quiz generator: upload PDF → backend generates questions → review ────

// ─── AI quiz generator: pick an existing club video + its PDF → generate ────

class _AiQuizUploadScreen extends StatefulWidget {
  final String clubId;
  final String token;
  final String schoolId;

  const _AiQuizUploadScreen({required this.clubId, required this.token, required this.schoolId});

  @override
  State<_AiQuizUploadScreen> createState() => _AiQuizUploadScreenState();
}

class _AiQuizUploadScreenState extends State<_AiQuizUploadScreen> {
  List<ClubVideo> _videos = [];
  bool _videosLoading = true;

  ClubVideo? _selectedVideo;
  Map<String, String>? _selectedPdf; // {id, url, name}
  final _questionCountCtrl = TextEditingController(text: '10');
  final _yearCtrl = TextEditingController(text: AcademicYearUtils.getCurrentAcademicYear());
  bool _generating = false;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.token}',
    'Accept': 'application/json',
  };

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllClubVideos}')
        .replace(queryParameters: {'clubId': widget.clubId, 'page': '1', 'limit': '50'});
    _logRequest('GET', uri);
    try {
      final res = await http.get(uri, headers: _headers);
      _logResponse('GET', uri, res);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] as List).map((e) => ClubVideo.fromJson(e)).toList();
        // Only videos that actually have a PDF attached are usable here.
        final withPdfs = list.where((v) => v.pdfs.isNotEmpty).toList();
        setState(() { _videos = withPdfs; _videosLoading = false; });
      } else {
        setState(() => _videosLoading = false);
      }
    } catch (e) {
      _logError('GET', uri, e);
      setState(() => _videosLoading = false);
    }
  }

  Future<void> _generate() async {
    if (_selectedVideo == null || _selectedPdf == null) {
      Get.snackbar('Pick a PDF', 'Choose a video and one of its attached PDFs',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    setState(() => _generating = true);

    final payload = {
      'schoolId': widget.schoolId,
      'clubId': widget.clubId,
      'clubVideoId': _selectedVideo!.id,
      'pdfId': _selectedPdf!['id'],
      'numberOfQuestions': int.tryParse(_questionCountCtrl.text.trim()) ?? 10,
      'academicYear': _yearCtrl.text.trim(),
      // classId / sectionId are optional per the docs — wire these in once
      // this screen has access to a class/section picker.
    };

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.generateQuizFromPdf}');
    _logRequest('POST', uri, fields: payload.map((k, v) => MapEntry(k, '$v')));
    try {
      final res = await http.post(uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      _logResponse('POST', uri, res);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        final data = body['data'] ?? body;
        final generatedQuizId = data['_id']?.toString();
        final title = data['title'] ?? '${_selectedVideo!.title} Quiz';
        final questions = (data['questions'] as List? ?? [])
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList();

        // if (questions.isEmpty) {
        //   Get.snackbar('No questions generated', 'Try a different PDF or add questions manually',
        //       backgroundColor: Colors.orange, colorText: Colors.white);
        //   setState(() => _generating = false);
        //   return;
        // }

        if (!mounted) return;
        final alreadySaved = generatedQuizId != null && generatedQuizId.isNotEmpty;

        final saved = await Navigator.pushReplacement<bool, void>(context, MaterialPageRoute(
          builder: (_) => _QuizBuilderScreen(
            clubId: widget.clubId,
            token: widget.token,
            schoolId: widget.schoolId,
            source: 'ai',
            initialVideoId: _selectedVideo!.id,
            editingQuiz: alreadySaved
                ? Quiz(
              id: generatedQuizId!,
              title: title,
              clubId: widget.clubId,
              clubVideoId: _selectedVideo!.id,
              isGeneratedByAi: true,
              questions: questions,
              createdAt: '',
            )
                : null,
            initialTitle: title,
            initialQuestions: questions,
          ),
        ));
        if (saved == true && mounted) Navigator.pop(context, true);
      } else {
        Get.snackbar('Error', 'Failed to generate quiz: ${_msg(res)}',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      _logError('POST', uri, e);
      Get.snackbar('Error', 'Failed to generate quiz: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A2E)),
          onPressed: _generating ? null : () => Navigator.pop(context),
        ),
        title: const Text('Generate quiz with AI',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
      ),
      body: _generating
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('Reading the PDF and building questions…',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ]))
          : _videosLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
          ? const _EmptyState(
        message: 'No videos with attached PDFs yet.\nUpload a video with a PDF first, then generate a quiz from it.',
        icon: Icons.picture_as_pdf_outlined,
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.auto_awesome, color: Colors.purple[700], size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Pick a video and one of its attached PDFs — we\'ll auto-generate quiz questions from it.',
                style: TextStyle(fontSize: 12, color: Colors.purple[700]),
              )),
            ]),
          ),
          const SizedBox(height: 16),
          _StyledDropdown(
            label: 'Video',
            value: _selectedVideo?.title ?? '',
            items: _videos.map((v) => v.title).toList(),
            onChanged: (title) {
              final video = _videos.firstWhere((v) => v.title == title);
              setState(() {
                _selectedVideo = video;
                _selectedPdf = null; // reset — pick a PDF again for the new video
                _yearCtrl.text = video.academicYear.isNotEmpty ? video.academicYear : _yearCtrl.text;
              });
            },
          ),
          if (_selectedVideo != null) ...[
            const SizedBox(height: 16),
            Text('PDF', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            const SizedBox(height: 6),
            ..._selectedVideo!.pdfs.map((pdf) {
              final isSelected = _selectedPdf?['id'] == pdf['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedPdf = pdf),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200),
                  ),
                  child: Row(children: [
                    Icon(isSelected ? Icons.check_circle : Icons.picture_as_pdf,
                        size: 18, color: isSelected ? Colors.blue[700] : Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(pdf['name'] ?? 'PDF',
                        style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ]),
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          _StyledInput(
            ctrl: _questionCountCtrl,
            label: 'Number of questions',
            hint: 'e.g. 10',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _StyledInput(ctrl: _yearCtrl, label: 'Academic year', hint: '2025-2026'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Generate quiz', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700], foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  String _msg(http.Response r) {
    try { return jsonDecode(r.body)['message'] ?? '${r.statusCode}'; } catch (_) { return '${r.statusCode}'; }
  }}


// ─── Read-only quiz preview / take screen ─────────────────────────────────────

class _QuizPreviewScreen extends StatefulWidget {
  final Quiz quiz;
  const _QuizPreviewScreen({required this.quiz});

  @override
  State<_QuizPreviewScreen> createState() => _QuizPreviewScreenState();
}

class _QuizPreviewScreenState extends State<_QuizPreviewScreen> {
  final Map<int, int> _selected = {}; // questionIndex -> optionIndex
  bool _submitted = false;

  int get _score {
    int s = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_selected[i] == widget.quiz.questions[i].correctIndex) s++;
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quiz;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(q.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_submitted)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14)),
              child: Text('Score: $_score / ${q.questions.length}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.green[800])),
            ),
          ...List.generate(q.questions.length, (qi) {
            final question = q.questions[qi];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${qi + 1}. ${question.text}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...List.generate(question.options.length, (oi) {
                  final isSelected = _selected[qi] == oi;
                  final isCorrect  = oi == question.correctIndex;
                  Color? bg;
                  if (_submitted) {
                    if (isCorrect) bg = Colors.green.shade50;
                    else if (isSelected && !isCorrect) bg = Colors.red.shade50;
                  } else if (isSelected) {
                    bg = Colors.blue.shade50;
                  }
                  return GestureDetector(
                    onTap: _submitted ? null : () => setState(() => _selected[qi] = oi),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: bg ?? Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          size: 16, color: isSelected ? Colors.blue[700] : Colors.grey[400],
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(question.options[oi], style: const TextStyle(fontSize: 13))),
                        if (_submitted && isCorrect)
                          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                      ]),
                    ),
                  );
                }),
              ]),
            );
          }),
          if (!_submitted)
            ElevatedButton(
              onPressed: () => setState(() => _submitted = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700], foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 14)),
            ),
        ],
      ),
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