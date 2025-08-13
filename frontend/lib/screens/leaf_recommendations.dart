import 'package:flutter/material.dart';
import 'package:greeny_mobile/backend_config.dart';
import 'package:http/http.dart' as http;
import 'package:greeny_mobile/screens/saved_recommendations.dart';
import 'dart:convert';
import 'package:rflutter_alert/rflutter_alert.dart'; // Added

class LeafRecommendationsPage extends StatefulWidget {
  final List<Map<String, String>> recommendations;
  final String prediction;
  final String userId;

  const LeafRecommendationsPage({
    super.key,
    required this.recommendations,
    required this.prediction,
    required this.userId,
  });

  @override
  _LeafRecommendationsPageState createState() => _LeafRecommendationsPageState();
}

class _LeafRecommendationsPageState extends State<LeafRecommendationsPage> {
  bool _isSaving = false; // Track saving state

  Future<void> saveRecommendation(BuildContext context, String title, String description) async {
    if (_isSaving) return; // Prevent duplicate saves

    setState(() => _isSaving = true);
    
    try {
      final response = await http.post(
        Uri.parse('${backendUrl}save_recommendation/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'class_name': widget.prediction,
          'user_id': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessAlert("Saved to your recommendations!");
      } else {
        _showErrorAlert("Failed to save: ${response.body}");
      }
    } catch (e) {
      _showErrorAlert("Network error: ${e.toString()}");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ===== Alert Helpers =====
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
        title: Text('Recommendations for ${widget.prediction}'),
        backgroundColor: const Color.fromARGB(255, 113, 80, 15),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedRecommendationsPage(userId: widget.userId),
                ),
              );
            },
          ),
        ],
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
        child: widget.recommendations.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 50, color: Colors.white70),
                    SizedBox(height: 16),
                    Text(
                      'No recommendations available',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.recommendations.length,
                itemBuilder: (context, index) {
                  final rec = widget.recommendations[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec["title"] ?? "No title",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rec["description"] ?? "No description",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _isSaving
                                ? const CircularProgressIndicator()
                                : ElevatedButton.icon(
                                    onPressed: () => saveRecommendation(
                                      context, 
                                      rec["title"] ?? "", 
                                      rec["description"] ?? "",
                                    ),
                                    icon: const Icon(Icons.bookmark_add),
                                    label: const Text('Save'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}