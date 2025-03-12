import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeTab extends StatelessWidget {
  final List<String> imagePaths = [
    'assets/chilli1.jpg',
    'assets/chilli2.jpg',
    'assets/chilli3.jpg',
  ];

  final List<Map<String, dynamic>> features = [
    {'title': 'Disease Identification', 'icon': FontAwesomeIcons.disease, 'bgImage': 'assets/disease_identification.jpg'},
    {'title': 'Quality Measurement', 'icon': FontAwesomeIcons.checkCircle, 'bgImage': 'assets/quality.jpg'},
    {'title': 'Weed Detection', 'icon': FontAwesomeIcons.seedling, 'bgImage': 'assets/weed.jpg'},
    {'title': 'Environmental Optimization', 'icon': FontAwesomeIcons.leaf, 'bgImage': 'assets/environment.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity, // Ensures the container fills the whole screen
        width: double.infinity,  // Ensures the container fills the whole screen
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 238, 167, 222), const Color(0xFF2E7D32)], // Green gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              // Title added here
              Text(
                "Welcome to Greeny",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text for better contrast
                ),
              ),
              SizedBox(height: 20),
              CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
                items: imagePaths.map((item) => Container(
                  margin: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: AssetImage(item),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.2), // Adjust opacity here for carousel images
                        BlendMode.darken,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              SizedBox(height: 50),
              Text(
                "Our Features",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text for better contrast
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: features.length,
                  itemBuilder: (context, index) {
                    return Card(
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
                              Colors.black.withOpacity(0.5), // Adjust opacity here for feature cards
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
                            SizedBox(height: 10),
                            Text(
                              features[index]['title'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
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