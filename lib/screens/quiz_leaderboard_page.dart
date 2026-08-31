import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'club_quiz_attempt_page.dart';


class QuizLeaderboardPage extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final String schoolId;
  final bool canDelete;

  const QuizLeaderboardPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.schoolId,
    this.canDelete = false,
  });

  @override
  State<QuizLeaderboardPage> createState() => _QuizLeaderboardPageState();
}

class _QuizLeaderboardPageState extends State<QuizLeaderboardPage> {
  final _auth = Get.find<AuthController>();
  List<ClubQuizAttempt> _attempts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = _auth.storage.read('token') ?? '';
    final list = await QuizAttemptApi.fetchAttempts(token: token, quizId: widget.quizId,schoolId: widget.schoolId);
    // Leaderboard order: highest score/percentage first, most recent as tiebreak.
    list.sort((a, b) {
      final byPct = b.percentage.compareTo(a.percentage);
      if (byPct != 0) return byPct;
      return b.completedAt.compareTo(a.completedAt);
    });
    if (mounted) setState(() { _attempts = list; _loading = false; });
  }

  Future<void> _confirmDelete(ClubQuizAttempt a) async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      content: Text('Delete ${a.studentName == '—' ? 'this' : "${a.studentName}'s"} attempt?',
          style: const TextStyle(fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () => Get.back(result: true),
          child: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    ));
    if (confirmed != true) return;

    final token = _auth.storage.read('token') ?? '';
    final ok = await QuizAttemptApi.deleteAttempt(token: token, attemptId: a.id);
    if (ok) {
      setState(() => _attempts.removeWhere((x) => x.id == a.id));
      Get.snackbar('Success', 'Attempt deleted',
          backgroundColor: const Color(0xFF22C55E), colorText: Colors.white);
    } else {
      Get.snackbar('Error', 'Failed to delete attempt',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leaderboard',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            Text(widget.quizTitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _attempts.isEmpty
          ? Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Icon(Icons.leaderboard_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No attempts yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      ))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _attempts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final a = _attempts[i];
            final isTop = i == 0;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isTop ? Border.all(color: Colors.amber.shade300, width: 1.2) : null,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                Container(
                  width: 32, height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isTop ? Colors.amber.shade50 : Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: isTop ? Colors.amber[800] : Colors.blue[700])),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.studentName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 3),
                    Text(
                      [
                       // if (a.studentId != null) 'StudentId: ${a.studentId!}',
                        if (a.className != null) a.className!,
                        if (a.sectionName != null) a.sectionName!,
                        a.completedAt.split('T').first,
                      ].join(' · '),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                )),
                Text('${a.score}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
                Text(' (${a.percentage}%)',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                if (widget.canDelete) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () => _confirmDelete(a),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ]),
            );
          },
        ),
      ),
    );
  }
}