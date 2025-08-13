import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:greeny_mobile/screens/chilli_prediction.dart';
import 'package:greeny_mobile/screens/chili_quality.dart';
import 'package:greeny_mobile/screens/chilli_prediction_page.dart';
import 'package:greeny_mobile/screens/home_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:greeny_mobile/sign_in.dart';
import 'package:greeny_mobile/screens/weed_detection.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // List of widgets for the bottom navigation bar
  static final List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    const ChilliPredictionPage(),
    const WeedDetectionPage(),
    const ChiliDetectionPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Logout function with rflutter_alert confirmation
  Future<void> _logout(BuildContext context) async {
    await Alert(
      context: context,
      type: AlertType.warning,
      title: "LOGOUT",
      desc: "Are you sure you want to logout?",
      style: const AlertStyle(
        titleStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.orange,
        ),
        descStyle: TextStyle(
          fontSize: 16,
        ),
      ),
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.grey,
          child: const Text(
            "Cancel",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        DialogButton(
          onPressed: () async {
            Navigator.pop(context); // Close the dialog
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', false);
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignInPage()),
            );
          },
          color: Colors.orange,
          child: const Text(
            "Logout",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ],
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 56, 3, 45),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                _selectedIndex == 0 ? "Home" : "Prediction",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        leading: Opacity(
          opacity: 0.0,
          child: IconButton(
            icon: const Icon(Icons.menu), // dummy icon to balance layout
            onPressed: () {},
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
              BottomNavigationBarItem(
                icon: Icon(Icons.eco, size: 28),
                label: 'Weed Detection',
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.checkCircle, size: 28),
                label: 'Quality Measure',
                tooltip: 'Quality Measure',
                backgroundColor: Colors.transparent,
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.teal,
            unselectedItemColor: const Color.fromARGB(255, 105, 104, 104),
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
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeTab();
  }
}

class PredictionContent extends StatelessWidget {
  const PredictionContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImageUploadScreen();
  }
}