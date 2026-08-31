import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/services/api_service.dart';

/// NOTE:
/// This controller assumes the following endpoints exist (or will be added)
/// to your ApiConstants file. Update the paths below to match your actual
/// ApiConstants class if the naming differs.
///
///   Driver:
///     createDriver            -> /api/transport/driver/create
///     getDrivers              -> /api/transport/driver
///     getDriverDropdown       -> /api/transport/driver/dropdown
///     getDriverById           -> /api/transport/driver
///     updateDriver            -> /api/transport/driver
///     deleteDriver            -> /api/transport/driver
///     deleteDriverDocFile     -> /api/transport/driver
///
///   Bus:
///     createBus               -> /api/transport/bus/create
///     getBuses                -> /api/transport/bus
///     getBusDropdown          -> /api/transport/bus/dropdown
///     getBusById              -> /api/transport/bus
///     updateBus               -> /api/transport/bus
///     deleteBus               -> /api/transport/bus
///     deleteBusDocFile        -> /api/transport/bus
///
///   Daily Trip Log:
///     createDailyTripLog      -> /api/transport/dailytriplog/create
///     getDailyTripLogs        -> /api/transport/dailytriplog
///     getDailyTripLogById     -> /api/transport/dailytriplog
///     updateDailyTripLog      -> /api/transport/dailytriplog
///     deleteDailyTripLog      -> /api/transport/dailytriplog
///
///   Fuel Log:
///     createFuelLog           -> /api/transport/fuellog/create
///     getFuelLogs              -> /api/transport/fuellog
///     getFuelLogById           -> /api/transport/fuellog
///     updateFuelLog            -> /api/transport/fuellog
///     deleteFuelLog            -> /api/transport/fuellog
///
///   Bus Route:
///     createBusRoute           -> /api/transport/busroute
///     getBusRoutes              -> /api/transport/busroute
///     getBusRouteDropdown       -> /api/transport/busroute/drop-down
///     getBusRouteById           -> /api/transport/busroute
///     updateBusRoute            -> /api/transport/busroute
///     deleteBusRoute            -> /api/transport/busroute
///     busRouteAssignments       -> /api/transport/busroute/{routeId}/assignments
///
/// If you already have these mapped under different constant names, just
/// swap the string literals used below (e.g. ApiConstants.transportDriverCreate)
/// with the ones you've defined.

class TransportController extends GetxController {
  final ApiService _apiService = Get.find();
  final isLoading = false.obs;
  final uploadProgress = 0.0.obs;

  // ---------------- Driver ----------------
  final drivers = <Map<String, dynamic>>[].obs;
  final driverDropdown = <Map<String, dynamic>>[].obs;
  final currentDriver = Rxn<Map<String, dynamic>>();

  // ---------------- Bus ----------------
  final buses = <Map<String, dynamic>>[].obs;
  final busDropdown = <Map<String, dynamic>>[].obs;
  final currentBus = Rxn<Map<String, dynamic>>();

  // ---------------- Daily Trip Log ----------------
  final dailyTripLogs = <Map<String, dynamic>>[].obs;
  final currentDailyTripLog = Rxn<Map<String, dynamic>>();

  // ---------------- Fuel Log ----------------
  final fuelLogs = <Map<String, dynamic>>[].obs;
  final currentFuelLog = Rxn<Map<String, dynamic>>();

  // ---------------- Bus Route ----------------
  final busRoutes = <Map<String, dynamic>>[].obs;
  final busRouteDropdown = <Map<String, dynamic>>[].obs;
  final currentBusRoute = Rxn<Map<String, dynamic>>();

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

  // Builds a MultipartFile from a local File, guessing content type by extension.
  Future<MultipartFile> _multipartFromFile(File file, {String? fieldFileName}) async {
    final ext = path.extension(file.path).toLowerCase().replaceFirst('.', '');
    final mimeType = ext == 'pdf'
        ? 'application/pdf'
        : (ext == 'jpg' || ext == 'jpeg')
        ? 'image/jpeg'
        : ext == 'png'
        ? 'image/png'
        : ext == 'mp4'
        ? 'video/mp4'
        : 'application/octet-stream';
    return MultipartFile.fromFile(
      file.path,
      filename: fieldFileName ?? path.basename(file.path),
      contentType: DioMediaType.parse(mimeType),
    );
  }

  // =======================================================================
  // DRIVER MODULE
  // =======================================================================

  /// Create a driver. [documents] is the metadata list (must only contain
  /// the allowed document names). [documentFiles] maps the index of the
  /// document in [documents] to the File(s) to upload for it
  /// (documents_0, documents_1, ...).
  Future<bool> createDriver({
    required String schoolId,
    String? name,
    String? phone,
    String? assignedBusId,
    String? dateOfBirth,
    String? joinedDate,
    String? emergencyContact,
    String? address,
    File? photo,
    List<Map<String, dynamic>>? documents,
    Map<int, List<File>>? documentFiles,
  }) async {
    try {
      isLoading.value = true;

      final formData = FormData.fromMap({
        'schoolId': schoolId,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (assignedBusId != null) 'assignedBusId': assignedBusId,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (joinedDate != null) 'joinedDate': joinedDate,
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
        if (address != null) 'address': address,
        if (documents != null) 'documents': documents,
      });

      if (photo != null) {
        formData.files.add(MapEntry('photo', await _multipartFromFile(photo)));
      }

      if (documentFiles != null) {
        for (final entry in documentFiles.entries) {
          for (final file in entry.value) {
            formData.files.add(
              MapEntry('documents_${entry.key}', await _multipartFromFile(file)),
            );
          }
        }
      }

      final response = await _apiService.dio.post(
        ApiConstants.createDriver,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackbar('Success', 'Driver created successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', 'Failed to create driver', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while creating driver'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getDrivers({String? schoolId, String? status, String? search}) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        ApiConstants.getAllDrivers,
        queryParameters: {
          if (schoolId != null) 'schoolId': schoolId,
          if (status != null) 'status': status,
          if (search != null) 'search': search,
        },
      );

      if (response.data['ok'] == true) {
        drivers.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load drivers', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading drivers'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getDriverDropdown(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getDriverDropdown}/$schoolId');

      if (response.data['ok'] == true) {
        driverDropdown.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load driver dropdown', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading driver dropdown'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getDriverById(String id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getDriver}/$id');

      if (response.data['ok'] == true) {
        currentDriver.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load driver', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading driver'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update a driver. Existing documents keep their `_id` inside [documents];
  /// new documents omit `_id`. [documentFiles] again maps the index of the
  /// document object in [documents] to newly uploaded files (appended, not
  /// replaced) for that document.
  Future<bool> updateDriver({
    required String id,
    String? name,
    String? phone,
    String? assignedBusId,
    String? dateOfBirth,
    String? joinedDate,
    String? emergencyContact,
    String? address,
    String? status,
    File? photo,
    List<Map<String, dynamic>>? documents,
    Map<int, List<File>>? documentFiles,
  }) async {
    try {
      isLoading.value = true;

      final formData = FormData.fromMap({
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (assignedBusId != null) 'assignedBusId': assignedBusId,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (joinedDate != null) 'joinedDate': joinedDate,
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
        if (address != null) 'address': address,
        if (status != null) 'status': status,
        if (documents != null) 'documents': documents,
      });

      if (photo != null) {
        formData.files.add(MapEntry('photo', await _multipartFromFile(photo)));
      }

      if (documentFiles != null) {
        for (final entry in documentFiles.entries) {
          for (final file in entry.value) {
            formData.files.add(
              MapEntry('documents_${entry.key}', await _multipartFromFile(file)),
            );
          }
        }
      }

      final response = await _apiService.dio.put(
        '${ApiConstants.updateDriver}/$id',
        data: formData,
      );

      if (response.statusCode == 200) {
        _showSnackbar('Success', 'Driver updated successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', 'Failed to update driver', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while updating driver'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteDriver(String id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('${ApiConstants.deleteDriver}/$id');

      if (response.statusCode == 200) {
        _showSnackbar('Success', response.data['message'] ?? 'Driver deleted successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to delete driver', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while deleting driver'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Deletes a single attachment file from a driver document (document itself stays).
  Future<bool> deleteDriverDocumentFile({
    required String driverId,
    required String documentId,
    required String fileId,
  }) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete(
        '${ApiConstants.deleteDriver}/$driverId/documents/$documentId/files/$fileId',
      );

      if (response.statusCode == 200) {
        _showSnackbar('Success', 'File removed successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to remove file', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while removing file'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =======================================================================
  // BUS MODULE
  // =======================================================================

  /// Create a bus. [statutoryDocuments] is the metadata list (documentName
  /// must be one of the allowed names). [statutoryDocumentFiles] maps the
  /// index of the document object to the file(s) to upload for it
  /// (statutoryDocuments_0, statutoryDocuments_1, ...).
  Future<bool> createBus({
    required String schoolId,
    String? busNumber,
    String? registrationNo,
    String? makeModel,
    int? year,
    int? seatingCapacity,
    String? fuelType,
    String? chassisNo,
    String? engineNo,
    String? purchaseDate,
    String? rcOwner,
    String? nextServiceDate,
    String? lastServiceDate,
    String? assignedDriverId,
    String? operationalStatus,
    List<Map<String, dynamic>>? statutoryDocuments,
    Map<int, List<File>>? statutoryDocumentFiles,
  }) async {
    try {
      isLoading.value = true;

      final formData = FormData.fromMap({
        'schoolId': schoolId,
        if (busNumber != null) 'busNumber': busNumber,
        if (registrationNo != null) 'registrationNo': registrationNo,
        if (makeModel != null) 'makeModel': makeModel,
        if (year != null) 'year': year,
        if (seatingCapacity != null) 'seatingCapacity': seatingCapacity,
        if (fuelType != null) 'fuelType': fuelType,
        if (chassisNo != null) 'chassisNo': chassisNo,
        if (engineNo != null) 'engineNo': engineNo,
        if (purchaseDate != null) 'purchaseDate': purchaseDate,
        if (rcOwner != null) 'rcOwner': rcOwner,
        if (nextServiceDate != null) 'nextServiceDate': nextServiceDate,
        if (lastServiceDate != null) 'lastServiceDate': lastServiceDate,
        if (assignedDriverId != null) 'assignedDriverId': assignedDriverId,
        if (operationalStatus != null) 'operationalStatus': operationalStatus,
        if (statutoryDocuments != null) 'statutoryDocuments': statutoryDocuments,
      });

      if (statutoryDocumentFiles != null) {
        for (final entry in statutoryDocumentFiles.entries) {
          for (final file in entry.value) {
            formData.files.add(
              MapEntry('statutoryDocuments_${entry.key}', await _multipartFromFile(file)),
            );
          }
        }
      }

      final response = await _apiService.dio.post(
        ApiConstants.createBus,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackbar('Success', 'Bus created successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', 'Failed to create bus', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while creating bus'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getBuses({String? schoolId, String? operationalStatus, String? search}) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        ApiConstants.getAllBuses,
        queryParameters: {
          if (schoolId != null) 'schoolId': schoolId,
          if (operationalStatus != null) 'operationalStatus': operationalStatus,
          if (search != null) 'search': search,
        },
      );

      if (response.data['ok'] == true) {
        buses.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load buses', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading buses'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getBusDropdown(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getBusDropdown}/$schoolId');

      if (response.data['ok'] == true) {
        busDropdown.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load bus dropdown', AppTheme.errorRed);
      }
    } catch (e) {
     // _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading bus dropdown'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getBusById(String id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getBus}/$id');

      if (response.data['ok'] == true) {
        currentBus.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load bus', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading bus'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateBus({
    required String id,
    String? busNumber,
    String? registrationNo,
    String? makeModel,
    int? year,
    int? seatingCapacity,
    String? fuelType,
    String? chassisNo,
    String? engineNo,
    String? purchaseDate,
    String? rcOwner,
    String? nextServiceDate,
    String? lastServiceDate,
    String? assignedDriverId,
    String? operationalStatus,
    List<Map<String, dynamic>>? statutoryDocuments,
    Map<int, List<File>>? statutoryDocumentFiles,
  }) async {
    try {
      isLoading.value = true;

      final formData = FormData.fromMap({
        if (busNumber != null) 'busNumber': busNumber,
        if (registrationNo != null) 'registrationNo': registrationNo,
        if (makeModel != null) 'makeModel': makeModel,
        if (year != null) 'year': year,
        if (seatingCapacity != null) 'seatingCapacity': seatingCapacity,
        if (fuelType != null) 'fuelType': fuelType,
        if (chassisNo != null) 'chassisNo': chassisNo,
        if (engineNo != null) 'engineNo': engineNo,
        if (purchaseDate != null) 'purchaseDate': purchaseDate,
        if (rcOwner != null) 'rcOwner': rcOwner,
        if (nextServiceDate != null) 'nextServiceDate': nextServiceDate,
        if (lastServiceDate != null) 'lastServiceDate': lastServiceDate,
        if (assignedDriverId != null) 'assignedDriverId': assignedDriverId,
        if (operationalStatus != null) 'operationalStatus': operationalStatus,
        if (statutoryDocuments != null) 'statutoryDocuments': statutoryDocuments,
      });

      if (statutoryDocumentFiles != null) {
        for (final entry in statutoryDocumentFiles.entries) {
          for (final file in entry.value) {
            formData.files.add(
              MapEntry('statutoryDocuments_${entry.key}', await _multipartFromFile(file)),
            );
          }
        }
      }

      final response = await _apiService.dio.put(
        '${ApiConstants.updateBus}/$id',
        data: formData,
      );

      if (response.statusCode == 200) {
        _showSnackbar('Success', 'Bus updated successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', 'Failed to update bus', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while updating bus'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteBus(String id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('${ApiConstants.deleteBus}/$id');

      if (response.statusCode == 200) {
        _showSnackbar('Success', response.data['message'] ?? 'Bus deleted successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to delete bus', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while deleting bus'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Deletes a single file from a bus statutory document (document itself stays).
  Future<bool> deleteBusDocumentFile({
    required String busId,
    required String documentId,
    required String fileId,
  }) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete(
        '${ApiConstants.deleteBusDocumentFile}/$busId/documents/$documentId/files/$fileId',
      );

      if (response.statusCode == 200) {
        _showSnackbar('Success', 'File removed successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to remove file', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while removing file'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =======================================================================
  // DAILY TRIP LOG MODULE
  // =======================================================================

  Future<bool> createDailyTripLog(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post(ApiConstants.createDailyTripLog, data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Daily trip log created successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to create daily trip log', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while creating daily trip log'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getDailyTripLogs({
    String? schoolId,
    String? busId,
    String? academicYear,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        ApiConstants.getAllDailyTripLogs,
        queryParameters: {
          if (schoolId != null) 'schoolId': schoolId,
          if (busId != null) 'busId': busId,
          if (academicYear != null) 'academicYear': academicYear,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['ok'] == true) {
        dailyTripLogs.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load daily trip logs', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading daily trip logs'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getDailyTripLogById(String id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getDailyTripLog}/$id');

      if (response.data['ok'] == true) {
        currentDailyTripLog.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load daily trip log', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading daily trip log'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateDailyTripLog(String id, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('${ApiConstants.updateDailyTripLog}/$id', data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Daily trip log updated successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to update daily trip log', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while updating daily trip log'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
// TransportController
  Future<Map<String, dynamic>?> getDailyTripLogAnalytics(
      String schoolId, {
        String? period, // 'today' | 'week' | 'month' | 'year' — TBC with backend
        String? fromDate,
        String? toDate,
      }) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        '${ApiConstants.getDailyTripLogAnalytics}/$schoolId',
        queryParameters: {
          if (period != null) 'period': period,
          if (fromDate != null) 'fromDate': fromDate,
          if (toDate != null) 'toDate': toDate,
        },
      );
      if (response.data['ok'] == true) {
        return response.data['data'];
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to load trip analytics', AppTheme.errorRed);
      return null;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading trip analytics'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  Future<bool> deleteDailyTripLog(String id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('${ApiConstants.deleteDailyTripLog}/$id');

      if (response.statusCode == 200) {
        _showSnackbar('Success', response.data['message'] ?? 'Daily trip log deleted successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to delete daily trip log', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while deleting daily trip log'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =======================================================================
  // FUEL LOG MODULE
  // =======================================================================

  Future<bool> createFuelLog(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post(ApiConstants.createFuelLog, data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Fuel log created successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to create fuel log', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while creating fuel log'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getFuelLogs({
    String? schoolId,
    String? busId,
    String? academicYear,
    String? search,
    String? fromDate,
    String? toDate,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        ApiConstants.getAllFuelLogs,
        queryParameters: {
          if (schoolId != null) 'schoolId': schoolId,
          if (busId != null) 'busId': busId,
          if (academicYear != null) 'academicYear': academicYear,
          if (search != null) 'search': search,
          if (fromDate != null) 'fromDate': fromDate,
          if (toDate != null) 'toDate': toDate,
          if (minAmount != null) 'minAmount': minAmount,
          if (maxAmount != null) 'maxAmount': maxAmount,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['ok'] == true) {
        fuelLogs.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load fuel logs', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading fuel logs'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getFuelLogById(String id, {required String schoolId}) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        '${ApiConstants.getFuelLog}/$id',
        queryParameters: {'schoolId': schoolId},
      );
      if (response.data['ok'] == true) {
        currentFuelLog.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load fuel log', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      // TEMP DEBUG — remove once fixed
      if (e is DioException) {

      } else {
      }
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading fuel log'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateFuelLog(String id, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('${ApiConstants.updateFuelLog}/$id', data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Fuel log updated successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to update fuel log', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while updating fuel log'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteFuelLog(String id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('${ApiConstants.deleteFuelLog}/$id');

      if (response.statusCode == 200) {
        _showSnackbar('Success', response.data['message'] ?? 'Fuel log deleted successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to delete fuel log', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while deleting fuel log'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =======================================================================
  // BUS ROUTE MODULE
  // =======================================================================

  /// [stops] format: [{ stopName, landmark, order, latitude, longitude, googlePlaceId }]
  Future<bool> createBusRoute({
    required String schoolId,
    String? routeNo,
    required String routeName,
    List<Map<String, dynamic>>? stops,
    double? feeAmount,
    String? feeFrequency,
    bool? isActive,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        'schoolId': schoolId,
        'routeName': routeName,
        if (routeNo != null) 'routeNo': routeNo,
        if (stops != null) 'stops': stops,
        if (feeAmount != null) 'feeAmount': feeAmount,
        if (feeFrequency != null) 'feeFrequency': feeFrequency,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await _apiService.post(ApiConstants.createBusRoute, data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Bus route created successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to create bus route', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while creating bus route'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// [assignments] format: [{ busId, driverId, shift, stopTimings: [{ stopName, time }] }]
  Future<bool> addBusRouteAssignments({
    required String routeId,
    required String schoolId,
    required List<Map<String, dynamic>> assignments,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        'schoolId': schoolId,
        'assignments': assignments,
      };

      final response = await _apiService.post(
        '${ApiConstants.addBusRouteAssignments}/$routeId/assignments',
        data: data,
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Assignments added successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to add assignments', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while adding assignments'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// [stopTimings] format: [{ stopName, time }]
  Future<bool> updateBusRouteAssignment({
    required String routeId,
    required String schoolId,
    required String assignmentId,
    String? busId,
    String? driverId,
    String? shift,
    List<Map<String, dynamic>>? stopTimings,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        'schoolId': schoolId,
        'assignmentId': assignmentId,
        if (busId != null) 'busId': busId,
        if (driverId != null) 'driverId': driverId,
        if (shift != null) 'shift': shift,
        if (stopTimings != null) 'stopTimings': stopTimings,
      };

      final response = await _apiService.put(
        '${ApiConstants.updateBusRouteAssignment}/$routeId/assignments',
        data: data,
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Assignment updated successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to update assignment', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while updating assignment'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteBusRouteAssignment({
    required String routeId,
    required String schoolId,
    required String assignmentId,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.dio.delete(
        '${ApiConstants.deleteBusRouteAssignment}/$routeId/assignments',
        data: {
          'schoolId': schoolId,
          'assignmentId': assignmentId,
        },
      );

      if (response.statusCode == 200) {
        _showSnackbar('Success', 'Assignment removed successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', 'Failed to remove assignment', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while removing assignment'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getBusRoutes({
    String? schoolId,
    String? search,
    double? minFee,
    double? maxFee,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        ApiConstants.getAllBusRoutes,
        queryParameters: {
          if (schoolId != null) 'schoolId': schoolId,
          if (search != null) 'search': search,
          if (minFee != null) 'minFee': minFee,
          if (maxFee != null) 'maxFee': maxFee,
          'page': page,
          'limit': limit,
        },
      );
      if (response.data['ok'] == true) {
        busRoutes.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load bus routes', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading bus routes'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getBusRouteDropdown(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        ApiConstants.getBusRouteDropdown,
        queryParameters: {'schoolId': schoolId},
      );

      if (response.data['ok'] == true) {
        busRouteDropdown.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load bus route dropdown', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading bus route dropdown'), AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getBusRouteById(String routeId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getBusRoute}/$routeId');

      if (response.data['ok'] == true) {
        currentBusRoute.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load bus route', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading bus route'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// [stops] format: [{ stopName, landmark, order, latitude, longitude, googlePlaceId }]
  Future<bool> updateBusRoute({
    required String routeId,
    required String schoolId,
    String? routeNo,
    String? routeName,
    List<Map<String, dynamic>>? stops,
    double? feeAmount,
    String? feeFrequency,
    bool? isActive,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        'schoolId': schoolId,
        if (routeNo != null) 'routeNo': routeNo,
        if (routeName != null) 'routeName': routeName,
        if (stops != null) 'stops': stops,
        if (feeAmount != null) 'feeAmount': feeAmount,
        if (feeFrequency != null) 'feeFrequency': feeFrequency,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await _apiService.put('${ApiConstants.updateBusRoute}/$routeId', data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Bus route updated successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to update bus route', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while updating bus route'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteBusRoute(String routeId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('${ApiConstants.deleteBusRoute}/$routeId');

      if (response.statusCode == 200) {
        _showSnackbar('Success', response.data['message'] ?? 'Bus route deleted successfully', AppTheme.successGreen);
        return true;
      }
      _showSnackbar('Error', response.data['message'] ?? 'Failed to delete bus route', AppTheme.errorRed);
      return false;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while deleting bus route'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  Future<Map<String, dynamic>?> getFuelLogAnalytics(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getFuelLogAnalytics}/$schoolId');
      if (response.data['ok'] == true) {
        return response.data['data'];}
      _showSnackbar('Error', response.data['message'] ?? 'Failed to load fuel log analytics', AppTheme.errorRed);
      return null;
    } catch (e) {
      _showSnackbar('Error', _errorMessage(e, 'An error occurred while loading fuel log analytics'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}