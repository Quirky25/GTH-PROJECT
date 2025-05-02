import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'register_page.dart';
import 'user_data.dart';
import 'gauge_display.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _nameError;
  String? _passwordError;

  void _loginUser() async {
    String fullNameInput = _fullNameController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();

    Map<String, String?> userInfo = await UserData.getUserInfo();
    String? storedFullName = userInfo['fullName'];
    String? storedPassword = userInfo['password'];

    setState(() {
      _nameError = null;
      _passwordError = null;
    });

    if (fullNameInput.isEmpty && password.isEmpty) {
      _showDialog("Please Sign in to your Account or Register!");
      return;
    }
    if (fullNameInput.isEmpty) {
      _showDialog("Please input your Name");
      return;
    }
    if (password.isEmpty) {
      _showDialog("Please input Password");
      return;
    }
    if (storedFullName == null || storedPassword == null) {
      _showDialog("Account not found. Please register first!");
      return;
    }
    if (!storedFullName.toLowerCase().split(" ").contains(fullNameInput)) {
      setState(() {
        _nameError = "Name does not match.";
      });
      return;
    }
    if (password != storedPassword) {
      setState(() {
        _passwordError = "Incorrect Password";
      });
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);

    _navigateToGaugeDisplay();
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

void _showForgotPasswordDialog() {
  TextEditingController newPasswordController = TextEditingController();
  bool obscurePassword = true;
  String? passwordError;

  void validateInputs() {
    String password = newPasswordController.text.trim();

    passwordError = (password.isEmpty || password.length < 8 || password.length > 16)
        ? "Password must be between 8-16 characters."
        : null;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  const Icon(
                    Icons.lock_reset,
                    size: 50,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Reset Password",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // New Password Field
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscurePassword,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(16),
                    ],
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      errorText: passwordError,
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            setState(() {
                              validateInputs();
                            });

                            if (passwordError == null) {
                              String newPassword = newPasswordController.text.trim();

                              Map<String, String?> userInfo = await UserData.getUserInfo();
                              String? fullName = userInfo['fullName'] ?? "";

                              await UserData.saveUserInfo(fullName, userInfo['contactNo'] ?? '', newPassword);

                              if (context.mounted) {
                                Navigator.pop(context);
                                // Show success dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.green,
                                            size: 60,
                                          ),
                                          SizedBox(height: 20),
                                          Text(
                                            "Password Reset Successfully!",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        Center(
                                          child: TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text(
                                              "OK",
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Reset Password',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  void _navigateToGaugeDisplay() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const GaugeDisplayPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[300]!,
              Colors.blue[600]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon with Smoke and Temperature/Humidity
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Smoke effect background
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.8),
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                              stops: const [0.2, 0.5, 1.0],
                            ),
                          ),
                        ),
                        // Main icon container
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Temperature icon
                              const Positioned(
                                left: 15,
                                top: 25,
                                child: Icon(
                                  Icons.thermostat,
                                  size: 50,
                                  color: Colors.red,
                                ),
                              ),
                              // Humidity icon
                              const Positioned(
                                right: 15,
                                top: 25,
                                child: Icon(
                                  Icons.water_drop,
                                  size: 50,
                                  color: Colors.blue,
                                ),
                              ),
                              // Smoke icon
                              Positioned(
                                bottom: 15,
                                left: 0,
                                right: 0,
                                child: Icon(
                                  Icons.air,
                                  size: 50,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Title Text
                    const Text(
                      "GTH Monitoring",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Gas • Temperature • Humidity",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Login Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _fullNameController,
                            onChanged: (value) {
                              setState(() {
                                _nameError = null;
                              });
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Name',
                              prefixIcon: const Icon(Icons.person, color: Colors.blue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.blue),
                              ),
                              errorText: _nameError,
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(16),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _passwordError = null;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.blue),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              errorText: _passwordError,
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Forgot Password and Register Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () async {
                            String fullNameInput = _fullNameController.text.trim().toLowerCase();
                            Map<String, String?> userInfo = await UserData.getUserInfo();
                            String? storedFullName = userInfo['fullName']?.toLowerCase().trim();

                            if (storedFullName == null || storedFullName.isEmpty) {
                              _showDialog("No registered account found. Please register first.");
                              return;
                            }

                            if (fullNameInput.isNotEmpty &&
                                storedFullName.toLowerCase().split(" ").contains(fullNameInput)) {
                              if (context.mounted) {
                                _showForgotPasswordDialog();
                              }
                            } else {
                              _showDialog("Please enter your name to proceed.");
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                        const Text("|", style: TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
