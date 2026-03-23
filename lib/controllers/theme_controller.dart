import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();
  final isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _storage.read('isDarkMode') ?? false;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _storage.write('isDarkMode', isDarkMode.value);
  }

  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}