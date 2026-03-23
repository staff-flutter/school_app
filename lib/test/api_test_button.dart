import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/test/api_test_screens.dart';

class ApiTestButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Get.to(() => ApiTestHomeScreen()),
      child: Icon(Icons.api),
      tooltip: 'API Tests',
    );
  }
}

// Add this to any existing screen to access API tests
class WithApiTestButton extends StatelessWidget {
  final Widget child;
  
  const WithApiTestButton({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: ApiTestButton(),
    );
  }
}