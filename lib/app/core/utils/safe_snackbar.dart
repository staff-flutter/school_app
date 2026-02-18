import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SafeSnackbar {
  static void show(String title, String message, {Color? backgroundColor}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.context != null) {
          Get.snackbar(
            title,
            message,
            backgroundColor: backgroundColor ?? Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        } else {
          
        }
      } catch (e) {
        
      }
    });
  }
  
  static void success(String message) {
    show('Success', message, backgroundColor: Colors.green);
  }
  
  static void error(String message) {
    show('Error', message, backgroundColor: Colors.red);
  }
  
  static void info(String message) {
    show('Info', message, backgroundColor: Colors.blue);
  }
}