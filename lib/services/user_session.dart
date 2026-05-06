import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession extends GetxController {
  String? token;
  String? schoolId;
  List<String>? studentId;
  String? parentId;
  String? parentName;
  String? parentEmail;
  String? parentPhoneNo;
  String? role;
  bool? isPlatformAdmin;
  String? assignments;
  String? schoolSocialPlatform;
  String? schoolName;
  String? schoolEmail;
  String? schoolPhoneNo;
  String? schoolAddress;


  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    schoolId = prefs.getString('schoolId');
    studentId = prefs.getStringList('studentId');
    parentId =prefs.getString('parentId');
    parentName=prefs.getString('parentName');
    parentEmail=prefs.getString('parentEmail');
    parentPhoneNo=prefs.getString('parentPhoneNo');
    role=prefs.getString('role');
    isPlatformAdmin=prefs.getBool('isPlatformAdmin');
    assignments=prefs.getString('assignments');
    schoolSocialPlatform=prefs.getString('schoolSocialPlatform');
    schoolName =prefs.getString('schoolName');
    schoolEmail=prefs.getString('schoolEmail');
    schoolPhoneNo=prefs.getString('schoolPhoneNo');
    schoolAddress=prefs.getString('schoolAddress');

    print(token);
    print(schoolId);
    print(parentId);
    print(parentName);
    print(parentEmail);
    print(parentPhoneNo);
    print(isPlatformAdmin);
    print(assignments);
    print(schoolSocialPlatform);
    print(schoolName);
    print(schoolEmail);
    print(schoolPhoneNo);
    print(schoolAddress);

    //  Print individual IDs
    if (studentId != null && studentId!.isNotEmpty) {
      print("--- Printing Individual Student IDs ---");
      for (var id in studentId!) {
        print("Student ID: $id");
      }
    } else {
      print("No Student IDs found in session.");
    }

    update();
  }
}