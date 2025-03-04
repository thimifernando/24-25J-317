import 'package:greenhouse_app/pages/onboarding_page.dart';
import 'package:greenhouse_app/pages/signup_page.dart';
import 'package:greenhouse_app/pages/signin_page.dart';
import 'package:greenhouse_app/pages/home_page.dart';
import 'package:greenhouse_app/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import './providers/user_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),
      home: const OnboardingPage(),
      routes: {
        '/signin': (context) => Signin(),
        '/signup': (context) => Signup(),
        '/home': (context) => HomePage(),
        '/user/profile': (context) => ProfilePage(),
      },
    );
  }
}