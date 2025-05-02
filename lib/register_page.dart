import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'user_data.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  String? _fullNameError;
  String? _passwordError;
  String? _contactError;
  bool _obscurePassword = true;

  void _registerUser() async {
    setState(() {
      _validateInputs();
    });

    if (_fullNameError == null &&
        _passwordError == null &&
        _contactError == null) {
      await UserData.saveUserInfo(
        _fullNameController.text.trim(),
        _contactController.text.trim(),
        _passwordController.text.trim(),
      );
      
  // ✅ Store Contact Number in Firebase
      DatabaseReference ref = FirebaseDatabase.instance.ref("config/phoneNumber");  //--- 
      await ref.set(_contactController.text.trim());     

      _showSuccessDialog();
    }
  }

  void _validateInputs() {
    String fullName = _fullNameController.text.trim();
    String password = _passwordController.text.trim();
    String contactNo = _contactController.text.trim();

    final RegExp phNumberRegex = RegExp(r'^9[0-9]{9}$');

    _fullNameError =
        (fullName.isEmpty || fullName.length < 5 || fullName.length > 30) ? "Full Name must be between 5 - 30 letters." : null;
    _passwordError =
        (password.isEmpty || password.length < 8 || password.length > 16) ? "Password must be between 8-16 characters." : null;
    _contactError = (contactNo.isEmpty || !phNumberRegex.hasMatch(contactNo)) ? "Please enter a valid number." : null;
  }

  void _onTextChanged() {
    setState(() {
      if (_fullNameController.text.isNotEmpty) _fullNameError = null;
      if (_passwordController.text.isNotEmpty) _passwordError = null;
      if (_contactController.text.isNotEmpty) _contactError = null;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Success!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                "Registered Successfully!",
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  "Continue to Login",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

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
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // White Container for Form
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
                              // Full Name
                              TextField(
                                controller: _fullNameController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                                  LengthLimitingTextInputFormatter(30),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
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
                                  errorText: _fullNameError,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                onChanged: (_) => _onTextChanged(),
                              ),
                              const SizedBox(height: 20),

                              // Password
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                inputFormatters: [LengthLimitingTextInputFormatter(16)],
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
                                onChanged: (_) => _onTextChanged(),
                              ),
                              const SizedBox(height: 20),

                              // Contact No.
                              TextField(
                                controller: _contactController,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Contact No.',
                                  prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                                  prefixText: '+63 ',
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
                                  errorText: _contactError,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                onChanged: (_) => _onTextChanged(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
