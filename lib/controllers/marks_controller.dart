import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/services/api_service.dart';

class MarksController extends GetxController {
  final ApiService _apiService = Get.find();

  final isLoading        = false.obs;
  final marksList        = <Map<String, dynamic>>[].obs;
  final studentMarksList = <Map<String, dynamic>>[].obs;

  // ── Snackbar helper (identical to AttendanceController) ───────────────────
  void _showSnackbar(String title, String message, Color color) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isSnackbarOpen != true) {
        Get.snackbar(
          title,
          message,
          backgroundColor: color,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  // ─── 1. Load marks for a class + exam ─────────────────────────────────────
  // GET /api/marks/getbyclass
  Future<List<Map<String, dynamic>>?> getMarksByClass({
    required String schoolId,
    required String classId,
    required String examType,
    required String term,
    String? sectionId,
    String? academicYear,
  }) async {
    try {
      isLoading.value = true;

      final queryParams = {
        'schoolId': schoolId,
        'classId':  classId,
        'examType': examType,
        'term':     term,
        if (sectionId    != null) 'sectionId':    sectionId,
        if (academicYear != null) 'academicYear': academicYear,
      };

      final response = await _apiService.get(
        ApiConstants.getMarksByClass,
        queryParameters: queryParams,
      );

      if (response.data['ok'] == true) {
        final data = List<Map<String, dynamic>>.from(
            response.data['data'] ?? []);
        marksList.value = data;
        return data;
      } else {
        _showSnackbar('Error',
            response.data['message'] ?? 'Failed to load marks',
            AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar(
          'Error', 'An error occurred while loading marks', AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── 2. Upload marks (bulk — all students at once) ─────────────────────────
  // POST /api/marks/upload
  Future<bool> uploadMarks({
    required String schoolId,
    required String classId,
    required String examType,
    required String term,
    required int    maxMarks,
    required List<Map<String, dynamic>> entries,
    // entries format:
    // [ { studentId, studentName, rollNumber, subjectMarks: { Math: 85 } } ]
    String? sectionId,
    String? academicYear,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        'schoolId': schoolId,
        'classId':  classId,
        'examType': examType,
        'term':     term,
        'maxMarks': maxMarks,
        'entries':  entries,
        if (sectionId    != null) 'sectionId':    sectionId,
        if (academicYear != null) 'academicYear': academicYear,
      };

      final response = await _apiService.post(
        ApiConstants.uploadMarks,
        data: data,
      );

      if (response.data['ok'] == true) {
        _showSnackbar(
            'Success', 'Marks uploaded successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error',
            response.data['message'] ?? 'Failed to upload marks',
            AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar(
          'Error', 'An error occurred while uploading marks', AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── 3. Update a single student's marks ────────────────────────────────────
  // PUT /api/marks/update/:marksId
  Future<bool> updateStudentMarks({
    required String marksId,
    required Map<String, int> subjectMarks,
    int? maxMarks,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        'subjectMarks': subjectMarks,
        if (maxMarks != null) 'maxMarks': maxMarks,
      };

      final response = await _apiService.put(
        '${ApiConstants.updateMarks}/$marksId',
        data: data,
      );

      if (response.data['ok'] == true) {
        _showSnackbar(
            'Success', 'Marks updated successfully', AppTheme.successGreen);

        // Update local list without full reload
        final idx = marksList.indexWhere((m) => m['_id'] == marksId);
        if (idx != -1) {
          marksList[idx] = Map<String, dynamic>.from(marksList[idx])
            ..addAll(response.data['data'] ?? {});
          marksList.refresh();
        }
        return true;
      } else {
        _showSnackbar('Error',
            response.data['message'] ?? 'Failed to update marks',
            AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar(
          'Error', 'An error occurred while updating marks', AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── 4. Get all marks for a single student ─────────────────────────────────
  // GET /api/marks/getstudentmarks
  Future<List<Map<String, dynamic>>?> getMarksByStudent({
    required String studentId,
    required String schoolId,
    String? examType,
    String? term,
    String? academicYear,
  }) async {
    try {
      isLoading.value = true;

      final queryParams = {
        'studentId': studentId,
        'schoolId':  schoolId,
        if (examType     != null) 'examType':    examType,
        if (term         != null) 'term':        term,
        if (academicYear != null) 'academicYear': academicYear,
      };

      final response = await _apiService.get(
        ApiConstants.getStudentMarks,
        queryParameters: queryParams,
      );

      if (response.data['ok'] == true) {
        final data = List<Map<String, dynamic>>.from(
            response.data['data'] ?? []);
        studentMarksList.value = data;
        return data;
      } else {
        _showSnackbar('Error',
            response.data['message'] ?? 'Failed to fetch student marks',
            AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error',
          'An error occurred while fetching student marks', AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── 5. Delete a marks record ──────────────────────────────────────────────
  // DELETE /api/marks/delete/:marksId
  Future<bool> deleteMarks(String marksId) async {
    try {
      isLoading.value = true;

      final response = await _apiService.delete(
        '${ApiConstants.deleteMarks}/$marksId',
      );

      if (response.data['ok'] == true) {
        marksList.removeWhere((m) => m['_id'] == marksId);
        _showSnackbar('Deleted', 'Marks record deleted', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error',
            response.data['message'] ?? 'Failed to delete marks',
            AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar(
          'Error', 'An error occurred while deleting marks', AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── 6. Validate before upload ─────────────────────────────────────────────
  bool validateMarksData({
    required String schoolId,
    required String classId,
    required String examType,
    required String term,
    required int maxMarks,
    required List<Map<String, dynamic>> entries,
  }) {
    if (schoolId.isEmpty || classId.isEmpty ||
        examType.isEmpty || term.isEmpty) {
      _showSnackbar(
          'Error', 'Required fields are missing', AppTheme.errorRed);
      return false;
    }

    if (maxMarks <= 0) {
      _showSnackbar(
          'Error', 'Max marks must be greater than 0', AppTheme.errorRed);
      return false;
    }

    if (entries.isEmpty) {
      _showSnackbar('Error', 'No marks entries provided', AppTheme.errorRed);
      return false;
    }

    for (final entry in entries) {
      if (entry['studentId'] == null || entry['subjectMarks'] == null) {
        _showSnackbar(
            'Error', 'Invalid marks entry format', AppTheme.errorRed);
        return false;
      }

      // Check no mark exceeds maxMarks
      final subjectMarks = entry['subjectMarks'] as Map<String, dynamic>;
      for (final mark in subjectMarks.values) {
        if ((mark as int) > maxMarks) {
          _showSnackbar('Error',
              'A mark exceeds the maximum of $maxMarks', AppTheme.errorRed);
          return false;
        }
      }
    }

    return true;
  }

  // ─── 7. Grade helper (client-side) ─────────────────────────────────────────
  static String computeGrade(int marks, int maxMarks) {
    if (maxMarks == 0) return '—';
    final pct = marks / maxMarks * 100;
    if (pct >= 90) return 'A+';
    if (pct >= 75) return 'A';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 35) return 'D';
    return 'F';
  }

  // ─── 8. Clear state ────────────────────────────────────────────────────────
  void clearMarks() {
    marksList.clear();
    studentMarksList.clear();
  }
}