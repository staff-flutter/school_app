import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/test/api_test_screens.dart';

class StudentRecordNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.receipt_long),
      title: Text('Student Records'),
      subtitle: Text('Manage fee records and dues'),
      onTap: () => Get.to(() => StudentRecordScreen()),
    );
  }
}