import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

import 'package:school_app/core/theme/app_theme.dart';

/// Utility class for standardized error handling across the app
class ErrorHandler {
  /// Shows error message from API response or DioException
  static void showError(dynamic error, [String fallbackMessage = 'Operation failed']) {
    String errorMessage = fallbackMessage;

    if (error is DioException && error.response?.data != null) {
      final responseData = error.response!.data;
      if (responseData is Map && responseData.containsKey('message')) {
        errorMessage = responseData['message'];
      } else if (error.response?.statusCode == 400) {
        errorMessage = 'Invalid request data. Please check all fields.';
      } else {
        errorMessage = 'Server error: ${error.response?.statusCode}';
      }
    } else if (error is Map && error.containsKey('message')) {
      // Handle API response error objects
      errorMessage = error['message'];
    }

    Get.snackbar(
      'Error',
      errorMessage,
      backgroundColor: AppTheme.errorRed,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  /// Shows success message
  static void showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: AppTheme.successGreen,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  /// Handles API response and shows appropriate message
  static bool handleApiResponse(dynamic response, {String successMessage = 'Operation successful'}) {
    if (response != null && response['ok'] == true) {
      showSuccess(successMessage);
      return true;
    } else {
      final errorMessage = response?['message'] ?? 'Operation failed';
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
      return false;
    }
  }
}
