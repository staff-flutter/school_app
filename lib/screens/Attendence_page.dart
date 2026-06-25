import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:school_app/controllers/attendance_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/utils/academic_year_utils.dart';
import '../core/utils/responsive_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:table_calendar/table_calendar.dart';


import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../services/user_session.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _AuthCtrl = Get.find<AuthController>();
  final AttendanceController _attendanceCtrl = Get.put(AttendanceController());
  DateTime _focusDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  int _currentPageIndex=0;
  final PageController _pageController = PageController();

  List<FestivalTiles> _holidayList = [];
  bool _loadingHolidays = false;
  final List<NumberColorItem> attendanceFestivalsHolidays = [
    NumberColorItem(number:01,colorDarker: Color(0xFFC62828),colorLight: Color(0xFFFF6961),title:'Absent'),
    NumberColorItem(number: 02,colorDarker:  Color(0xFF159A46),colorLight: Color(0xFF81EE53),title: 'Festivals&Holidays'),
  ];
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _pageController.dispose();
    _inspectControllerResponses();
  }
// Add this helper method inside your _AttendancePageState class:
  void _inspectControllerResponses() async {
    final controller = Get.find<MyChildrenController>();
    final selectedStudent = Get.find<MyChildrenController>().selectedChild;
    print("------- 🔍 STARTING ATTENDANCE INSPECTION 🔍 -------");

    final String currentSchoolId = _AuthCtrl.user.value?.schoolId ?? '';
    // Replace these with sample IDs that actually exist in your database for testing
    final String sampleClassId = controller.selectedChild['classId'] ?? 'null';
    final String sampleSectionId =  selectedStudent['sectionId'] ?? 'null';
    final String sampleDate = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    // 1. Inspect getAttendanceSheet Response
    try {
      print("🚀 Calling getAttendanceSheet...");
      await _attendanceCtrl.getAttendanceSheet(
        schoolId: currentSchoolId,
        classId: sampleClassId,
        date: sampleDate, academicYear: AcademicYearUtils.getCurrentAcademicYear(),
      );

      // Since it's a GetX RxList, .value or .toList() prints the underlying raw list data clearly
      print("📦 Attendance Sheet Saved State: ${_attendanceCtrl.attendanceSheet.value}");
    } catch (e) {
      print("❌ Error calling getAttendanceSheet: $e");
    }

    // 2. Inspect getAttendanceHistory Response
    try {
      print("🚀 Calling getAttendanceHistory...");
      await _attendanceCtrl.getAttendanceHistory(
        schoolId: currentSchoolId,
        classId: sampleClassId,
        sectionId: sampleSectionId,
        startDate: '01-06-2026',
        endDate: '25-06-2026'
      );

      print("📦 Attendance History Saved State: ${_attendanceCtrl.attendanceHistory.value}");
    } catch (e) {
      print("❌ Error calling getAttendanceHistory: $e");
    }

    print("------- 🔍 INSPECTION COMPLETE 🔍 -------");
  }
  //  Map for O(1) lookup: {DateTime: "present"}
  Map<DateTime, String> _attendanceMap = {};
  Map<String, int> _attendanceTotals = {'present': 0, 'absent': 0}; // ← add this


  Future<void> _initializeAttendance() async {
   // await loginAndGetToken();
    List<AttendanceRecord> records = await fetchAttendance();

    // Converting List to Map for easy calendar coloring
    _attendanceMap = {
      for (var record in records)
        DateTime(record.date.year, record.date.month, record.date.day): record.status
    };
    _attendanceTotals = {
      'present': records.where((r) => r.status == 'present').length,
      'absent': records.where((r) => r.status == 'absent').length,
    };
    setState(() {});
  }



//------------------------------------------ THE FETCH ATTENDANCE FUNCTION ----------------------------------------


  /// Computes attendance totals from the studentAttendance API response.
  /// Expects response.data['data'] to be a List of records, each with a 'status' field.
  Map<String, int> computeAttendanceTotals(List<dynamic> attendanceRecords) {
    int presentCount = 0;
    int absentCount = 0;
    int otherCount = 0; // catches any status that isn't present/absent (e.g. "leave", "holiday")

    for (final record in attendanceRecords) {
      final status = (record['status'] ?? '').toString().toLowerCase();
      switch (status) {
        case 'present':
          presentCount++;
          break;
        case 'absent':
          absentCount++;
          break;
        default:
          otherCount++;
      }
    }

    return {
      'present': presentCount,
      'absent': absentCount,
      'other': otherCount,
      'total': attendanceRecords.length,
    };
  }
  Future<List<AttendanceRecord>> fetchAttendance({DateTime? month}) async {
    String baseUrl = ApiConstants.baseUrl;
    final targetMonth = month ?? _focusDay;

    final controller = Get.find<MyChildrenController>();
    final selectedStudent = Get.find<MyChildrenController>().selectedChild;

    final String? token = _AuthCtrl.storage.read('token');
    final String? schoolId = _AuthCtrl.user.value?.schoolId ?? '';
    final String? classId = controller.selectedChild['classId'] ?? 'null';
    final String? studentId = controller.selectedChild['_id'] ?? 'null';
    final String? sectionId = selectedStudent['sectionId'] ?? 'null';

    final Map<String, String> queryParameters = {
      if (schoolId != null) "schoolId": schoolId,
      "classId": '$classId',
      "sectionId": "$sectionId",
      "month": "${targetMonth.month}",
      "year": "${targetMonth.year}",
    };

    final uri = Uri.parse('$baseUrl/api/attendance/student/$studentId')
        .replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedData = jsonDecode(response.body);
      final List<dynamic> list = decodedData['data'] ?? [];
      return list.map((data) => AttendanceRecord.fromJson(data)).toList();
    }
    return [];
  }

  Future<void> _fetchHolidayCalendar() async {
    setState(() => _loadingHolidays = true);
    try {
      final baseUrl = ApiConstants.baseUrl;
      final String? token = _AuthCtrl.storage.read('token');
      final String? schoolId = _AuthCtrl.user.value?.schoolId ?? '';

      final uri = Uri.parse('$baseUrl/api/calendar/getall').replace(
        queryParameters: {
          if (schoolId != null && schoolId.isNotEmpty) 'schoolId': schoolId,
        },
      );

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is Map
            ? (decoded['data'] ?? [])
            : (decoded is List ? decoded : []);

        final tiles = list.map((e) {
          final from = DateTime.parse(e['startDate'] ?? e['fromDate'] ?? e['date']);
          return FestivalTiles(
            festivalName: e['title'] ?? e['name'] ?? 'Event',
            dateAndMonth: _ordinalDate(from),
            dayName: _weekdayName(from),
          );
        }).toList();

        setState(() => _holidayList = tiles);
      }
    } catch (e) {
      debugPrint('⚠️ fetchHolidayCalendar error: $e');
    } finally {
      if (mounted) setState(() => _loadingHolidays = false);
    }
  }

  String _ordinalDate(DateTime d) {
    const months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    final day = d.day;
    final suffix = (day >= 11 && day <= 13)
        ? 'th'
        : switch (day % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
    return '$day$suffix ${months[d.month - 1]}';
  }

  String _weekdayName(DateTime d) {
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return days[d.weekday - 1];
  }
//----------------------------------------------- THE FETCH CALENDER FUNCTION ----------------------------------------



  Future<List<AttendanceRecord>> fetchCalender() async {
    String baseUrl = ApiConstants.baseUrl;

    //final SharedPreferences prefs = await SharedPreferences.getInstance();
   // String? token = prefs.getString('user_token');
    final String? token = _AuthCtrl.storage.read('token');

    final uri = Uri.parse('$baseUrl/api/calendar/getall');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print(response.body);

      final dynamic decodedData = jsonDecode(response.body);

      if(decodedData is List){
        return decodedData.map((data) => AttendanceRecord.fromJson(data)).toList();
      }
      else if (decodedData is Map<String, dynamic>) {
        final List<dynamic> list = decodedData['data'] ?? [];
        return list.map((data) => AttendanceRecord.fromJson(data)).toList();
      }

      return [];

    } else {
      print("Attendance Error: ${response.statusCode}");
      return [];
    }
  }


@override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeAttendance();
    _fetchHolidayCalendar();
  // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black, // transparent so AppBar image shows through
    //   statusBarIconBrightness: Brightness.light, // dark icons (visible on light bg)
    //   // or Brightness.light if your header image is dark
    // ));
  }



  //--------------------------------------------- BUILD METHOD ---------------------------------------------------



  @override
  Widget build(BuildContext context) {
   // final absentCount = _attendanceMap.values.where((s) => s == 'absent').length;
   // final presentCount = _attendanceMap.values.where((s) => s == 'present').length;
    final absentCount = _attendanceTotals['absent'] ?? 0;
    final presentCount = _attendanceTotals['present'] ?? 0;
    final List<NumberColorItem> dynamicStats = [
      NumberColorItem(
          number: absentCount,
          colorDarker: const Color(0xFFC62828),
          colorLight: const Color(0xFFFF6961),
          title: 'Absent'
      ),
      NumberColorItem(
          number: presentCount,
          colorDarker: const Color(0xFF159A46),
          colorLight: const Color(0xFF81EE53),
          title: 'Present'
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black), // Custom icon and color
          onPressed: () => Navigator.of(context).pop(), // Don't forget this!
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.8),      // Change Circle Color here
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: ResponsiveHelper.h(context, 75),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Scientific UI background design header.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ToggleSwitch(
              minWidth: 130.0,
              minHeight: 30.0,
              cornerRadius: 20.0,
              borderColor: [Colors.transparent],
              activeBgColor: [Colors.white],
              activeFgColor: const Color(0xFF6a83c8),
              inactiveBgColor: const Color(0xFFC9D6EE),
              inactiveFgColor: Colors.white,
              initialLabelIndex: _currentPageIndex,
              borderWidth: 1,
              totalSwitches: 2,
              labels: ['ATTENDANCE', 'HOLIDAYS'],
              customTextStyles: const [
                TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ],
              radiusStyle: true,
              onToggle: (index) {
                setState(() {
                  _currentPageIndex = index!;
                  _pageController.animateToPage(
                    _currentPageIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              },
            ),
          ),
        ),
      ),

         // ------------------------------------- PAGE VIEW -----------------------------------------------


      body: SafeArea(
        child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index; // Keep toggle in sync
              });
            },
            children: [
              SizedBox.expand(  //  Forces child to fill PageView's full space
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Color(0xff4A90E2),
                      Color(0xff6FD3F7),
                    ]),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        topLeft: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Calendar
                        TableCalendar(
                          rowHeight: ResponsiveHelper.isSmallHeight(context) ? 34.0 : 46.0,
                          daysOfWeekHeight: ResponsiveHelper.isSmallHeight(context) ? 18.0 : 16.0,
                          focusedDay: _focusDay,
                          firstDay: DateTime.utc(2025, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          headerStyle: const HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(color: Colors.black),
                            weekendStyle: TextStyle(color: Colors.red),
                          ),
                          calendarFormat: _calendarFormat,
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(day),
                            todayBuilder: (context, day, focusedDay) =>
                            _buildCalendarCell(day) ?? _buildStatusContainer(day, Colors.green),
                            holidayBuilder: (context, day, focusedDay) => _buildCalendarCell(day),
                          ),
                          onPageChanged: (focusedDay) async {
                            _focusDay = focusedDay;
                            final records = await fetchAttendance(month: focusedDay);
                            _attendanceMap = {
                              for (var r in records)
                                DateTime(r.date.year, r.date.month, r.date.day): r.status
                            };
                            _attendanceTotals = {
                              'present': records.where((r) => r.status == 'present').length,
                              'absent': records.where((r) => r.status == 'absent').length,
                            };
                            setState(() {});
                          },
                        ),


                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: dynamicStats.length,
                            itemBuilder: (context, index) {
                              return AttendanceFestivalsHolidaysContainers(
                                numberColorItem: dynamicStats[index],
                              );
                            },
                          ),
                        ),

                        // Footer pinned at bottom
                        SizedBox(
                          height: ResponsiveHelper.isSmallHeight(context)
                              ? ResponsiveHelper.h(context, 55)
                              : null,
                          child: Image.asset(
                            'assets/images/Blue science and education collection footer.png',
                            width: double.infinity,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0xff4A90E2),
                    Color(0xff6FD3F7),

                  ],),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(20),topLeft:Radius.circular(20) ),
                  ),
                  child: Column(
                    children: [


            // ---------------------------------TABLE CALENDER FOR HOLIDAYS --------------------------------------


                      TableCalendar(
                        rowHeight: ResponsiveHelper.isSmallHeight(context) ? 34.0 : 46.0,
                        daysOfWeekHeight: ResponsiveHelper.isSmallHeight(context) ? 18.0 : 16.0,
                        firstDay: DateTime.utc(2025,10,16) ,
                        lastDay: DateTime.utc(2030,3,14),
                        headerStyle: const HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(color:Colors.black),
                            weekendStyle: TextStyle(color: Colors.red)
                        ),
                        calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: Colors.green),
                            selectedDecoration: BoxDecoration(color: Colors.red,borderRadius: BorderRadius.circular(100),)
                        ),
                        focusedDay: _focusDay,
                        //selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        //onDaySelected: _onDaySelected,
                        calendarFormat: _calendarFormat,
                      ),
                      ResponsiveHelper.vSpace(context, 50),

                      Container(
                        padding: EdgeInsets.only(left: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('List of Holidays',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                          ],
                        ),
                      ),


             // ------------------------------LIST VIEW BUILDER FOR LIST OF HOLIDAYS ------------------------------------------


                      Expanded(
                        child: _loadingHolidays
                            ? const Center(child: CircularProgressIndicator())
                            : _holidayList.isEmpty
                            ? const Center(
                          child: Text('No holidays added yet',
                              style: TextStyle(color: Colors.grey)),
                        )
                            : ListView.builder(
                          itemCount: _holidayList.length,
                          itemBuilder: (context, index) {
                            return FestivalListContainer(festivalTiles: _holidayList[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              ),
            ]
        ),
      ),
    );
  }


  // _onDaySelected(selectedDay , focusDay) {
  //   if(!isSameDay(_selectedDay , selectedDay)){
  //     setState(() {
  //       _selectedDay = selectedDay;
  //       _focusDay = focusDay;
  //     });
  //   }
  // }

// Helper widget to draw the circle
  Widget _buildStatusContainer(DateTime day, Color color) {

    return Container(
      margin: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${day.day}',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget? _buildCalendarCell(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    final status = _attendanceMap[dateOnly];

    if (status == 'absent') {
      return _buildStatusContainer(day, const Color(0xFFC62828)); // Deep Red
    } else if (status == 'present') {
      return _buildStatusContainer(day, Colors.green); // Deep Green
    }
    return null;
  }}

class FestivalTiles{
  final String festivalName;
  final String dateAndMonth;
  final String dayName;
  FestivalTiles({required this.festivalName,required this.dateAndMonth,required this.dayName});
}

class NumberColorItem {
  final int number;
  final Color colorDarker;
  final Color colorLight;
  final String title;

  NumberColorItem( {required this.number, required this.colorDarker, required this.colorLight, required this.title});
}

class AttendanceFestivalsHolidaysContainers extends StatelessWidget {
  final NumberColorItem numberColorItem;
  const AttendanceFestivalsHolidaysContainers({super.key,required this.numberColorItem});

  @override
  Widget build(BuildContext context) {
    return   Container(
      margin: EdgeInsets.symmetric(horizontal:  ResponsiveHelper.w(context, 8),vertical: ResponsiveHelper.h(context, 8),),
      height: ResponsiveHelper.h(context, 40),
      width: MediaQuery.sizeOf(context).width-20,
      decoration: BoxDecoration(
        border: Border.all(
          color: numberColorItem.colorDarker,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  decoration: BoxDecoration(
                    color: numberColorItem.colorDarker,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(10),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Text('${numberColorItem.title}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 13),),
              ],
            ),
            Container(
              margin: EdgeInsets.only(right: 5),
              alignment: Alignment.center,
              height: 25,
              width: 25,
              decoration: BoxDecoration(
                  color:numberColorItem.colorLight,
                  borderRadius: BorderRadius.circular(20)
              ),
              child: Text('${numberColorItem.number}',style: TextStyle(color: numberColorItem.colorDarker),),
            )

          ]
      ),

    );
  }
}


class FestivalListContainer extends StatelessWidget {
  final FestivalTiles festivalTiles;
  const FestivalListContainer({super.key,required this.festivalTiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 12),

      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
          border: Border.all(
              color: Colors.grey,
              width: 1
          ),
          borderRadius: BorderRadius.circular(10)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(festivalTiles.festivalName,style: TextStyle(fontWeight: FontWeight.bold),),
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(festivalTiles.dateAndMonth),
              Text(festivalTiles.dayName)
            ],
          )
        ],
      ),
    );
  }
}


// -------------------------------------------- MODEL CLASS TO GET THE DATA ------------------------------


class AttendanceRecord {
  final DateTime date;
  final String status; // 'present' or 'absent'

  AttendanceRecord({required this.date, required this.status});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: DateTime.parse(json['date']),
      status: json['status'] ?? 'unknown',
    );
  }
}