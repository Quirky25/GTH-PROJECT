import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gauge_display.dart';
import 'data_log_service.dart'; // ✅ Import the DataLogService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await PushNotificationService.initialize(); // ✅ Initialize push notifications

  // Initialize the DataLogService
  await DataLogService().initialize(); // ✅ Initialize the logging service

  // Check if the user is already logged in
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn)); // Pass the login state to MyApp
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GTH Monitoring',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn ? const GaugeDisplayPage() : const LoginPage(),
    );
  }
}