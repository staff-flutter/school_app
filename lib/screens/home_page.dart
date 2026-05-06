import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:school_app/screens/Attendence_page.dart';
import 'parent_profile_page.dart';
import 'profile_selection_page.dart';
import 'student_profile_page.dart';
import 'time_table_page.dart';



import '../controllers/my_children_controller.dart';
import '../controllers/timetable_controller.dart';
import '../core/theme/app_theme.dart';
import '../services/user_session.dart';
// import '../screens/announcements_page.dart'; // TODO: announcements_page.dart not provided
import '../widgets/wrapper_with_no_navbar.dart';
import 'Assignments_page.dart';
// import 'Attendence_page.dart'; // TODO: file not provided in merge
import 'Notice_board_ui.dart';
// import 'Nticeboard_ui.dart'; // TODO: file not provided in merge
import 'clubs&activities_page.dart';
import 'fee_details_page.dart';
import 'marks_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black, // transparent so AppBar image shows through
    //   statusBarIconBrightness: Brightness.light, // dark icons (visible on light bg)
    // ));
  }


  // -----------------------------------  BUILD METHOD  ------------------------------------------


  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSession>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
          backgroundColor: AppTheme.appBackground,
          body:  Stack(
            children: <Widget>[
              Positioned(
                  top:0,left:0,right: 0,


                  // ----------------------------------  HEADER IMAGE  ----------------------------------------------


                  child: Image.asset('assets/images/Scientific UI background design header.png',width: MediaQuery.sizeOf(context).width, fit: BoxFit.cover,)
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: EdgeInsets.only(left: 18,right: 18,bottom: 18,top: 50),
                    height: MediaQuery.sizeOf(context).height*0.70,
                    width: MediaQuery.sizeOf(context).width,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(20),topLeft: Radius.circular(20))
                    ),
                
                
                  // --------------------------------  GRID VIEW  ---------------------------------------------
                
                
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('QUICK ACCESS',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.grey),),
                      SizedBox(height: 30,),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 3, // 2 columns, creating a 2x2 grid for 4 items
                          crossAxisSpacing: 8, // Horizontal space between icons
                          mainAxisSpacing: 20,  // Vertical space between icons
                          children:  [

                         // -------------------------------  ATTENDANCE PAGE  --------------------------------------------

                            _buildHomeItem(
                              iconPath: 'assets/images/Attendance_icon.png',
                              label: 'Attendance',
                              onTap: () => Get.to(() =>  const AttendancePage()),
                            ),

                         // --------------------------------  FEE DETAILS PAGE  -------------------------------------------

                            _buildHomeItem(
                              iconPath: 'assets/images/feedetails_icon.png',
                              label: 'FeeDetails',
                              onTap: () => Get.to(() =>  const FeeDetailsFirstPage()),                      ),

                          // --------------------------------  MARK LIST PAGE  ----------------------------------------------

                            _buildHomeItem(
                              iconPath: 'assets/images/marklist_icon.png',
                              label: 'Marks List',
                              onTap: () => Get.to(() =>  MarksList()),
                            ),

                          // ---------------------------------  TIME TABLE PAGE  ----------------------------------------------

                            _buildHomeItem(
                              iconPath: 'assets/images/timetable_icon.png',
                              label: 'Timetable',
                              onTap: () => Get.to(() => MainWrapperWithNoNavBar(child: const TimeTablePage())),
                            ),

                         // -----------------------------------  CLUBS & ACTIVITIES PAGE  --------------------------------------

                            _buildHomeItem(
                              iconPath: 'assets/images/clubs&activities_icon.png',
                              label: 'Clubs & Activities',
                              onTap: () => Get.to(() => const ClubAndActivitiesPage()),
                            ),

                          // ----------------------------------  HOMEWORK PAGE  -------------------------------------------------

                            _buildHomeItem(
                              iconPath: 'assets/images/homework_icon.png',
                              label: 'Homework',
                              onTap: () => Get.to(() =>const AssignmentUI()),
                            ),

                          // -----------------------------------  STUDENT PROFILE  ------------------------------------------------

                            _buildHomeItem(
                              iconPath: 'assets/images/studentprofile_icon.png',
                              label: 'Student Profile',
                              onTap: () =>Get.to(() =>  MainWrapperWithNoNavBar(child: ProfilePage(schoolId: '$session.schoolId'))),
                            ),

                          // -----------------------------------  PARENT PROFILE  --------------------------------------------------


                            _buildHomeItem(
                              iconPath: 'assets/images/parentprofile_icon.png',
                              label: 'Parent Profile',
                              onTap: () => Get.to(() => MainWrapperWithNoNavBar(child: const ParentProfile())),
                            ),

                          // ------------------------------------  NOTICE BOARD  ----------------------------------------------------
                            _buildHomeItem(
                              iconPath: 'assets/images/noticeboard_icon.png',
                              label: 'Notice Board',
                              onTap: () =>Get.to(() =>  NoticeBoardScreenUi()),
                            ),



                            // Column(
                            //   children: [
                            //     InkWell(
                            //         onTap: () {
                            //           Navigator.push(
                            //             context,
                            //             MaterialPageRoute(builder: (context) =>  NoticeBoardScreen()),
                            //           );
                            //         },
                            //         child: Image.asset('assets/images/noticeboard_icon.png', width: 50, height: 50,)
                            //     ),
                            //     SizedBox(height: 10),
                            //     Text('Notice Board',style: TextStyle(color: Colors.black,fontSize: 12),)
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                                ),
                ),
              ),
                ]
          )

      ),
    );
  }
}
Widget _buildHomeItem({
  required String iconPath,
  required String label,
  required VoidCallback onTap,
}) {
  return Column(
    children: [
      Material(
        color: Colors.transparent, // Required so the ripple isn't hidden
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          // Higher opacity makes it visible even on fast taps
          splashColor: Colors.blue.withOpacity(0.2),
          highlightColor: Colors.blue.withOpacity(0.1),
          onTap: () async {
            // This 150ms delay is the "magic" that makes the ripple visible
            await Future.delayed(const Duration(milliseconds: 150));
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0), // Bigger tap area
            child: Image.asset(iconPath, width: 30, height: 30),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 10)),
    ],
  );
}