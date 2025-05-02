import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  static Future<void> saveUserInfo(String fullName, String contactNo, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', fullName);
    await prefs.setString('contactNo', contactNo);
    await prefs.setString('password', password); // Save updated password
  }

  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fullName': prefs.getString('fullName'),
      'contactNo': prefs.getString('contactNo'),
      'password': prefs.getString('password'), // Retrieve password
    };
  }

  static Future<void> clearUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
