import 'package:flutter/material.dart';
import 'package:greeny_mobile/home.dart';
import 'package:greeny_mobile/screens/saved_recommendations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChilliPredictionPage extends StatelessWidget {
  const ChilliPredictionPage({super.key});

  void navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chilli Prediction', 
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.1,
          ),),
        centerTitle: true,
        backgroundColor: const Color(0xFF735D23), // Deeper earthy brown
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 238, 197, 228),
              Color.fromARGB(255, 143, 217, 147),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const SizedBox(height: 60),
              SizedBox(
                height: 200,
                child: _buildCard(
                  title: 'Start Prediction',
                  icon: Icons.search,
                  onTap: () => navigateTo(context, const PredictionContent()),
                  imagePath: 'assets/chilli_card.jpg',
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 200,
                child: _buildCard(
                  title: 'Saved Recommendations',
                  icon: Icons.bookmark,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getString('userId') ?? '';
                    navigateTo(context, SavedRecommendationsPage(userId: userId));
                  },
                  imagePath: 'assets/recommendations.jpg',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required String imagePath,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
            Center(
              child: ListTile(
                leading: Icon(icon, size: 40, color: Colors.white),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}