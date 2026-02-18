import 'package:get/get.dart';
import '../data/services/subscription_service.dart';
import '../modules/auth/controllers/auth_controller.dart';

class SubscriptionController extends GetxController {
  final SubscriptionService _subscriptionService = Get.find();
  final AuthController _authController = Get.find();
  
  final isLoading = false.obs;
  final subscriptionData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    
    // Load subscription data when controller initializes
    final schoolId = _authController.user.value?.schoolId;
    if (schoolId != null) {
      
      loadSubscription(schoolId);
    } else {
      
    }
  }

  // Load subscription data for school
  Future<void> loadSubscription(String schoolId) async {
    isLoading.value = true;
    final data = await _subscriptionService.getSubscription(schoolId);
    
    if (data != null) {
      subscriptionData.value = data;
      
    }
    isLoading.value = false;
    
    // Force UI update by triggering reactive updates
    update();
  }

  // Update subscription plan
  Future<bool> updateSubscription({
    required String schoolId,
    required String planName,
    Map<String, bool>? customModules,
  }) async {
    final success = await _subscriptionService.updateSubscription(
      schoolId: schoolId,
      planName: planName,
      customModules: customModules,
    );
    
    if (success) {
      // Reload subscription data to get the latest from server
      await loadSubscription(schoolId);
    }
    
    return success;
  }

  // Check if module is enabled
  bool hasModuleAccess(String module) {
    return _subscriptionService.hasModuleAccess(module, _authController.user.value?.schoolId ?? '');
  }

  // Get enabled modules
  Map<String, bool> getEnabledModules() {
    return _subscriptionService.getEnabledModules();
  }

  // Check if user has correspondent role (for subscription management)
  bool canManageSubscription() {
    final userRole = _authController.user.value?.role;
    return userRole == 'correspondent';
  }

  // Get current plan name
  String getCurrentPlan() {

    // Try both controller and service data, prioritize service data as it's more up-to-date
    final servicePlan = _subscriptionService.subscriptionData.value?['data']?['plan'] ?? 
                      _subscriptionService.subscriptionData.value?['plan'];
    final controllerPlan = subscriptionData.value?['data']?['plan'] ?? 
                          subscriptionData.value?['plan'];

    return servicePlan ?? controllerPlan ?? 'basic';
  }

  // Get subscription status for UI display
  Map<String, dynamic> getSubscriptionStatus() {
    final enabled = getEnabledModules();
    
    return {
      'plan': getCurrentPlan(),
      'modules': {
        'studentRecord': enabled['studentRecord'] ?? false,
        'attendance': enabled['attendance'] ?? false,
        'expense': enabled['expense'] ?? false,
        'club': enabled['club'] ?? false,
        'announcement': enabled['announcement'] ?? false,
      },
    };
  }
}