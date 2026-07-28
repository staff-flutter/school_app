import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/services/api_service.dart';

/// NOTE:
/// This controller assumes the following endpoints exist in ApiConstants
/// (see eb_api_constants_snippet.dart):
///
///   Premises:
///     getAllPremises   -> /api/premises/get           (GET  /:schoolId)
///     getPremises      -> /api/premises/get           (GET  /:schoolId/:premisesId)
///     createPremises   -> /api/premises/create         (POST /:schoolId)
///     updatePremises   -> /api/premises/update         (PUT  /:schoolId/:premisesId)
///     deletePremises   -> /api/premises/delete         (DELETE /:schoolId/:premisesId)
///
///   EB Log:
///     getAllEBLogs     -> /api/eb/logs/get-all         (GET  /:schoolId)
///     getEBLog         -> /api/eb/logs/get             (GET  /:schoolId/:logId)
///     createEBLog      -> /api/eb/logs/create           (POST /:schoolId)
///     updateEBLog      -> /api/eb/logs/update           (PUT  /:schoolId/:logId)
///     deleteEBLog      -> /api/eb/logs/delete           (DELETE /:schoolId/:logId)
///     ebLogsAnalyticsBase -> /api/eb/logs/analytics
///         /:schoolId/premises
///         /:schoolId/dashboard
///         /:schoolId/linechart/consumption
///         /:schoolId/bill/kpi
///
///   Tariff:
///     getAllTariffs    -> /api/eb/tariff/get-all        (GET  /:schoolId)
///     getTariff        -> /api/eb/tariff/get            (GET  /:schoolId/:tariffId)
///     createTariff     -> /api/eb/tariff/create          (POST /:schoolId)
///     updateTariff     -> /api/eb/tariff/update          (PUT  /:schoolId/:tariffId)
///     deleteTariff     -> /api/eb/tariff/delete          (DELETE /:schoolId/:tariffId)
///
/// If your ApiConstants names differ, just swap the string literals below.

class EBController extends GetxController {
  final ApiService _apiService = Get.find();
  final isLoading = false.obs;

  // ---------------- Premises ----------------
  final premisesList = <Map<String, dynamic>>[].obs;
  final currentPremises = Rxn<Map<String, dynamic>>();

  // ---------------- EB Log ----------------
  final ebLogs = <Map<String, dynamic>>[].obs;
  final currentEBLog = Rxn<Map<String, dynamic>>();

  // ---------------- EB Analytics ----------------
  final premisesAnalytics = <Map<String, dynamic>>[].obs;
  final dashboardAnalytics = Rxn<Map<String, dynamic>>();
  final consumptionLineChart = Rxn<Map<String, dynamic>>();
  final billKpi = Rxn<Map<String, dynamic>>();

  // ---------------- Tariff ----------------
  final tariffs = <Map<String, dynamic>>[].obs;
  final currentTariff = Rxn<Map<String, dynamic>>();

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

  String _errorMessage(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (e.message != null) return e.message!;
    }
    return fallback;
  }

  // =======================================================================
  // PREMISES MODULE
  // =======================================================================

  Future<void> getAllPremises(String schoolId) async {
    try {
      isLoading.value = true;
      print('schoolId:$schoolId');
      final response = await _apiService.get('${ApiConstants.getAllPremises}/$schoolId');
      print('schoolId:$schoolId');
      if (response.data['ok'] == true) {
        print('response of get all premisses:${response.data}');
        premisesList.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load premises', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading premises'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getPremisesById(String schoolId, String premisesId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getPremises}/$schoolId/$premisesId');

      if (response.data['ok'] == true) {
        currentPremises.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load premises', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading premises'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createPremises(String schoolId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post('${ApiConstants.createPremises}/$schoolId', data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Premises created successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to create premises', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while creating premises'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updatePremises(String schoolId, String premisesId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put(
        '${ApiConstants.updatePremises}/$schoolId/$premisesId',
        data: data,
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Premises updated successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to update premises', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while updating premises'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletePremises(String schoolId, String premisesId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('${ApiConstants.deletePremises}/$schoolId/$premisesId');

      if (response.statusCode == 200) {
        _showSnackbar('Success', response.data['message'] ?? 'Premises deleted successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to delete premises', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while deleting premises'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =======================================================================
  // EB LOG MODULE
  // =======================================================================

  /// [premisesId], [fromDate], [toDate], [minReading], [maxReading], [search]
  /// are all optional filters supported by the backend.
  Future<void> getAllEBLogs({
    required String schoolId,
    String? premisesId,
    String? fromDate,
    String? toDate,
    num? minReading,
    num? maxReading,
    String? search,
  }) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        '${ApiConstants.getAllEBLogs}/$schoolId',
        queryParameters: {
          if (premisesId != null) 'premisesId': premisesId,
          if (fromDate != null) 'fromDate': fromDate,
          if (toDate != null) 'toDate': toDate,
          if (minReading != null) 'minReading': minReading,
          if (maxReading != null) 'maxReading': maxReading,
          if (search != null) 'search': search,
        },
      );

      if (response.data['ok'] == true) {
        ebLogs.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load EB logs', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading EB logs'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getEBLogById(String schoolId, String logId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getEBLog}/$schoolId/$logId');

      if (response.data['ok'] == true) {
        currentEBLog.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load EB log', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading EB log'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// [data] should contain all EBLog schema fields except ebLogNo
  /// (premisesId, date, time, meterReading, kwUsed, note).
  Future<bool> createEBLog(String schoolId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post('${ApiConstants.createEBLog}/$schoolId', data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'EB log created successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to create EB log', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while creating EB log'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateEBLog(String schoolId, String logId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('${ApiConstants.updateEBLog}/$schoolId/$logId', data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'EB log updated successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to update EB log', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while updating EB log'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteEBLog(String schoolId, String logId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('${ApiConstants.deleteEBLog}/$schoolId/$logId');

      if (response.statusCode == 200) {
        _showSnackbar('Success', response.data['message'] ?? 'EB log deleted successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to delete EB log', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while deleting EB log'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =======================================================================
  // EB ANALYTICS
  // =======================================================================

  /// Per-premises analytics cards: premisesId, premisesName, yesterdayConsumption,
  /// avg30DayConsumption, projectedThisMonthConsumption, totalConsumption.
  Future<void> getPremisesAnalytics(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.ebLogsAnalyticsBase}/$schoolId/premises');
      final url = '${ApiConstants.ebLogsAnalyticsBase}/$schoolId/premises';
      print('GET $url');
      if (response.data['ok'] == true) {
        premisesAnalytics.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load premises analytics', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading premises analytics'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  /// Overall dashboard summary: totalConsumptionYesterday, premisesReportedYesterday,
  /// totalPremises, recentLogs (latest 10).
  Future<Map<String, dynamic>?> getDashboardAnalytics(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.ebLogsAnalyticsBase}/$schoolId/dashboard');

      if (response.data['ok'] == true) {
        dashboardAnalytics.value = response.data['data'];
        return response.data['data'];
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to load dashboard analytics', AppTheme.errorRed);
      return null;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading dashboard analytics'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Line-chart consumption data. [period] is 'today' | 'week' | 'month' | 'year' | 'custom'.
  /// For 'custom', [fromDate] and [toDate] are required. [premisesId] optionally filters.
  Future<Map<String, dynamic>?> getConsumptionLineChart({
    required String schoolId,
    String? period,
    String? premisesId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        '${ApiConstants.ebLogsAnalyticsBase}/$schoolId/line-chart/consumption',
        queryParameters: {
          if (period != null) 'period': period,
          if (premisesId != null) 'premisesId': premisesId,
          if (fromDate != null) 'fromDate': fromDate,
          if (toDate != null) 'toDate': toDate,
        },
      );

      if (response.data['ok'] == true) {
        consumptionLineChart.value = response.data['data'];
        return response.data['data'];
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to load consumption chart', AppTheme.errorRed);
      return null;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading consumption chart'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Projected billing KPIs: monthlyProjectedBill, projectedUnitsThisMonth,
  /// estimatedDailyEBCost.
  Future<Map<String, dynamic>?> getBillKpi(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.ebLogsAnalyticsBase}/$schoolId/bill/kpi');

      if (response.data['ok'] == true) {
        billKpi.value = response.data['data'];
        return response.data['data'];
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to load billing KPIs', AppTheme.errorRed);
      return null;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading billing KPIs'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // =======================================================================
  // TARIFF MODULE
  // =======================================================================

  Future<void> getAllTariffs(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getAllTariffs}/$schoolId');

      if (response.data['ok'] == true) {
        tariffs.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load tariffs', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading tariffs'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getTariffById(String schoolId, String tariffId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getTariff}/$schoolId/$tariffId');

      if (response.data['ok'] == true) {
        currentTariff.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load tariff', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading tariff'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// [data] should include tariffName, fixedChargePerKw, isActive, and
  /// slabs: List<{ upto, ratePerUnit }>.
  Future<bool> createTariff(String schoolId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post('${ApiConstants.createTariff}/$schoolId', data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Tariff created successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to create tariff', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while creating tariff'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// If updating slabs, send the complete slabs array (not a partial patch).
  Future<bool> updateTariff(String schoolId, String tariffId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('${ApiConstants.updateTariff}/$schoolId/$tariffId', data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Tariff updated successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to update tariff', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while updating tariff'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteTariff(String schoolId, String tariffId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('${ApiConstants.deleteTariff}/$schoolId/$tariffId');

      if (response.statusCode == 200) {
        _showSnackbar('Success', response.data['message'] ?? 'Tariff deleted successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to delete tariff', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while deleting tariff'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}