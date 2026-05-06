import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth_controller.dart';


class LoginPage extends StatefulWidget {
   LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController controller = Get.find<AuthController>();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isObscure = true;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: const Color(0xFF7BB4DD),
          child: Stack(
            children: [

//------------------------------------------------------  TOP IMAGE-----------------------------------
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/Scientific UI background design header.png',
                  fit: BoxFit.cover,
                ),
              ),

 //------------------------------------------------------  BOTTOM CONTAINER------------------------------------
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  height: MediaQuery.of(context).size.height * 0.75,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text(
                            'Hi Student',
                            style: TextStyle(
                                fontSize: 40, fontWeight: FontWeight.bold),
                          ),

                          const Text(
                            'Sign in to continue',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),

                          const SizedBox(height: 20),

//---------------------------------------------  EMAIL FIELD--------------------------------------------------
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number / Email',
                              border: UnderlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          //  PASSWORD FIELD
                          TextField(
                            controller: _passwordController,
                            obscureText: _isObscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const UnderlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_isObscure
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _isObscure = !_isObscure;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          //  BUTTON
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xff4A90E2),
                                  Color(0xff6FD3F7),
                                ],
                              ),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize:
                                const Size(double.infinity, 50),
                              ),
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Signing In...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                                  : Row(
                                children: const [
                                  Expanded(
                                    child: Text(
                                      'SIGN IN',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Align(
                            alignment: Alignment.centerRight,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),

                          const SizedBox(height: 20),

                          //  SHOW RESPONSE IN UI
                          // if (_album != null) ...[
                          //   const Divider(),
                          //   Text("User ID: ${_album!.id}"),
                          //   Text("Password: ${_album!.password}"),
                          ]
                      ),
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

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      controller.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }
}

//  MODEL CLASS
// class Album {
//   final String id;
//   final String password;
//
//   Album({required this.id, required this.password});
//
//   factory Album.fromJson(Map<String, dynamic> json) {
//     return Album(
//       id: json['id'].toString(),
//       password: json['password'].toString(),
//     );
//   }
// }