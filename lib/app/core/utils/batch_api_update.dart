import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'api_loading_helper.dart';
import '../../core/theme/app_theme.dart';

/// Batch update utility for converting manual API calls to use ApiLoadingHelper
/// This file contains examples and patterns for updating API calls across the project

class BatchApiUpdate {

  /// Example: Convert a manual API call with try-catch to use ApiLoadingHelper
  ///
  /// BEFORE:
  /// ```dart
  /// try {
  ///   await someApiCall();
  ///   Get.snackbar('Success', 'Operation completed');
  /// } catch (e) {
  ///   Get.snackbar('Error', 'Operation failed: $e');
  /// }
  /// ```
  ///
  /// AFTER:
  /// ```dart
  /// await ApiLoadingHelper.executeVoid(
  ///   () => someApiCall(),
  ///   loadingMessage: 'Processing...',
  ///   successMessage: 'Operation completed successfully',
  /// );
  /// ```

  /// Pattern 1: Void operations (create, update, delete)
  static Future<bool> updateVoidOperation(
    Future<void> Function() apiCall, {
    String loadingMessage = 'Updating...',
    String? successMessage,
    String? errorMessage,
  }) {
    return ApiLoadingHelper.executeVoid(
      apiCall,
      loadingMessage: loadingMessage,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  /// Pattern 2: Operations that return data
  static Future<T?> updateDataOperation<T>(
    Future<T> Function() apiCall, {
    String loadingMessage = 'Loading...',
    String? successMessage,
    String? errorMessage,
  }) {
    return ApiLoadingHelper.executeWithLoading<T>(
      apiCall,
      loadingMessage: loadingMessage,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  /// Pattern 3: Quick operations without custom messages
  static Future<T?> quickCall<T>(
    Future<T> Function() apiCall, {
    String loadingMessage = 'Loading...',
  }) {
    return ApiLoadingHelper.call(apiCall, loadingMessage: loadingMessage);
  }

  /// Common API call patterns found in the project:
  ///
  /// 1. Controller methods that show snackbars:
  ///    - getAllClubs(), createClub(), updateClub(), deleteClub()
  ///    - uploadClubVideo(), updateVideoDetails(), deleteClubVideo()
  ///    - login(), logout(), isAuthenticated()
  ///    - getAllSchools(), getAllClasses(), getAllSections()
  ///
  /// 2. View methods with manual loading dialogs:
  ///    - Video upload dialogs, form submissions
  ///    - CRUD operations in various views
  ///
  /// 3. Silent background calls:
  ///    - Data refresh operations
  ///    - Cache updates

  /// Helper method to show custom snackbar
  static void showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: AppTheme.successGreen.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  static void showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: AppTheme.errorRed.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  static void showWarningSnackbar(String message) {
    Get.snackbar(
      'Warning',
      message,
      backgroundColor: AppTheme.warningYellow.withOpacity(0.9),
      colorText: Colors.black,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.warning, color: Colors.black),
    );
  }
}

/// Extension methods for easier API call wrapping
extension ApiCallExtensions on Future<void> Function() {
  Future<bool> withLoading({
    String loadingMessage = 'Loading...',
    String? successMessage,
    String? errorMessage,
  }) {
    return ApiLoadingHelper.executeVoid(
      this,
      loadingMessage: loadingMessage,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

extension ApiCallExtensionsWithReturn<T> on Future<T> Function() {
  Future<T?> withLoading({
    String loadingMessage = 'Loading...',
    String? successMessage,
    String? errorMessage,
  }) {
    return ApiLoadingHelper.executeWithLoading<T>(
      this,
      loadingMessage: loadingMessage,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

