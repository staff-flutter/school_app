import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../controllers/communications_controller.dart';



class NoticeBoardScreen extends GetView<CommunicationsController> {
  final CommunicationsController controller = Get.put(
      CommunicationsController());

  NoticeBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      // backgroundColor: Colors.transparent,

      body: SafeArea(
        child: Container(
          color: const Color(0xFF7BB4DD),
          child: Stack(
            children: [
              Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/Scientific UI background design header.png',
                fit: BoxFit.cover,
              ),
            ),
              Positioned(
                  top: 35,
                  left: 10,
                  child: Text('NOTICE BOARD',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),)),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xff4A90E2),
                        Color(0xff6FD3F7),
                      ],

                    ),
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.85,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(20),topLeft: Radius.circular(20))
                    ),
                    child:ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        final message = controller.messages[index];
                        return NoticeCard(
                          title: message.subject,
                          subject: message.content,
                          date: message.date,
                        );
                      },
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }




  IconData _getMessageIcon(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'fee':
        return Icons.payment;
      case 'achievement':
        return Icons.star;
      default:
        return Icons.message;
    }
  }
}
class NoticeCard extends StatelessWidget {
  final String title;
  final String subject;
  final String date;


  const NoticeCard({
    super.key,
    required this.title,
    required this.subject,
    required this.date,

  });

  // Color getStatusColor() {
  //   switch (status) {
  //     case "Completed":
  //       return Colors.green;
  //     case "In Progress":
  //       return Colors.purple;
  //     case "Not Started":
  //       return Colors.blue;
  //     default:
  //       return Colors.orange;
  //   }
  // }
  // schoolId:objectId,
  //     academicYear:string
  // (eg:”2025-2026”
  // ),
  // title:stirng,
  // description:string,
  // type:string,
  // priority:string,
  // targetAudience[],
  // targetClasses[]

  // Color getStatusColor() {
  //   switch (status) {
  //     case "Viewed":
  //       return Colors.blue;
  //     case "Not Viewed":
  //       return Colors.blue;
  //     default:
  //       return Colors.blue;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: (){
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => NoticeBoardDescription(noticeCard: NoticeCard(title: title, subject: subject, date: date, status: status, color: color)),
            //   ),
            // );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10, left: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Container(
                        //   padding:
                        //   const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        //   decoration: BoxDecoration(
                        //     color:Colors.blue,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //
                        // ),
                        Icon(Icons.keyboard_arrow_right_outlined,color: Colors.blue,),
                      ],
                    ),
                    // Row(
                    //   children: [
                    //     Icon(status == 'Not Submitted' ? null:Icons.circle,size: 10.0,color: getStatusColor(),),
                    //     Icon(Icons.keyboard_arrow_right_outlined,color: getStatusColor(),),
                    //
                    //     ]
                    // )

                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  "subject: $subject",
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 6),

                Text(
                  "Due Date: $date",
                  style: const TextStyle(color: Colors.black45),
                ),
              ],
            ),
          ),
        ),

        // Timeline line

      ],
    );
  }
}

//
// class AlbumForNoticeBoard {
//
//   final  schoolId  objectId,
//       academicYear:string
//   (eg:”2025-2026”
//   ),
//   title:stirng,
//   description:string,
//   type:string,
//   priority:string,
//   targetAudience[],
//   targetClasses[]
//
// }