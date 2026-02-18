import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/api_guard.dart';
import '../core/permissions/permission_system.dart';

class FeeStructureController extends GetxController {
  final ApiService _apiService = Get.find();
  
  final isLoading = false.obs;
  final feeStructures = <Map<String, dynamic>>[].obs;
  final allFeeStructures = <Map<String, dynamic>>[].obs;

  void _showSnackbar(String title, String message, Color color) {
    Get.snackbar(title, message, backgroundColor: color, colorText: Colors.white);
  }

  // Get all fee structures for a school
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

        // Debug each fee structure
        for (int i = 0; i < allFeeStructures.length; i++) {
          final fee = allFeeStructures[i];

        }
      } else {
        
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load fee structures', AppTheme.errorRed);
      }
    } catch (e) {
      
      _showSnackbar('Error', 'An error occurred while loading fee structures.', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  // Set fee structure for a class
  Future<void> setFeeStructure({
    required String schoolId,
    required String classId,
    required Map<String, dynamic> feeHead,
    String type = 'old',
  }) async {
    try {
      // Check permission before proceeding
      ApiGuard.enforcePermission(Permission.FEES_VIEW_REPORTS);
      
      isLoading.value = true;
      
      // Validate type parameter
      if (type != 'old' && type != 'new') {
        _showSnackbar('Error', 'Invalid student type. Must be "old" or "new"', AppTheme.errorRed);
        return;
      }

      final requestPayload = {
        'schoolId': schoolId,
        'classId': classId,
        'type': type.toString().toLowerCase(),
        'feeHead': feeHead,
      };

      final response = await _apiService.post(
        ApiConstants.setFeeStructure,
        data: requestPayload,
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Fee structure updated successfully', AppTheme.successGreen);
        await getFeeStructureByClass(schoolId, classId, type: type);
      } else {
        
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update fee structure', AppTheme.errorRed);
      }
    } catch (e) {
      
      if (e.toString().contains('Permission denied')) {
        return; // Error already shown by ApiGuard
      }
      _showSnackbar('Error', 'An error occurred while updating fee structure.', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  // Get fee structure by class
  Future<Map<String, dynamic>?> getFeeStructureByClass(String schoolId, String classId, {String type = 'old'}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.get(
        ApiConstants.getFeeStructure,
        queryParameters: {
          'schoolId': schoolId,
          'classId': classId,
          'type': type,
        },
      );

      if (response.data['ok'] == true) {
        final data = response.data['data'];

        // Handle case where API returns a list of fee structures
        if (data is List) {
          // Find the fee structure that matches the requested type
          final feeStructure = data.firstWhere(
            (item) => item['type'] == type,
            orElse: () => null,
          );

          if (feeStructure != null) {
            
            return {'data': feeStructure};
          } else {
            
            return null;
          }
        } else {
          // Handle case where API returns a single fee structure object
          
          return response.data['data'];
        }
      } else {
        
      }
      return null;
    } catch (e) {
      
      _showSnackbar('Error', 'Failed to load fee structure', AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}