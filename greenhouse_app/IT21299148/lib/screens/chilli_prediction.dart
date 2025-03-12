import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image;
  String? prediction;
  double? confidence;
  final ImagePicker _picker = ImagePicker();

  Future pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      uploadImage();
    }
  }

  Future uploadImage() async {
    if (_image == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.8.105:8001/predict/'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = jsonDecode(await response.stream.bytesToString());
      setState(() {
        prediction = responseData['class'];
        confidence = responseData['confidence'];
      });
    } else {
      setState(() {
        prediction = 'Error in prediction';
        confidence = 0.0;
      });
    }
  }

  void showRecommendations() {
    String recommendationText = '';

    if (prediction == "Curl Leaf") {
      recommendationText = '''
- Avoid overuse of nitrogen fertilizers.
- Use neem oil spray to control pests.
- Ensure proper watering to prevent stress.
- Remove infected leaves to prevent spread.''';
    } else if (prediction == "Yellowish Leaf") {
      recommendationText = '''
- Check for iron and nitrogen deficiency.
- Apply organic compost or balanced fertilizers.
- Ensure proper drainage to prevent root rot.
- Use disease-resistant chilli plant varieties.''';
    } else if (prediction == "Spot Leaf") {
      recommendationText = '''
- Remove and destroy infected leaves.
- Apply copper-based fungicides.
- Avoid overhead watering to reduce moisture on leaves.
- Improve air circulation by proper spacing of plants.''';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Recommendations',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(recommendationText),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text(
        'Chilli Leaf Disease Detection',
        textAlign: TextAlign.center, // Center the title
        style: TextStyle(
          color: Colors.white, // Foreground color (text color)
        ),
      ),
      centerTitle: true, // Ensure the title is centered
      backgroundColor: const Color.fromARGB(255, 113, 80, 15), // Background color of the AppBar
      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
    ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 238, 167, 222),
              const Color(0xFF2E7D32),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: 300,
                    height: 300,
                    child: _image == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No image selected',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              _image!,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (prediction != null)
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Prediction: $prediction\nConfidence: ${(confidence! * 100).toStringAsFixed(2)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          if (prediction == "Curl Leaf" ||
                              prediction == "Yellowish Leaf" ||
                              prediction == "Spot Leaf")
                            ElevatedButton(
                              onPressed: showRecommendations,
                              child: const Text('View Recommendations'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}