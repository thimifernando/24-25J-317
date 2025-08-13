import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:greeny_mobile/backend_config.dart';

class ViewRecommendationsScreen extends StatefulWidget {
  const ViewRecommendationsScreen({super.key});

  @override
  _ViewRecommendationsScreenState createState() => _ViewRecommendationsScreenState();
}

class _ViewRecommendationsScreenState extends State<ViewRecommendationsScreen> {
  final String apiUrl = "${backendUrl}get_recommendations/";
  final List<String> classNames = ["All", "Curl Leaf", "Yellowish Leaf", "Spot Leaf"];
  String selectedClass = "All";

  List<Map<String, dynamic>> recommendations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
  }

  Future<void> fetchRecommendations() async {
    setState(() => isLoading = true);

    String url = selectedClass == "All"
        ? apiUrl
        : "$apiUrl?class_name=${Uri.encodeComponent(selectedClass)}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          recommendations = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          isLoading = false;
        });
      } else {
        showError("Failed to fetch recommendations");
      }
    } catch (e) {
      showError("An error occurred: $e");
    }
  }

  void showError(String message) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> deleteRecommendation(String id) async {
  try {
    final response = await http.delete(
      Uri.parse("${backendUrl}delete_recommendation/$id"),
    );
    if (response.statusCode == 200) {
      fetchRecommendations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deleted successfully")),
      );
    } else {
      showError("Failed to delete: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    showError("Delete error: $e");
  }
}

Future<void> updateRecommendation(String id, String title, String description, String className) async {
  try {
    print("Sending update request with:");
    print("ID: $id");
    print("Title: $title");
    print("Description: $description");
    print("Class: $className");

    final response = await http.put(
      Uri.parse("${backendUrl}update_recommendation/$id"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "new_title": title,
        "new_description": description,
        "new_class_name": className
      }),
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      fetchRecommendations();
      Navigator.of(context).pop(); // close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated successfully")),
      );
    } else {
      showError("Update failed: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    print("Update error: $e");
    showError("Update error: $e");
  }
}

  void showEditDialog(Map<String, dynamic> item) {
    final String id = item["_id"]?.toString() ?? "";
    final String title = item["title"]?.toString() ?? "";
    final String description = item["description"]?.toString() ?? "";
    final String className = item["class_name"]?.toString() ?? classNames[1];

    final titleController = TextEditingController(text: title);
    final descController = TextEditingController(text: description);
    String selectedClassName = className;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade50, Colors.greenAccent.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Edit Recommendation",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Plant Condition", style: TextStyle(color: Colors.teal.shade700)),
                  DropdownButtonFormField<String>(
                    value: selectedClassName,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    items: classNames.sublist(1).map((name) {
                      return DropdownMenuItem(
                        value: name,
                        child: Text(name, style: TextStyle(color: Colors.teal.shade800)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedClassName = value);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Title",
                      labelStyle: TextStyle(color: Colors.teal.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: "Description",
                      labelStyle: TextStyle(color: Colors.teal.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.teal.shade700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Colors.teal, Colors.greenAccent],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            final updatedTitle = titleController.text.trim();
                            final updatedDesc = descController.text.trim();
                            updateRecommendation(id, updatedTitle, updatedDesc, selectedClassName);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text(
                            "Update",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Recommendations"),
        centerTitle: true,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.greenAccent.shade100, Colors.teal.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: DropdownButton<String>(
                    value: selectedClass,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.teal.shade700),
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
                      if (newValue != null) {
                        setState(() {
                          selectedClass = newValue;
                        });
                        fetchRecommendations();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                      )
                    : recommendations.isEmpty
                        ? Center(
                            child: Text(
                              "No recommendations found",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: recommendations.length,
                            itemBuilder: (context, index) {
                              final item = recommendations[index];
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            item["class_name"] ?? "Unknown",
                                            style: const TextStyle(
                                              color: Colors.teal,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.teal),
                                                onPressed: () => showEditDialog(item),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: Colors.red.shade400),
                                                onPressed: () => deleteRecommendation(item["_id"]),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item["title"] ?? "No Title",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item["description"] ?? "No Description",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade700,
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