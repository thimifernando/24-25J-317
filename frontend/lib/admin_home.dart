import 'package:flutter/material.dart';
import 'package:greeny_mobile/screens/admin/add_recommendations_screen.dart';
import 'package:greeny_mobile/screens/admin/view_recommendations_screen.dart';
import 'package:greeny_mobile/sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _adminPages = <Widget>[
    const AddRecommendationsScreen(),
    const ViewRecommendationsScreen(),
  ]; 

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color.fromARGB(255, 12, 136, 119),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await prefs.setBool('isAdmin', false);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignInPage()),
              );
            },
          ),
        ],
      ),
      body: _adminPages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'View'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 12, 136, 119),
      ),
    );
  }
}


