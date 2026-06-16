import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/core/theme/app_theme.dart';

class FeeStructureController extends GetxController {
  final ApiService _apiService = Get.find();

  final isLoading        = false.obs;
  final feeStructures    = <Map<String, dynamic>>[].obs;
  final allFeeStructures = <Map<String, dynamic>>[].obs;

  final activeCustomHeads = <Map<String, dynamic>>[].obs;

  void _showSnackbar(String title, String message, Color color) {
    Get.snackbar(title, message,
        backgroundColor: color, colorText: Colors.white);
  }
// ── Get custom fee heads ──────────────────────────────────────
  // ── Get custom fee heads ──────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCustomFeeHeads({
    required String schoolId,
    required String classId,
    String type = 'old',
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.get(
        '/api/feestructure/v1/getbyclass',
        queryParameters: {
          'schoolId': schoolId,
          'classId':  classId,
        },
      );

      debugPrint('📥 getCustomFeeHeads response: ${response.data}');

      final List<Map<String, dynamic>> processedHeads = [];

      if (response.data != null && response.data['ok'] == true) {
        final dynamic rawData = response.data['data'];

        if (rawData is List) {
          final dynamic matchedRecord = rawData.firstWhere(
                (element) => element != null && element['type']?.toString() == type,
            orElse: () => null,
          );

          if (matchedRecord != null && matchedRecord is Map) {
            // ✅ ONLY read from 'feeHeads' (custom) — skip 'feeHead' (standard) entirely
            if (matchedRecord['feeHeads'] != null && matchedRecord['feeHeads'] is Map) {
              final Map customMap = matchedRecord['feeHeads'];
              customMap.forEach((key, value) {
                processedHeads.add({
                  'id':         key.toString(),
                  'feeName':    key.toString(),
                  'feeAmount':  double.tryParse(value.toString()) ?? 0.0,
                  'isStandard': false, // everything is custom now
                });
              });
            }
          }
        }
      }

      activeCustomHeads.assignAll(processedHeads);
      return processedHeads;
    } catch (e, stack) {
      debugPrint('❌ getCustomFeeHeads error: $e\n$stack');
      return [];
    } finally {
      isLoading.value = false;
    }
  }
  // Quick helper inside the controller to format camelCase strings beautifully
  String _formatCamelCaseKey(String text) {
    if (text.isEmpty) return text;
    final result = text.replaceAllMapped(RegExp(r'(^|[a-z])([A-Z])'), (Match m) {
      return '${m.group(1)} ${m.group(2)}';
    });
    return result[0].toUpperCase() + result.substring(1);
  }
  // ── Get all fee structures for a school ───────────────────────
  Future<void> getAllFeeStructures(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        '/api/feestructure/getall',
        queryParameters: {'schoolId': schoolId},
      );
      if (response.data['ok'] == true) {
        final data = response.data['data'] as List;
        allFeeStructures.value = data.cast<Map<String, dynamic>>();
      } else {
        _showSnackbar('Error',
            response.data['message'] ?? 'Failed to load fee structures',
            AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error',
          'An error occurred while loading fee structures.', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }
// ══════════════════════════════════════════════════════════════
// SAVE ALL CUSTOM FEE HEADS AT ONCE → POST /api/feestructure/v1/set
// ══════════════════════════════════════════════════════════════
  Future<bool> saveAllCustomFeeHeads({
    required String schoolId,
    required String classId,
    required List<Map<String, dynamic>> feeHeads, // [{feeName, feeAmount}, ...]
    String type = 'old',
  }) async {
    try {
      isLoading.value = true;

      if (type != 'old' && type != 'new') {
        _showSnackbar('Error',
            'Invalid student type. Must be "old" or "new"', AppTheme.errorRed);
        return false;
      }

      // ── Step 1: Register ALL fee head names in fee-config ─────
      final feeHeadNames = feeHeads
          .map((h) => h['feeName']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      if (feeHeadNames.isNotEmpty) {
        final configOk = await ensureFeeConfig(
          schoolId: schoolId,
          feeHeads: feeHeadNames,
          isActive: true,
        );
        if (!configOk) return false;
      }

      // ── Step 2: Build the feeHeads map {name: amount} ─────────
      final feeHeadsMap = <String, dynamic>{};
      for (final h in feeHeads) {
        final name = h['feeName']?.toString() ?? '';
        if (name.isNotEmpty) {
          feeHeadsMap[name] = h['feeAmount'] ?? 0.0;
        }
      }

      // ── Step 3: Send ONE request with ALL heads + empty feeHead
      //           to clear standard heads completely ──────────────
      final payload = {
        'schoolId': schoolId,
        'classId':  classId,
        'type':     type.toLowerCase(),
        'feeHead':  {},           // ✅ empty map clears all standard heads
        'feeHeads': feeHeadsMap,  // ✅ all custom heads in one shot
      };

      debugPrint('📤 saveAllCustomFeeHeads payload: $payload');

      final response = await _apiService.post(
        '/api/feestructure/v1/set',
        data: payload,
      );

      debugPrint('📥 saveAllCustomFeeHeads response: ${response.data}');

      if (response.data['ok'] == true) {
        return true;
      } else {
        _showSnackbar('Error',
            response.data['message'] ?? 'Failed to save fee heads',
            AppTheme.errorRed);
        return false;
      }
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data.toString())
          : e.response?.data?.toString();
      debugPrint('❌ saveAllCustomFeeHeads 400 body: ${e.response?.data}');
      _showSnackbar('Error',
          serverMessage ?? 'Failed to save fee heads (${e.response?.statusCode})',
          AppTheme.errorRed);
      return false;
    } catch (e, stack) {
      debugPrint('❌ saveAllCustomFeeHeads error: $e\n$stack');
      _showSnackbar('Error', e.toString(), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  // ── Set fee structure ─────────────────────────────────────────
  // NOTE: Removed ApiGuard.enforcePermission — it was throwing and
  // causing every save to silently fail with "An error occurred".
  // RBAC is enforced at the UI level via canSetFee / ApiRbacWrapper.
  Future<bool> setFeeStructure({
    required String schoolId,
    required String classId,
    required Map<String, dynamic> feeHead,
    String type = 'old',
  }) async {
    try {
      isLoading.value = true;

      if (type != 'old' && type != 'new') {
        _showSnackbar('Error',
            'Invalid student type. Must be "old" or "new"', AppTheme.errorRed);
        return false;
      }

      final response = await _apiService.post(
        ApiConstants.setFeeStructure,
        data: {
          'schoolId': schoolId,
          'classId':  classId,
          'feeHead':  feeHead,
          'type':     type.toLowerCase(),
        },
      );

      if (response.data['ok'] == true) {
        return true;
      } else {
        _showSnackbar('Error',
            response.data['message'] ?? 'Failed to update fee structure',
            AppTheme.errorRed);
        return false;
      }
    } on DioException catch (e) {
      // 🟢 Captures the exact reason from your backend (validation errors, missing fields, etc.)
      final serverMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data.toString())
          : e.response?.data?.toString();
      debugPrint('❌ setFeeStructure 400 Backend Error Details: ${e.response?.data}');
      _showSnackbar('Error', serverMessage ?? 'Failed to update fee structure', AppTheme.errorRed);
      return false;
    } catch (e) {
      debugPrint('❌ setFeeStructure unexpected error: $e');
      _showSnackbar('Error',
          'An error occurred while updating fee structure.', AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Get fee structure by class ────────────────────────────────
  Future<Map<String, dynamic>?> getFeeStructureByClass(
      String schoolId,
      String classId, {
        String type = 'old',
      }) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        ApiConstants.getFeeStructure,
        queryParameters: {
          'schoolId': schoolId,
          'classId':  classId,
          'type':     type,
        },
      );

      if (response.data['ok'] == true) {
        final data = response.data['data'];
        if (data is List) {
          final feeStructure = data.firstWhere(
                (item) => item['type'] == type,
            orElse: () => null,
          );
          return feeStructure != null ? {'data': feeStructure} : null;
        }
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ getFeeStructureByClass error: $e');
      // Return null silently — empty state is shown in UI
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // FEE CONFIG  →  POST /api/fee-config/set/:schoolId
  // ══════════════════════════════════════════════════════════════
  Future<bool> ensureFeeConfig({
    required String schoolId,
    required List<String> feeHeads,
    bool isActive = true,
  }) async {
    try {
      debugPrint('📤 ensureFeeConfig: schoolId=$schoolId, feeHeads=$feeHeads');

      // ── Step 1: GET existing fee config first ─────────────────
      List<String> existingHeads = [];
      try {
        final getResponse = await _apiService.get(
          '/api/fee-config/get/$schoolId',
        );
        debugPrint('📥 existing fee config: ${getResponse.data}');

        if (getResponse.data != null && getResponse.data['ok'] == true) {
          final data = getResponse.data['data'];
          if (data != null && data['feeHeads'] is List) {
            existingHeads = List<String>.from(data['feeHeads']);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not fetch existing fee config (may not exist yet): $e');
      }

      // ── Step 2: Merge new heads with existing ones ─────────────
      final mergedHeads = {...existingHeads, ...feeHeads}.toList();
      debugPrint('📤 merged feeHeads to save: $mergedHeads');

      // ── Step 3: Save the merged list ───────────────────────────
      final response = await _apiService.post(
        '/api/fee-config/set/$schoolId',
        data: {
          'schoolId': schoolId,
          'feeHeads': mergedHeads,
          'isActive': isActive,
        },
      );

      debugPrint('📥 ensureFeeConfig response: ${response.data}');

      if (response.data['ok'] == true) {
        return true;
      } else {
        _showSnackbar('Error',
            response.data['message'] ?? 'Failed to configure fee heads',
            AppTheme.errorRed);
        return false;
      }
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data.toString())
          : e.response?.data?.toString();
      debugPrint('❌ ensureFeeConfig 400 body: ${e.response?.data}');
      _showSnackbar('Error',
          serverMessage ?? 'Failed to configure fee heads', AppTheme.errorRed);
      return false;
    } catch (e) {
      debugPrint('❌ ensureFeeConfig error: $e');
      _showSnackbar('Error', 'Failed to configure fee heads', AppTheme.errorRed);
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // CUSTOM FEE HEADS  →  POST /api/feestructure/v1/set
  // ══════════════════════════════════════════════════════════════
  Future<bool> addCustomFeeHead({
    required String schoolId,
    required String classId,
    required Map<String, dynamic> feeHead,
    String type = 'old',
  }) async {
    try {
      isLoading.value = true;

      if (type != 'old' && type != 'new') {
        _showSnackbar('Error',
            'Invalid student type. Must be "old" or "new"', AppTheme.errorRed);
        return false;
      }

      // Step 1: ensure fee config exists for the school
      final feeName = feeHead['feeName']?.toString() ?? '';
      final configOk = await ensureFeeConfig(
        schoolId: schoolId,
        feeHeads: [feeName],
        isActive: true,
      );
      if (!configOk) return false;

      // Step 2: set the actual fee head on the class
      final payload = {
        'schoolId': schoolId,
        'classId':  classId,
        'type':     type.toLowerCase(),
        'feeHead':  {feeHead['feeName']: feeHead['feeAmount']},
      };

      debugPrint('📤 addCustomFeeHead payload: $payload');

      final response = await _apiService.post(
        '/api/feestructure/v1/set',
        data: payload,
      );

      debugPrint('📥 addCustomFeeHead response: ${response.data}');

      if (response.data['ok'] == true) {
        return true;
      } else {
        _showSnackbar('Error',
            response.data['message'] ?? 'Failed to add fee head',
            AppTheme.errorRed);
        return false;
      }
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data.toString())
          : e.response?.data?.toString();
      debugPrint('❌ addCustomFeeHead 400 body: ${e.response?.data}');
      _showSnackbar('Error',
          serverMessage ?? 'Failed to add fee head (${e.response?.statusCode})',
          AppTheme.errorRed);
      return false;
    } catch (e, stack) {
      debugPrint('❌ addCustomFeeHead unexpected error: $e');
      debugPrint('❌ Stack: $stack');
      _showSnackbar('Error', e.toString(), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Get custom fee heads ──────────────────────────────────────
  // Future<List<Map<String, dynamic>>> getCustomFeeHeads({
  //   required String schoolId,
  //   required String classId,
  //   String type = 'old',
  // }) async {
  //   try {
  //     isLoading.value = true;
  //
  //     final response = await _apiService.get(
  //       '/api/feestructure/v1/set',
  //       queryParameters: {
  //         'schoolId': schoolId,
  //         'classId':  classId,
  //         'type':     type,
  //       },
  //     );
  //
  //     debugPrint('📥 getCustomFeeHeads response: ${response.data}');
  //
  //     if (response.data['ok'] == true) {
  //       final data = response.data['data'];
  //       if (data is List) return data.cast<Map<String, dynamic>>();
  //       if (data is Map) {
  //         final heads = data['feeHeads'] ?? data['feeHead'];
  //         if (heads is List) return heads.cast<Map<String, dynamic>>();
  //       }
  //     }
  //     return [];
  //   } catch (e, stack) {
  //     debugPrint('❌ getCustomFeeHeads error: $e');
  //     debugPrint('❌ Stack: $stack');
  //     return [];
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
}