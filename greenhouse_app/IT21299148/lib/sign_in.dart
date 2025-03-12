import 'package:flutter/material.dart';
import 'package:greeny_mobile/home.dart';
import 'package:greeny_mobile/sign_up.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    final String apiUrl = "http://192.168.8.105:8000/sign_in/";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData != null && responseData["message"] == "Sign-in successful") {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          _showSnackBar(responseData["message"]);
        }
      } else {
        _showSnackBar("Failed to sign in. Please try again.");
      }
    } catch (e) {
      _showSnackBar("An error occurred: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Opacity
          Opacity(
            opacity: 0.4, // Adjust the opacity level (0.0 to 1.0)
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.jpg'), // Path to your image
                  fit: BoxFit.cover, // Cover the entire screen
                ),
              ),
            ),
          ),
          // Main Content
          Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 80, color: const Color.fromARGB(255, 144, 92, 8)),
                  SizedBox(height: 20),
                  Text(
                    "Welcome Back!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Sign in to continue",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 30),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 144, 92, 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              "Sign In",
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignUpPage()),
                          );
                        },
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 144, 92, 8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}