import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_up.dart';
import 'sign_in.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await checkLoginStatus();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Greeny App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isLoggedIn ? HomeScreen() : MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SignInPage();  // Directly show the SignInPage UI
  }
}


