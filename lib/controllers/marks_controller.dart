import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/services/api_service.dart';

class MarksController extends GetxController {
  final ApiService _apiService = Get.find();

  final isLoading = false.obs;

  void _snack(String title, String msg, {bool error = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isSnackbarOpen != true) {
        Get.snackbar(title, msg,
            backgroundColor: error ? AppTheme.errorRed : AppTheme.successGreen,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3));
      }
    });
  }

  // ─── Mark Report Config ────────────────────────────────────────────────────

  /// GET /api/markreport/config/by-class
  Future<Map<String, dynamic>?> getConfig({
    required String schoolId,
    required String classId,
    required String academicYear,
  }) async {
    try {
      final resp = await _apiService.get(
        ApiConstants.getMarkReportConfigByClass,
        queryParameters: {
          'schoolId': schoolId,
          'classId': classId,
          'academicYear': academicYear,
        },
      );
      if (resp.data['ok'] == true) {
        return resp.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// POST /api/markreport/config/create
  Future<Map<String, dynamic>?> createConfig({
    required String schoolId,
    required String classId,
    required String academicYear,
    required List<Map<String, dynamic>> subjects,
    required List<Map<String, dynamic>> exams,
  }) async {
    try {
      final resp = await _apiService.post(
        ApiConstants.createMarkReportConfig,
        data: {
          'schoolId': schoolId,
          'classId': classId,
          'academicYear': academicYear,
          'subjects': subjects,
          'exams': exams,
        },
      );
      if (resp.data['ok'] == true) {
        _snack('Saved', 'Configuration created successfully');
        return resp.data['data'] as Map<String, dynamic>?;
      }
      _snack('Error', resp.data['message'] ?? 'Failed to create config', error: true);
      return null;
    } catch (_) {
      _snack('Error', 'Failed to create configuration', error: true);
      return null;
    }
  }

  /// PUT /api/markreport/config/update/:configId
  Future<bool> updateConfig({
    required String configId,
    required List<Map<String, dynamic>> subjects,
    required List<Map<String, dynamic>> exams,
  }) async {
    try {
      final resp = await _apiService.put(
        '${ApiConstants.updateMarkReportConfig}/$configId',
        data: {'subjects': subjects, 'exams': exams},
      );
      if (resp.data['ok'] == true) {
        _snack('Saved', 'Configuration updated successfully');
        return true;
      }
      _snack('Error', resp.data['message'] ?? 'Failed to update config', error: true);
      return false;
    } catch (_) {
      _snack('Error', 'Failed to update configuration', error: true);
      return false;
    }
  }

  // ─── Mark Reports v1 ───────────────────────────────────────────────────────

  /// GET /api/markreport/v1/get-all
  Future<List<Map<String, dynamic>>> getAllMarkReports({
    required String schoolId,
    required String classId,
    String? sectionId,
    String? academicYear,
    String? studentId,
  }) async {
    try {
      final resp = await _apiService.get(
        ApiConstants.getAllMarkReportsV1,
        queryParameters: {
          'schoolId': schoolId,
          'classId': classId,
          if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
          if (academicYear != null) 'academicYear': academicYear,
          if (studentId != null) 'studentId': studentId,
        },
      );
      if (resp.data['ok'] == true) {
        return List<Map<String, dynamic>>.from(resp.data['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// POST /api/markreport/v1/create
  Future<Map<String, dynamic>?> createMarkReport({
    required String schoolId,
    required String classId,
    String? sectionId,
    required String studentId,
    required String academicYear,
    required String markReportConfigId,
    required List<Map<String, dynamic>> examRecords,
    String? remarks,
    bool isAbsent = false,
  }) async {
    try {
      final resp = await _apiService.post(
        ApiConstants.createMarkReportV1,
        data: {
          'schoolId': schoolId,
          'classId': classId,
          if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
          'studentId': studentId,
          'academicYear': academicYear,
          'markReportConfigId': markReportConfigId,
          'examRecords': examRecords,
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
          'isAbsent': isAbsent,
        },
      );
      if (resp.data['ok'] == true) return resp.data['data'] as Map<String, dynamic>?;
      _snack('Error', resp.data['message'] ?? 'Failed to save marks', error: true);
      return null;
    } catch (_) {
      _snack('Error', 'Failed to save marks', error: true);
      return null;
    }
  }

  /// PUT /api/markreport/v1/update/:reportId
  Future<bool> updateMarkReport({
    required String reportId,
    required String classId,
    String? sectionId,
    required String studentId,
    required String academicYear,
    required List<Map<String, dynamic>> examRecords,
    String? markReportConfigId,
    String? remarks,
    bool isAbsent = false,
  }) async {
    try {
      final resp = await _apiService.put(
        '${ApiConstants.updateMarkReportV1}/$reportId',
        data: {
          'classId': classId,
          if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
          'studentId': studentId,
          'academicYear': academicYear,
          'examRecords': examRecords,
          if (markReportConfigId != null) 'markReportConfigId': markReportConfigId,
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
          'isAbsent': isAbsent,
        },
      );
      if (resp.data['ok'] == true) return true;
      _snack('Error', resp.data['message'] ?? 'Failed to update marks', error: true);
      return false;
    } catch (_) {
      _snack('Error', 'Failed to update marks', error: true);
      return false;
    }
  }

  /// DELETE /api/markreport/v1/delete/:reportId
  Future<bool> deleteMarkReport(String reportId) async {
    try {
      final resp = await _apiService.delete(
        '${ApiConstants.deleteMarkReportV1}/$reportId',
      );
      if (resp.data['ok'] == true) {
        _snack('Deleted', 'Mark report deleted');
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}