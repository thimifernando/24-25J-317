import 'package:flutter/material.dart';
import 'package:greeny_mobile/screens/chilli_prediction.dart';
import 'package:greeny_mobile/screens/home_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:greeny_mobile/sign_in.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // List of widgets for the bottom navigation bar
  static List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    PredictionContent(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Logout function with confirmation dialog
Future<void> _logout(BuildContext context) async {
  // Show a confirmation dialog
  bool confirmLogout = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Return false if user cancels
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Return true if user confirms
            },
            child: Text('Logout'),
          ),
        ],
      );
    },
  );

  // If user confirms logout, proceed with logout
  if (confirmLogout == true) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInPage()),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back button
        title: Center(
          child: Text(
            _selectedIndex == 0 ? "Home" : "Prediction",
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 56, 3, 45), // Set the background color to green
        foregroundColor: const Color.fromARGB(255, 255, 255, 255), // Set the background color to green
        actions: [
          // Logout button in AppBar
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home, size: 28),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.online_prediction, size: 28),
                label: 'Prediction',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.teal, // Selected tab color
            unselectedItemColor: const Color.fromARGB(255, 105, 104, 104), // Unselected tab color
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color.fromARGB(255, 203, 202, 202),
            elevation: 10,
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomeTab();
  }
}

class PredictionContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ImageUploadScreen();
  }
}
