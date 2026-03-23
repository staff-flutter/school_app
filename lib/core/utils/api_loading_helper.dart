import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/theme/app_theme.dart';

class ApiLoadingHelper {
  static Future<T?> executeWithLoading<T>(
    Future<T> Function() apiCall, {
    String loadingMessage = 'Loading...',
    String? successMessage,
    String? errorMessage,
    bool showSuccessSnackbar = true,
    bool showErrorSnackbar = true,
    bool showWarningSnackbar = false,
    String? warningMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
    VoidCallback? onWarning,
  }) async {
    // Show loading dialog
    _showLoadingDialog(loadingMessage);

    try {
      final result = await apiCall();

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Show success snackbar
      if (showSuccessSnackbar && successMessage != null) {
        Get.snackbar(
          'Success',
          successMessage,
          backgroundColor: AppTheme.successGreen.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      }

      // Call success callback
      onSuccess?.call();

      return result;
    } catch (e) {
      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Show error snackbar
      if (showErrorSnackbar) {
        final errorMsg = errorMessage ?? _getErrorMessage(e);
        Get.snackbar(
          'Error',
          errorMsg,
          backgroundColor: AppTheme.errorRed.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }

      // Show warning snackbar if needed
      if (showWarningSnackbar && warningMessage != null) {
        Get.snackbar(
          'Warning',
          warningMessage,
          backgroundColor: AppTheme.warningYellow.withOpacity(0.9),
          colorText: Colors.black,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.warning, color: Colors.black),
        );
      }

      // Call error/warning callbacks
      onError?.call();
      if (showWarningSnackbar && warningMessage != null) {
        onWarning?.call();
      }

      return null;
    }
  }

  static void _showLoadingDialog(String message) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final errorString = error.toString();
      if (errorString.contains('SocketException') || errorString.contains('Connection reset')) {
        return 'Network connection error. Please check your internet connection.';
      } else if (errorString.contains('timeout')) {
        return 'Request timed out. Please try again.';
      } else if (errorString.contains('404')) {
        return 'Resource not found. Please try again later.';
      } else if (errorString.contains('500')) {
        return 'Server error. Please try again later.';
      } else if (errorString.contains('401')) {
        return 'Authentication failed. Please login again.';
      } else if (errorString.contains('403')) {
        return 'Access denied. You don\'t have permission for this action.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Convenience method for quick API calls
  static Future<T?> call<T>(
    Future<T> Function() apiCall, {
    String loadingMessage = 'Loading...',
    String? successMessage,
  }) {
    return executeWithLoading(
      apiCall,
      loadingMessage: loadingMessage,
      successMessage: successMessage,
    );
  }

  // Method for operations that don't return data
  static Future<bool> executeVoid(
    Future<void> Function() apiCall, {
    String loadingMessage = 'Loading...',
    String? successMessage,
    String? errorMessage,
  }) async {
    final result = await executeWithLoading(
      () async {
        await apiCall();
        return true;
      },
      loadingMessage: loadingMessage,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
    return result ?? false;
  }
}

