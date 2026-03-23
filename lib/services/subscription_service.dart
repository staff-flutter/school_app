import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/controllers/auth_controller.dart';

class SubscriptionService extends GetxService {
  final ApiService _apiService = Get.find();
  
  final subscriptionData = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    // Load subscription data when service initializes
    _loadInitialSubscription();
  }

  Future<void> _loadInitialSubscription() async {
    try {

      // Check if AuthController is available
      if (!Get.isRegistered<AuthController>()) {
        
        return;
      }
      
      final authController = Get.find<AuthController>();

      final user = authController.user.value;

      final userRole = user?.role?.toLowerCase();
      final schoolId = user?.schoolId;

      // Load subscription for all roles, but only correspondent/principal need checks
      if (schoolId != null) {
        
        await getSubscription(schoolId);
      } else {
        
        _setLocalDefaultSubscription('default');
      }
    } catch (e) {
      
      // Set default premium on error
      _setLocalDefaultSubscription('default');
    }
  }

  // Public method to reload subscription after authentication
  Future<void> reloadSubscriptionAfterAuth() async {
    
    await _loadInitialSubscription();
  }

  // Force reload subscription for a specific school
  Future<void> forceReloadSubscription(String schoolId) async {
    
    subscriptionData.value = null; // Clear existing data
    await getSubscription(schoolId);
  }

  // Package definitions
  static const Map<String, Map<String, bool>> packages = {
    'basic': {
      'studentRecord': true,
      'attendance': false,
      'expense': false,
      'club': false,
      'announcement': false,
    },
    'standard': {
      'studentRecord': true,
      'attendance': true,
      'expense': true,
      'club': false,
      'announcement': false,
    },
    'premium': {
      'studentRecord': true,
      'attendance': true,
      'expense': true,
      'club': true,
      'announcement': true,
    },
  };

  // Update school subscription
  Future<bool> updateSubscription({
    required String schoolId,
    required String planName,
    Map<String, bool>? customModules,
  }) async {
    try {
      isLoading.value = true;
      
      final data = <String, dynamic>{
        'schoolId': schoolId,
        'planName': planName,
      };
      
      if (customModules != null) {
        data['customModules'] = customModules;
      }

      final response = await _apiService.put(
        ApiConstants.updateSubscription,
        data: data,
      );

      if (response.data['ok'] == true) {
        // Transform the update response to match the expected subscription format
        final schoolData = response.data['data'];
        final subscription = schoolData['subscription'];
        
        final transformedData = {
          'ok': true,
          'data': {
            'schoolId': schoolData['_id'],
            'plan': subscription['planName'],
            'features': subscription['modules'],
          }
        };
        
        // Update local subscription data with transformed format
        subscriptionData.value = transformedData;

        Get.snackbar('Success', 'Subscription updated successfully');
        return true;
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to update subscription');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update subscription');
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get subscription details
  Future<Map<String, dynamic>?> getSubscription(String schoolId) async {
    try {

      isLoading.value = true;

      final response = await _apiService.get(
        '/api/subscription/get',
        queryParameters: {'schoolId': schoolId},
      );

      if (response.data['ok'] == true && response.data['plan'] != null) {
        // Transform the GET response to match expected format
        final transformedData = {
          'ok': true,
          'data': {
            'schoolId': schoolId,
            'plan': response.data['plan'],
            'features': response.data['features'],
          }
        };
        
        subscriptionData.value = transformedData;

        return transformedData;
      } else {

        // Use local premium subscription since no create API exists
        _setLocalDefaultSubscription(schoolId);
        return subscriptionData.value;
      }
    } catch (e) {

      // Use local premium subscription on error
      _setLocalDefaultSubscription(schoolId);
      return subscriptionData.value;
    } finally {
      isLoading.value = false;
      
    }
  }

  // Create default basic subscription for school
  Future<void> _createDefaultSubscription(String schoolId) async {
    try {

      // Try to create subscription via API first
      
      final response = await _apiService.post(
        '/api/subscription/create',
        data: {
          'schoolId': schoolId,
          'planName': 'premium',
          'features': {
            'studentRecord': true,
            'attendance': true,
            'expense': true,
            'club': true,
            'announcement': true,
          }
        },
      );

      if (response.data['ok'] == true) {
        subscriptionData.value = response.data;

      } else {
        
        // If API creation fails, use local default
        _setLocalDefaultSubscription(schoolId);
      }
    } catch (e) {

      // Fallback to local default
      _setLocalDefaultSubscription(schoolId);
    }
  }

  void _setLocalDefaultSubscription(String schoolId) {
    
    final defaultSubscription = {
      'ok': true,
      'data': {
        'schoolId': schoolId,
        'plan': 'premium',
        'features': {
          'studentRecord': true,
          'attendance': true,
          'expense': true,
          'club': true,
          'announcement': true,
        }
      }
    };
    subscriptionData.value = defaultSubscription;

  }

  // Check if module is enabled for school
  bool hasModuleAccess(String module, String schoolId) {
    try {

      // Only check subscription for correspondent and principal roles
      final userRole = Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
      final requiresSubscriptionCheck = ['correspondent', 'principal'].contains(userRole);

      if (!requiresSubscriptionCheck) {
        
        return true;
      }

      final subscription = subscriptionData.value;
      if (subscription == null) {
        
        return false;
      }
      
      // Check both direct features and nested data.features
      final features = subscription['features'] as Map<String, dynamic>? ?? 
                      subscription['data']?['features'] as Map<String, dynamic>?;

      final hasAccess = features?[module] == true;
      
      return hasAccess;
    } catch (e) {
      
      return false;
    }
  }

  // Check multiple modules at once
  bool hasAnyModuleAccess(List<String> modules, String schoolId) {
    return modules.any((module) => hasModuleAccess(module, schoolId));
  }

  // Get enabled modules for school
  Map<String, bool> getEnabledModules() {

    // Force load subscription if not available
    if (subscriptionData.value == null) {
      
      final authController = Get.find<AuthController>();
      final schoolId = authController.user.value?.schoolId;
      if (schoolId != null) {
        
        getSubscription(schoolId);
      }
    }
    
    final subscription = subscriptionData.value;

    if (subscription == null) {

      final premiumFeatures = {
        'studentRecord': true,
        'attendance': true,
        'expense': true,
        'club': true,
        'announcement': true,
      };
      
      return premiumFeatures;
    }

    // Check both direct features and nested data.features
    final features = subscription['features'] as Map<String, dynamic>? ?? 
                    subscription['data']?['features'] as Map<String, dynamic>?;

    if (features == null) {

      final premiumFeatures = {
        'studentRecord': true,
        'attendance': true,
        'expense': true,
        'club': true,
        'announcement': true,
      };
      
      return premiumFeatures;
    }
    
    final result = features.map((key, value) => MapEntry(key, value as bool));

    return result;
  }
}