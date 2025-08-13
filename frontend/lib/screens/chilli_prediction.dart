import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:greeny_mobile/screens/leaf_recommendations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:greeny_mobile/backend_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart'; // Added rflutter_alert

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
      home: const ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image;
  String? prediction;
  double? confidence;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // Track loading state

  List<Map<String, String>> recommendations = [];

  Future<void> fetchRecommendations(String predictionClass) async {
    final response = await http.get(
      Uri.parse('${backendUrl}get_recommendations/?class_name=$predictionClass'),
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      
      if (data is List) {
        setState(() {
          recommendations = List<Map<String, String>>.from(
            data.map((item) => {
              "title": item["title"]?.toString() ?? "",
              "description": item["description"]?.toString() ?? ""
            })
          );
        });
      } else if (data is Map) {
        setState(() {
          recommendations = [
            {
              "title": data["title"]?.toString() ?? "",
              "description": data["description"]?.toString() ?? ""
            }
          ];
        });
      }
    } else {
      setState(() {
        recommendations = [];
      });
      _showErrorAlert("Failed to load recommendations");
    }
  }

  Future pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isLoading = true; // Show loading
        });
        await uploadImage();
      }
    } catch (e) {
      _showErrorAlert("Failed to pick image: ${e.toString()}");
      setState(() => _isLoading = false);
    }
  }

  Future uploadImage() async {
    if (_image == null) return;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${chilliPredictEndpoint}predict/'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = jsonDecode(await response.stream.bytesToString());
        setState(() {
          prediction = responseData['class'];
          confidence = responseData['confidence'];
          _isLoading = false;
        });
        _showSuccessAlert("Prediction successful!");
      } else {
        setState(() {
          prediction = 'Error in prediction';
          confidence = 0.0;
          _isLoading = false;
        });
        _showErrorAlert("Prediction failed (Server error)");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorAlert("Network error: ${e.toString()}");
    }
  }

  void showRecommendations() async {
    if (prediction != null) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      setState(() => _isLoading = true);
      try {
        await fetchRecommendations(prediction!);
        setState(() => _isLoading = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeafRecommendationsPage(
              recommendations: recommendations,
              prediction: prediction!,
              userId: userId,
            ),
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorAlert("Failed to load recommendations");
      }
    }
  }

  // ===== Alert Helper Methods =====
  void _showSuccessAlert(String message) {
    Alert(
      context: context,
      type: AlertType.success,
      title: "Success",
      desc: message,
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.green,
          child: const Text("OK", style: TextStyle(color: Colors.white)),
        ),
      ],
    ).show();
  }

  void _showErrorAlert(String message) {
    Alert(
      context: context,
      type: AlertType.error,
      title: "Error",
      desc: message,
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.red,
          child: const Text("OK", style: TextStyle(color: Colors.white)),
        ),
      ],
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chilli Leaf Disease Detection',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 113, 80, 15),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 238, 197, 228),
              Color.fromARGB(255, 143, 217, 147),
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _image == null
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
                      onPressed: _isLoading ? null : () => pickImage(ImageSource.gallery),
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
                      onPressed: _isLoading ? null : () => pickImage(ImageSource.camera),
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
                if (prediction != null && !_isLoading)
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
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('View Recommendations'),
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