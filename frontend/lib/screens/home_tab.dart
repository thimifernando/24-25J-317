import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:greeny_mobile/screens/chili_quality.dart';
import 'package:greeny_mobile/screens/chilli_prediction_page.dart';
import 'package:greeny_mobile/screens/weed_detection.dart';

class EnvironmentalOptimizationScreen extends StatelessWidget {
  const EnvironmentalOptimizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Environmental Optimization')),
      body: const Center(child: Text('Environmental Optimization Content')),
    );
  }
}

class HomeTab extends StatelessWidget {
  final List<String> imagePaths = [
    'assets/chilli1.jpg',
    'assets/chilli2.jpg',
    'assets/chilli3.jpg',
  ];

  final List<Map<String, dynamic>> features = [
    {
      'title': 'Disease Identification',
      'icon': FontAwesomeIcons.disease,
      'bgImage': 'assets/disease_identification.jpg',
      'route': const ChilliPredictionPage(),
    },
    {
      'title': 'Quality Measurement',
      'icon': FontAwesomeIcons.checkCircle,
      'bgImage': 'assets/quality.jpg',
      'route': const ChiliDetectionPage(),
    },
    {
      'title': 'Weed Detection',
      'icon': FontAwesomeIcons.seedling,
      'bgImage': 'assets/weed.jpg',
      'route': const WeedDetectionPage(),
    },
    {
      'title': 'Environmental Optimization',
      'icon': FontAwesomeIcons.leaf,
      'bgImage': 'assets/environment.jpg',
      'route': const EnvironmentalOptimizationScreen(),
    },
  ];

  HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 238, 197, 228),
              Color.fromARGB(255, 143, 217, 147)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Welcome to Greeny",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
                items: imagePaths
                    .map((item) => Container(
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: AssetImage(item),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.2),
                                BlendMode.darken,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 50),
              const Text(
                "Our Features",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: features.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => features[index]['route'],
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: AssetImage(features[index]['bgImage']),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.5),
                                BlendMode.darken,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                features[index]['icon'],
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                features[index]['title'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
