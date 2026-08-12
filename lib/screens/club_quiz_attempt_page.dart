import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ClubQuizAttempt {
  final String id;
  final String quizId;

  // ⚠️ FALLBACK: backend currently returns studentId/classId/sectionId as
  // null on every attempt (create + getall). Once fixed, these should come
  // back either as raw ObjectId strings or populated {_id, ...} maps —
  // this parser handles both. Until then, studentId/studentName will be
  // null / '—' for all rows.
  final String? studentId;
  final String studentName;
  final String? classId;
  final String? className;
  final String? sectionId;
  final String? sectionName;

  final int score;
  final num percentage;
  final String completedAt;
  final List<Map<String, dynamic>> answers; // questionText, options, correctOptionIndex, points

  const ClubQuizAttempt({
    required this.id,
    required this.quizId,
    this.studentId,
    required this.studentName,
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    required this.score,
    required this.percentage,
    required this.completedAt,
    required this.answers,
  });

  factory ClubQuizAttempt.fromJson(Map<String, dynamic> j) {
    final rawQuiz = j['quizId'];
    final rawStudent = j['studentId'];
    final rawClass = j['classId'];
    final rawSection = j['sectionId'];

    String? studentId;
    String studentName = '—';
    if (rawStudent is Map) {
      studentId = rawStudent['_id']?.toString();
      studentName = (rawStudent['userName'] ?? rawStudent['name'] ?? rawStudent['studentName'] ?? '—').toString();
    } else if (rawStudent is String && rawStudent.isNotEmpty) {
      studentId = rawStudent; // no name available from a bare id
    }

    String? classId, className;
    if (rawClass is Map) {
      classId = rawClass['_id']?.toString();
      className = rawClass['name']?.toString();
    } else if (rawClass is String && rawClass.isNotEmpty) {
      classId = rawClass;
    }

    String? sectionId, sectionName;
    if (rawSection is Map) {
      sectionId = rawSection['_id']?.toString();
      sectionName = rawSection['name']?.toString();
    } else if (rawSection is String && rawSection.isNotEmpty) {
      sectionId = rawSection;
    }

    return ClubQuizAttempt(
      id: j['_id'] ?? '',
      quizId: rawQuiz is Map ? (rawQuiz['_id'] ?? '') : (rawQuiz?.toString() ?? ''),
      studentId: studentId,
      studentName: studentName,
      classId: classId,
      className: className,
      sectionId: sectionId,
      sectionName: sectionName,
      score: j['score'] ?? 0,
      percentage: j['percentage'] ?? 0,
      completedAt: (j['completedAt'] ?? j['createdAt'] ?? '').toString(),
      answers: (j['answers'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }
}

/// Fetch + delete helpers shared by both leaderboard and the parent's
/// "did I already attempt this?" check.
class QuizAttemptApi {
  static Future<List<ClubQuizAttempt>> fetchAttempts({
    required String token,
    required String quizId,
    String? studentId,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllQuizAttempts}')
        .replace(queryParameters: {
      'quizId': quizId,
      if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
    });
    try {
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return (body['data'] as List? ?? [])
            .map((e) => ClubQuizAttempt.fromJson(e))
            .toList();
      }
    } catch (e) {
    }
    return [];
  }

  static Future<bool> deleteAttempt({required String token, required String attemptId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteAttempt}/$attemptId');
    try {
      final res = await http.delete(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}