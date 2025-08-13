import 'package:flutter/material.dart';
import 'package:greeny_mobile/backend_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddRecommendationsScreen extends StatefulWidget {
  const AddRecommendationsScreen({super.key});

  @override
  _AddRecommendationsScreenState createState() => _AddRecommendationsScreenState();
}

class _AddRecommendationsScreenState extends State<AddRecommendationsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final String apiUrl = "${backendUrl}add_recommendation/";

  final List<String> classNames = ["Curl Leaf", "Yellowish Leaf", "Spot Leaf"];
  String? selectedClass;

  Future<void> addRecommendation() async {
    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty || selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "class_name": selectedClass,
        "title": title,
        "description": description
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recommendation added successfully")),
      );
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        selectedClass = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add recommendation")),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.greenAccent.shade100, Colors.teal.shade50],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Scaffold(
      backgroundColor: Colors.transparent, // Important!
      appBar: AppBar(
        title: const Text("Add Recommendations"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.greenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedClass,
                        decoration: InputDecoration(
                          labelText: "Plant Condition",
                          labelStyle: TextStyle(color: Colors.teal.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.teal),
                          ),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                        ),
                        hint: const Text("Select Plant Condition"),
                        items: classNames.map((String className) {
                          return DropdownMenuItem<String>(
                            value: className,
                            child: Text(
                              className,
                              style: TextStyle(color: Colors.teal.shade800),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedClass = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: "Title",
                          labelStyle: TextStyle(color: Colors.teal.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.teal),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.teal, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: "Description",
                          labelStyle: TextStyle(color: Colors.teal.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.teal),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.teal, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                        ),
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Colors.greenAccent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: addRecommendation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Submit Recommendation",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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