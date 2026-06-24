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

      debugPrint('🔵 getCustomFeeHeads called: schoolId=$schoolId classId=$classId type=$type');

      final response = await _apiService.get(
        '/api/feestructure/v1/getbyclass',
        queryParameters: {'schoolId': schoolId, 'classId': classId},
      );

      debugPrint('📥 raw response: ${response.data}');

      final List<Map<String, dynamic>> processedHeads = [];

      if (response.data != null && response.data['ok'] == true) {
        final dynamic rawData = response.data['data'];
        debugPrint('📥 data field type: ${rawData.runtimeType}');

        if (rawData is List) {
          debugPrint('📥 data list length: ${rawData.length}');

          final dynamic matchedRecord = rawData.firstWhere(
                (element) => element != null && element['type']?.toString() == type,
            orElse: () => null,
          );

          debugPrint('📥 matchedRecord for type="$type": $matchedRecord');

          if (matchedRecord != null && matchedRecord is Map) {
            debugPrint('📥 feeHead field: ${matchedRecord['feeHead']}');
            debugPrint('📥 feeHeads field: ${matchedRecord['feeHeads']}');

            if (matchedRecord['feeHeads'] != null &&
                matchedRecord['feeHeads'] is Map) {
              final Map customMap = matchedRecord['feeHeads'];
              debugPrint('📥 feeHeads map entries: ${customMap.entries.map((e) => "${e.key}:${e.value}(${e.value.runtimeType})").toList()}');

              customMap.forEach((key, value) {
                // ✅ Parse value safely regardless of type from backend
                double amount;
                if (value is double) {
                  amount = value;
                } else if (value is int) {
                  amount = value.toDouble();
                } else if (value is String) {
                  amount = double.tryParse(value) ?? 0.0;
                  debugPrint('⚠️ feeHeads value for "$key" was String "$value" — parsed to $amount');
                } else {
                  amount = 0.0;
                  debugPrint('⚠️ feeHeads value for "$key" unexpected type ${value.runtimeType}');
                }

                processedHeads.add({
                  'id':         key.toString(),
                  'feeName':    key.toString(),
                  'feeAmount':  amount,
                  'isStandard': false,
                });

                debugPrint('   processed: feeName="${key}" feeAmount=$amount');
              });
            } else {
              debugPrint('⚠️ feeHeads is null or not a Map');
            }
          } else {
            debugPrint('⚠️ No record matched type="$type" in data list');
          }
        }
      } else {
        debugPrint('⚠️ response ok=false or data null');
      }

      debugPrint('📥 processedHeads final: $processedHeads');
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
    required List<Map<String, dynamic>> feeHeads,
    String type = 'old',
  }) async {
    try {
      isLoading.value = true;

      debugPrint('🔵 saveAllCustomFeeHeads called');
      debugPrint('   schoolId: $schoolId');
      debugPrint('   classId:  $classId');
      debugPrint('   type:     $type');
      debugPrint('   feeHeads: $feeHeads');

      // Check types explicitly
      for (final h in feeHeads) {
        debugPrint('   → feeName: "${h['feeName']}" (${h['feeName'].runtimeType})');
        debugPrint('   → feeAmount: ${h['feeAmount']} (${h['feeAmount'].runtimeType})');
      }

      if (type != 'old' && type != 'new') {
        _showSnackbar('Error', 'Invalid student type', AppTheme.errorRed);
        return false;
      }

      // final feeHeadNames = feeHeads
      //     .map((h) => h['feeName']?.toString() ?? '')
      //     .where((n) => n.isNotEmpty)
      //     .toList();
      //
      // debugPrint('🔵 ensureFeeConfig with names: $feeHeadNames');
      //
      // if (feeHeadNames.isNotEmpty) {
      //   final configOk = await ensureFeeConfig(
      //     schoolId: schoolId,
      //     feeHeads: feeHeadNames,
      //     isActive: true,
      //   );
      //   debugPrint('🔵 ensureFeeConfig result: $configOk');
      //   if (!configOk) return false;
      // }

      // Build feeHeads map — ensure amounts are doubles not strings
      final feeHeadsMap = <String, dynamic>{};
      for (final h in feeHeads) {
        final name = h['feeName']?.toString() ?? '';
        if (name.isNotEmpty) {
          // ✅ Force to double regardless of what was passed in
          final rawAmount = h['feeAmount'];
          double amount;
          if (rawAmount is double) {
            amount = rawAmount;
          } else if (rawAmount is int) {
            amount = rawAmount.toDouble();
          } else if (rawAmount is String) {
            amount = double.tryParse(rawAmount) ?? 0.0;
            debugPrint('⚠️ feeAmount was a String "$rawAmount" — converted to $amount');
          } else {
            amount = 0.0;
            debugPrint('⚠️ feeAmount was unexpected type ${rawAmount.runtimeType} — defaulted to 0.0');
          }
          feeHeadsMap[name] = amount;
          debugPrint('   mapped: "$name" → $amount (${amount.runtimeType})');
        }
      }

      final payload = {
        'schoolId': schoolId,
        'classId':  classId,
        'type':     type.toLowerCase(),
        'feeHead': feeHeadsMap,
      };

      debugPrint('📤 Final payload: $payload');

      final response = await _apiService.post(
        '/api/feestructure/v1/set',
        data: payload,
      );

      debugPrint('📥 saveAllCustomFeeHeads response: ${response.data}');

      if (response.data['ok'] == true) {
        debugPrint('✅ Save successful');
        return true;
      } else {
        debugPrint('❌ Save failed: ${response.data['message']}');
        _showSnackbar('Error',
            response.data['message'] ?? 'Failed to save fee heads',
            AppTheme.errorRed);
        return false;
      }
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data.toString())
          : e.response?.data?.toString();
      debugPrint('❌ DioException: ${e.response?.statusCode}');
      debugPrint('❌ Body: ${e.response?.data}');
      _showSnackbar('Error',
          serverMessage ?? 'Failed to save fee heads',
          AppTheme.errorRed);
      return false;
    } catch (e, stack) {
      debugPrint('❌ Unexpected error: $e');
      debugPrint('❌ Stack: $stack');
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
  // FEE CONFIG (v1)  →  POST /api/fee-config/v1/set/:schoolId
  // ══════════════════════════════════════════════════════════════

  /// Fetch the school's current fee-config head objects as-is
  /// (each: { _id, feeHead, associatedTerm, isTerm }).
  Future<List<Map<String, dynamic>>> getFeeConfigHeads(String schoolId) async {
    try {
      final response = await _apiService.get('/api/fee-config/get/$schoolId');
      if (response.data != null && response.data['ok'] == true) {
        debugPrint('📥 fee-config/get raw: ${response.data}');
        final data = response.data['data'];
        if (data != null && data['feeHeads'] is List) {
          return List<Map<String, dynamic>>.from(data['feeHeads']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ getFeeConfigHeads error: $e');
      return [];
    }
  }

  /// Create/update fee config using the new v1 (term-aware) endpoint.
  /// [feeHeads] entries: { feeHead, associatedTerm, isTerm, _id? }
  /// — include '_id' for heads that already exist so the backend
  /// updates them instead of duplicating.
  Future<bool> ensureFeeConfigV1({
    required String schoolId,
    required List<Map<String, dynamic>> feeHeads,
    bool isActive = true,
  }) async {
    try {
      debugPrint('📤 ensureFeeConfigV1: schoolId=$schoolId, feeHeads=$feeHeads');

      final response = await _apiService.post(
        '/api/fee-config/v1/set/$schoolId',
        data: {
          'feeHeads': feeHeads,
          'isActive': isActive,
        },
      );

      debugPrint('📥 ensureFeeConfigV1 response: ${response.data}');

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
      debugPrint('❌ ensureFeeConfigV1 400 body: ${e.response?.data}');
      _showSnackbar('Error',
          serverMessage ?? 'Failed to configure fee heads', AppTheme.errorRed);
      return false;
    } catch (e) {
      debugPrint('❌ ensureFeeConfigV1 error: $e');
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
      // final feeName = feeHead['feeName']?.toString() ?? '';
      // final configOk = await ensureFeeConfig(
      //   schoolId: schoolId,
      //   feeHeads: [feeName],
      //   isActive: true,
      // );
      // if (!configOk) return false;

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