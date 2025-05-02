import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'user_data.dart';
import 'login_page.dart'; // Import Login Page for navigation

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ForgotPasswordPageState createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  String? _passwordError;

  void _resetPassword() async {
    String newPassword = _newPasswordController.text.trim();

    // Reset errors
    setState(() {
      _passwordError = null;
    });

    if (newPassword.isEmpty) {
      _showDialog("Please enter your New Password");
      return;
    }

    // Fetch stored user data
    Map<String, String?> userInfo = await UserData.getUserInfo();

    // Update User Data with new password
    await UserData.saveUserInfo(userInfo['fullName'] ?? '', userInfo['contactNo'] ?? '', newPassword);

    // Show success dialog after password is updated
    _showDialog("Password successfully updated!", success: true);
  }

  void _showDialog(String message, {bool success = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            success ? "Success!" : "Error",  // If success is true, show "Success!"
            textAlign: TextAlign.center,      // Center the title
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,     // Center the content message
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (success) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  }
                },
                child: const Text("OK"),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(16),
                ],
                onChanged: (value) {
                  setState(() {
                    _passwordError = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  errorText: _passwordError,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: screenWidth * 0.6,
                height: 50,
                child: ElevatedButton(
                  onPressed: _resetPassword,
                  child: const Text('Confirm', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}