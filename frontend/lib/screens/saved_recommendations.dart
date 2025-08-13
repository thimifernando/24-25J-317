import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:greeny_mobile/backend_config.dart';
import 'dart:convert';
import 'package:rflutter_alert/rflutter_alert.dart';

class SavedRecommendationsPage extends StatefulWidget {
  final String userId;

  const SavedRecommendationsPage({
    super.key,
    required this.userId,
  });

  @override
  _SavedRecommendationsPageState createState() => _SavedRecommendationsPageState();
}

class _SavedRecommendationsPageState extends State<SavedRecommendationsPage> {
  List<Map<String, dynamic>> savedRecommendations = [];
  bool isLoading = true;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    fetchSavedRecommendations();
  }

  Future<void> fetchSavedRecommendations() async {
    setState(() => isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('${backendUrl}get_saved_recommendations/?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          savedRecommendations = List<Map<String, dynamic>>.from(data.map((item) => {
                "id": item["_id"],
                "title": item["title"],
                "description": item["description"],
                "class_name": item["class_name"],
                "saved_at": item["saved_at"],
              }));
        });
      } else {
        _showErrorAlert("Failed to load recommendations", response.body);
      }
    } catch (e) {
      _showErrorAlert("Network error", e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteRecommendation(String id) async {
    setState(() => isDeleting = true);
    
    try {
      final response = await http.delete(
        Uri.parse('${backendUrl}delete_saved_recommendation/$id'),
      );

      if (response.statusCode == 200) {
        _showSuccessAlert("Recommendation deleted successfully");
        fetchSavedRecommendations(); // Refresh the list
      } else {
        _showErrorAlert("Deletion failed", response.body);
      }
    } catch (e) {
      _showErrorAlert("Network error", e.toString());
    } finally {
      setState(() => isDeleting = false);
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

  void _showErrorAlert(String title, String message) {
    Alert(
      context: context,
      type: AlertType.error,
      title: title,
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

  void _showDeleteConfirmation(String id) {
    Alert(
      context: context,
      type: AlertType.warning,
      title: "Confirm Delete",
      desc: "Are you sure you want to delete this recommendation?",
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.grey,
          child: const Text("Cancel", style: TextStyle(color: Colors.white)),
        ),
        DialogButton(
          onPressed: () {
            Navigator.pop(context);
            deleteRecommendation(id);
          },
          color: Colors.red,
          child: const Text("Delete", style: TextStyle(color: Colors.white)),
        ),
      ],
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Recommendations'),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : savedRecommendations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_remove, size: 50, color: Colors.white70),
                        const SizedBox(height: 16),
                        const Text(
                          'No saved recommendations yet',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: fetchSavedRecommendations,
                          child: const Text(
                            'Refresh',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchSavedRecommendations,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: savedRecommendations.length,
                      itemBuilder: (context, index) {
                        final rec = savedRecommendations[index];
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rec["title"] ?? "No title",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                    ),
                                    if (isDeleting)
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _showDeleteConfirmation(rec["id"]),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  rec["description"] ?? "No description",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                        rec["class_name"] ?? "Unknown",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Saved: ${rec["saved_at"] ?? "Unknown"}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}