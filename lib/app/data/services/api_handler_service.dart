import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'api_service.dart';

class ApiHandlerService extends GetxService {
  static ApiHandlerService get to => Get.find();

  // Show loading dialog
  void _showLoadingDialog() {
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );
  }

  // Hide loading dialog
  void _hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Navigator.pop(Get.context!);
    }
  }

  // Show response snackbar
  void _showResponseSnackBar(bool isSuccess, String message) {
    try {
      Get.snackbar(
        isSuccess ? 'Success' : 'Error',
        message,
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: Colors.white,
        ),
      );
    } catch (e) {
      // Fallback: print to console if snackbar can't be shown

    }
  }

  // Handle API call with loading and response handling
  Future<T?> handleApiCall<T>(
    Future<T> Function() apiCall, {
    bool showLoading = true,
    bool showSuccessSnackBar = true,
    bool showErrorSnackBar = true,
    String? successMessage,
    String? errorMessage,
  }) async {
    if (showLoading) {
      _showLoadingDialog();
    }

    try {
      final result = await apiCall();

      if (showLoading) {
        _hideLoadingDialog();
      }

      if (showSuccessSnackBar && successMessage != null) {
        _showResponseSnackBar(true, successMessage);
      }

      return result;
    } catch (e) {
      if (showLoading) {
        _hideLoadingDialog();
      }

      if (showErrorSnackBar) {
        final message = errorMessage ?? 'An error occurred';
        _showResponseSnackBar(false, message);
      }

      return null;
    }
  }

  // Convenience methods for different HTTP methods
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool showLoading = true,
    bool showSuccessSnackBar = false,
    bool showErrorSnackBar = true,
    String? successMessage,
    String? errorMessage,
  }) async {
    return handleApiCall(
      () => Get.find<ApiService>().get(endpoint, queryParameters: queryParameters),
      showLoading: showLoading,
      showSuccessSnackBar: showSuccessSnackBar,
      showErrorSnackBar: showErrorSnackBar,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    bool showLoading = true,
    bool showSuccessSnackBar = false,
    bool showErrorSnackBar = true,
    String? successMessage,
    String? errorMessage,
  }) async {
    return handleApiCall(
      () => Get.find<ApiService>().post(endpoint, data: data),
      showLoading: showLoading,
      showSuccessSnackBar: showSuccessSnackBar,
      showErrorSnackBar: showErrorSnackBar,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    bool showLoading = true,
    bool showSuccessSnackBar = false,
    bool showErrorSnackBar = true,
    String? successMessage,
    String? errorMessage,
  }) async {
    return handleApiCall(
      () => Get.find<ApiService>().put(endpoint, data: data),
      showLoading: showLoading,
      showSuccessSnackBar: showSuccessSnackBar,
      showErrorSnackBar: showErrorSnackBar,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    bool showLoading = true,
    bool showSuccessSnackBar = false,
    bool showErrorSnackBar = true,
    String? successMessage,
    String? errorMessage,
  }) async {
    return handleApiCall(
      () => Get.find<ApiService>().delete(endpoint),
      showLoading: showLoading,
      showSuccessSnackBar: showSuccessSnackBar,
      showErrorSnackBar: showErrorSnackBar,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

