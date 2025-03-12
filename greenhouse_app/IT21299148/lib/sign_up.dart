import 'package:flutter/material.dart';
import 'package:greeny_mobile/sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    final String apiUrl = "http://192.168.8.105:8000/add_user/";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _nameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);
      final message = responseData["message"] ?? "Unexpected response from server";
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar("Error: $e");
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
      backgroundColor: Colors.white,
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
          // Existing Content
          Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 80, color: const Color.fromARGB(255, 144, 92, 8)),
                  SizedBox(height: 20),
                  Text(
                    "Create an Account",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Sign up to get started",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 30),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Name",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 15),
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
                            onPressed: _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 144, 92, 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              "Sign Up",
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignInPage()),
                          );
                        },
                        child: Text(
                          "Sign In",
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