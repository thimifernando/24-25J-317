import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:greeny_mobile/backend_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

Future<pw.Document> _makePdfDocument() async {
  final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
  final ttf = pw.Font.ttf(fontData);
  final ttfBold = pw.Font.ttf(boldFontData);

  return pw.Document(
    theme: pw.ThemeData.withFont(
      base: ttf,
      bold: ttfBold,
      italic: ttf, // or load a separate italic file
      boldItalic: ttf, // or load a separate boldItalic file
    ),
  );
}

class ChiliDetectionPage extends StatefulWidget {
  const ChiliDetectionPage({super.key});

  @override
  _ChiliDetectionPageState createState() => _ChiliDetectionPageState();
}

class _ChiliDetectionPageState extends State<ChiliDetectionPage> {
  File? _selectedImage;
  Map<String, dynamic>? _result;
  bool _isLoading = false;

  final String apiUrl = '${backendUrl}detect-quality/';

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

  Future<void> _generateReport() async {
    if (_result == null) return;

    try {
      // 1️⃣ Prepare PDF document
      final pdf = await _makePdfDocument();

      // 2️⃣ Decode annotated image if present
      pw.MemoryImage? annotatedImage;
      if (_result!['image_annotated'] != null) {
        final imgBytes = base64Decode(_result!['image_annotated']);
        annotatedImage = pw.MemoryImage(imgBytes);
      }

      // 3️⃣ First page: result summary
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => [
            pw.Header(level: 0, child: pw.Text('Chili Quality Report')),
            pw.Paragraph(
              text:
                  'Predicted Class: ${getFriendlyClassName(_result!['class'])}',
            ),
            if (_result!['confidence'] != null)
              pw.Paragraph(
                text:
                    'Confidence: ${((_result!['confidence'] as num) * 100).toStringAsFixed(2)}%',
              ),
            pw.Paragraph(
              text:
                  'Market Recommendation:\n${_result!['market_recommendation']}',
            ),
            if (_result!['counts'] != null) ...[
              pw.SizedBox(height: 12),
              pw.Text('Detected Pods (rough count):',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: (_result!['counts'] as Map<String, dynamic>)
                    .entries
                    .map((e) => pw.Bullet(
                        text: '${getFriendlyClassName(e.key)}: ${e.value}'))
                    .toList(),
              ),
            ],
            if (annotatedImage != null) ...[
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Annotated Image')),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Image(annotatedImage, width: 300)),
            ],
            pw.SizedBox(height: 20),
            pw.Paragraph(text: 'Generated on: ${DateTime.now().toLocal()}'),
          ],
        ),
      );

      // 4️⃣ Second page: ALL recommendations
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => [
            pw.Header(level: 1, child: pw.Text('All Farmer Recommendations')),
            ..._chiliInfo.entries.expand((entry) {
              final title = entry.value['title'] as String;
              final recs = entry.value['recommendations'] as List<String>;
              return [
                pw.SizedBox(height: 8),
                pw.Text(title,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: recs.map((r) => pw.Bullet(text: r)).toList(),
                ),
              ];
            }),
          ],
        ),
      );

      // 5️⃣ Save to disk (same permission logic)
      final bytes = await pdf.save();
      Directory? outDir;
      String permissionError;

      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isGranted) {
          final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          );
          outDir = dirs?.first;
          permissionError = 'Manage external storage permission not granted';
        } else {
          final status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('→ Please allow “All files access” in settings.'),
              ),
            );
          }
          final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          );
          outDir = dirs?.first;
          permissionError = 'Manage external storage permission denied';
        }
      } else {
        outDir = await getApplicationDocumentsDirectory();
        permissionError = 'Could not resolve Downloads folder';
      }

      final filename =
          'chili_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${outDir?.path}/$filename');
      await file.writeAsBytes(bytes);

      _showSuccessAlert('Report saved to:\n${file.path}');
    } catch (e, stack) {
      debugPrint('_generateReport error: $e\n$stack');
      _showErrorAlert('Error generating report:\n$e');
    }
  }

  final Map<String, Map<String, dynamic>> _chiliInfo = {
    'red_chil': {
      'title': 'Red Chil',
      'suitability':
          '❌ Not suitable for green chili fresh export market.\n✅ Can be used for drying and spice powder production.',
      'infection': null,
      'recommendations': [
        'Review harvest timing to avoid overripeness and color change beyond green stage.',
        'Full red chili is not accepted for fresh export market—harvest at raw green stage for best value.',
        'Use red chilies for dry chili or chili powder production, not fresh export.',
        'Avoid late harvests.'
      ]
    },
    'chili_anthracnose_disease': {
      'title': 'Chili Anthracnose Disease',
      'suitability':
          '❌ Not suitable for any market.\n⚠️ Causes rot, black spots, and rapid spoilage—major loss risk.',
      'infection':
          'Caused by *Colletotrichum* fungus; spreads in humid conditions through rain splashes and poor airflow.',
      'recommendations': [
        'Use preventive fungicides early (e.g., Mancozeb, Copper Oxychloride).',
        'Improve airflow and avoid overhead watering to reduce humidity.',
        'Practice crop rotation and clean up infected plant residues.',
        'Harvest only healthy pods, remove infected ones immediately.'
      ]
    },
    'chili_anthrax_disease': {
      'title': 'Chili Anthrax Disease',
      'suitability':
          '❌ Not suitable for any market.\n⚠️ Leads to soft rot, lesions—unacceptable for sale or storage.',
      'infection':
          'Caused by bacterial/fungal pathogens; spreads via wet leaves, tight planting, and unclean tools.',
      'recommendations': [
        'Avoid planting in water‑logged areas; ensure proper drainage.',
        'Use disease‑free seeds and sanitize equipment regularly.',
        'Apply copper‑based bactericides early in the growth stage.',
        'Space plants properly and trim lower leaves to improve ventilation.'
      ]
    },
    'green_chili': {
      'title': 'Green Chili',
      'suitability':
          '✅ Highly suitable for fresh export market.\n🥇 This is the ideal target stage!',
      'infection': null,
      'recommendations': [
        'Maintain current harvest stage—this is best for export markets.',
        'Harvest at 32–38 days after flowering for ideal firmness and color.',
        'Avoid post‑harvest bruising—use clean gloves and soft handling.',
        'Store in cool, dry conditions to retain freshness during transport.'
      ]
    }
  };

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _result = null;
      });
      _uploadImage();
    }
  }

  String _normalize(String raw) {
    final cleaned = raw.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '_');
    return cleaned
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_\$'), '');
  }

  String _beautify(String? raw) {
    if (raw == null || raw.isEmpty) return 'Unknown';
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Widget _buildAnnotatedImage(String base64String) {
    final decodedBytes = base64Decode(base64String);
    return InteractiveViewer(
      panEnabled: true,
      scaleEnabled: true,
      minScale: 1.0,
      maxScale: 5.0,
      child: Image.memory(decodedBytes),
    );
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files
          .add(await http.MultipartFile.fromPath('file', _selectedImage!.path));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        setState(() {
          _result = json.decode(response.body);
        });
        _showSuccessAlert("Image uploaded and detected successfully!");
      } else {
        _showErrorAlert('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorAlert('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showInfoPopup({bool auto = false}) {
    // If no prediction or no class matched, show generic guidance.
    final rawClass = _result?['class']?.toString();
    final info = rawClass == null ? null : _chiliInfo[_normalize(rawClass)];

    if (info == null) {
      _showGeneralPopup();
      return;
    }

    _showDialogForInfo(title: _beautify(rawClass), info: info);
  }

  void _showGeneralPopup() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('General Market Recommendations'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _chiliInfo.values.map((info) {
                return ExpansionTile(
                  title: Text(info['title'] as String),
                  children: [_buildInfoContent(info)],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDialogForInfo(
      {required String title, required Map<String, dynamic> info}) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: _buildInfoContent(info),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoContent(Map<String, dynamic> info) {
    return SingleChildScrollView(
      child: Card(
        elevation: 2,
        color: Colors.white,
        margin: const EdgeInsets.all(6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info['suitability'] as String,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              if (info['infection'] != null) ...[
                const SizedBox(height: 14),
                const Text(
                  'Infection Reason:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(info['infection'] as String),
              ],
              const SizedBox(height: 14),
              const Text(
                'Farmer Recommendations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 7),
              ...(info['recommendations'] as List<String>).map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 18)),
                        Expanded(child: Text(rec)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountsSection(Map<String, dynamic>? counts) {
    if (counts == null || counts.isEmpty) return const SizedBox();
    final entries = counts.entries.toList()
      ..sort((a, b) =>
          getFriendlyClassName(a.key).compareTo(getFriendlyClassName(b.key)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Detected Pods (rough count):',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: entries.map((e) {
            return Chip(
              label: Text(
                '${getFriendlyClassName(e.key)}: ${e.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(0xFFD7263D).withOpacity(.85),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              elevation: 2,
            );
          }).toList(),
        ),
      ],
    );
  }

  String getFriendlyClassName(String className) {
    final words = className.split('_');
    final friendlyWords =
        words.map((word) => word[0].toUpperCase() + word.substring(1)).toList();
    return friendlyWords.join(' ');
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox();
    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: Colors.white.withOpacity(0.97),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Button Row in Card
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showInfoPopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF63A46C), // green
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('Recommendations'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generateReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF355C7D), // bluish
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Report'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Results List
              _buildLabeledTile(
                icon: Icons.label_important_rounded,
                title: 'Predicted Class',
                value: _result!['class'] != null
                    ? getFriendlyClassName(_result!['class'])
                    : 'N/A',
                valueColor: Colors.black87,
              ),

              if ((_result?['confidence'] ?? 0) > 0) ...[
                const SizedBox(height: 8),
                _buildLabeledTile(
                  icon: Icons.thumb_up_alt_rounded,
                  title: 'Confidence',
                  value:
                      '${((_result!['confidence'] as num) * 100).toStringAsFixed(2)}%',
                  valueColor: Colors.blueGrey.shade700,
                ),
              ],

              const SizedBox(height: 8),
              _buildLabeledTile(
                icon: Icons.store_mall_directory_rounded,
                title: 'Market Recommendation',
                value: _result!['market_recommendation'] ??
                    'Not suitable for market',
                valueColor: const Color(0xFFD7263D), // Chili Red
              ),

              // Counts as chips
              _buildCountsSection(_result!['counts'] as Map<String, dynamic>?),

              // Annotated image preview
              if (_result!['image_annotated'] != null) ...[
                const Divider(height: 32),
                const Text(
                  "Annotated Image:",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAnnotatedImage(_result!['image_annotated']),
              ],
            ],
          ),
        ),
      ),
    );
  }

// Pretty ListTile-alike
  Widget _buildLabeledTile({
    required IconData icon,
    required String title,
    required String value,
    Color valueColor = Colors.black,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.black54, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 4,
        title: const Text(
          'Chili Quality Detector',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF735D23), // Deep chili brown
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Image Picker Box
                Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(22),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      height: 210,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.3,
                        ),
                        color: _selectedImage == null
                            ? Colors.grey.shade200
                            : Colors.transparent,
                      ),
                      child: _selectedImage != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white60,
                                    child: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.black54),
                                      onPressed: () =>
                                          setState(() => _selectedImage = null),
                                    ),
                                  ),
                                )
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined,
                                      size: 50, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No image selected',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 22),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          elevation: 2,
                          backgroundColor: const Color(0xFFD7263D), // Chili Red
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 14.0),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 22),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          elevation: 2,
                          backgroundColor:
                              const Color(0xFFF7B32B), // Warm yellow
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 14.0),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_result != null)
                  // Use Flexible to avoid overflow and make things scrollable
                  Flexible(child: _buildResult()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
