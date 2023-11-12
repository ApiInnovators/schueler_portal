import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  static late SharedPreferences _prefs;
  static const String _accentColorKey = "accent color";

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setAccentColor(Color color) =>
      _prefs.setString(_accentColorKey, color.toString());

  static Color getAccentColor() {
    String? res = _prefs.getString(_accentColorKey);

    if (res == null) return Colors.lightBlue;

    return Color(int.parse(res.split('(0x')[1].split(')')[0], radix: 16));
  }

  static bool isCourseEnabled(String course) => _prefs.getBool(course) ?? true;

  static Future<void> setCourseIsEnabled(String course, bool value) =>
      _prefs.setBool(course, value);

  static bool selectedAnyCourses() => _prefs.getKeys().isNotEmpty;
}
