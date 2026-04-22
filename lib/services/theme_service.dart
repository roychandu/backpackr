import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  static ThemeService get to => Get.find();
  
  final _key = 'isDarkMode';
  late SharedPreferences _prefs;

  final RxBool isDarkMode = false.obs;

  ThemeMode get theme => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  Future<ThemeService> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Default to light mode if no preference found
    isDarkMode.value = _prefs.getBool(_key) ?? false;
    return this;
  }

  void switchTheme() {
    isDarkMode.value = !isDarkMode.value;
    _prefs.setBool(_key, isDarkMode.value);
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);

    // Force immediate rebuild of the element tree so static getters re-evaluate
    Future.delayed(const Duration(milliseconds: 50), () {
      if (Get.context != null) {
        void rebuild(Element el) {
          el.markNeedsBuild();
          el.visitChildren(rebuild);
        }
        (Get.context as Element).visitChildren(rebuild);
      }
    });
  }
}
