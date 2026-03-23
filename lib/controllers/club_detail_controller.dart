import 'package:get/get.dart';
import 'package:school_app/models/club_model.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/controllers/auth_controller.dart';

class ClubDetailController extends GetxController {
  final ApiService _apiService = Get.find();
  final AuthController _authController = Get.find();
  final isLoading = false.obs;
  final club = Rxn<Club>();

  String _getSchoolId() {
    return _authController.user.value?.schoolId ?? '';
  }

  Future<void> fetchClubDetails(String clubId) async {

    try {
      isLoading.value = true;
      
      final schoolId = _getSchoolId();

      final url = '${ApiConstants.getClub}/$clubId';
      final queryParams = {'schoolId': schoolId};

      final response = await _apiService.get(url, queryParameters: queryParams);

      if (response.data['ok'] == true) {
        club.value = Club.fromJson(response.data['data']);
        
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to load club details');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load club details');
    } finally {
      isLoading.value = false;
    }
  }
}
