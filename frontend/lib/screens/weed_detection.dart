import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:greeny_mobile/backend_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as imglib;

class BoundingBox {
  final int x, y, width, height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class WeedDetectionPage extends StatefulWidget {
  const WeedDetectionPage({super.key});

  @override
  _WeedDetectionPageState createState() => _WeedDetectionPageState();
}

class _WeedDetectionPageState extends State<WeedDetectionPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  late WebSocketChannel _channel;
  List<BoundingBox> _boxes = [];
  int? _imageWidth;
  int? _imageHeight;
  bool _isSendingFrame = false;
  bool _isProcessingGalleryImage = false;
  bool _isCapturing = false;
  var backendURL = '${backendURLWebSocket}ws/detect_weed';

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    _initializeWebSocket();
  }

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

  Future<void> _initializeCamera() async {
    try {
      // 1. pick a camera (back if possible, otherwise first)
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'This device has no cameras.');
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // 2. create controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      // 3. kick off initialisation and expose the future for the UI
      _initializeControllerFuture = _cameraController.initialize();
      await _initializeControllerFuture; // ← wait until it’s ready

      // 4. now it’s safe to change settings
      await _cameraController.setFlashMode(FlashMode.off);
      _flashOn = false;

      // 5. start the live stream
      await _cameraController.startImageStream(_processCameraImage);

      setState(() {}); // rebuild the UI
    } catch (e) {
      debugPrint('Camera init failed: $e');
      _showErrorAlert('Could not open the camera.\n$e');
    }
  }

  static const shift = (0xFF << 24);

  Future<imglib.Image> convertYUV420toImageColor(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int? uvPixelStride = image.planes[1].bytesPerPixel;
      var img = imglib.Image(width, height);
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex =
              uvPixelStride! * (x ~/ 2) + uvRowStride * (y ~/ 2);
          final int index = y * width + x;
          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
              .round()
              .clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          img.data[index] = shift | (b << 16) | (g << 8) | r;
        }
      }
      return imglib.Image.fromBytes(width, height, img.data);
    } catch (e) {
      print("Error converting image: $e");
      return Future.error(e);
    }
  }

  Future<Uint8List>? convertCameraImageToJpeg(CameraImage image) {
    try {
      return convertYUV420toImageColor(image).then((imglib.Image img) {
        final pngBytes = imglib.encodePng(img);
        return Uint8List.fromList(pngBytes);
      }).catchError((e) {
        print("Error converting image: $e");
        return null;
      });
    } catch (e) {
      print("Error in conversion: $e");
      return null;
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isSendingFrame || _isProcessingGalleryImage) return;
    print("Frame dimensions: ${image.width} x ${image.height}");
    final jpegBytes = await convertCameraImageToJpeg(image);
    if (jpegBytes == null) return;
    _isSendingFrame = true;
    _channel.sink.add(jpegBytes);
    print("Sent JPEG frame bytes: ${jpegBytes.length}");
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSendingFrame = false;
    });
  }

  void _initializeWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse(backendURL),
    );
    _channel.stream.listen((data) {
      try {
        final response = jsonDecode(data);
        setState(() {
          _imageWidth = response['image_width'];
          _imageHeight = response['image_height'];
          print("Annotated image dimensions: $_imageWidth x $_imageHeight");
          List boxes = response['bounding_boxes'] ?? [];
          _boxes = boxes
              .map((box) => BoundingBox(
                    x: box['x'],
                    y: box['y'],
                    width: box['width'],
                    height: box['height'],
                  ))
              .toList();
        });
      } catch (e) {
        debugPrint("Error parsing response: $e");
      }
    });
  }

  bool _flashOn = false; // current state

  Future<void> _toggleFlash() async {
    if (!_cameraController.value.isInitialized) return;

    try {
      await _cameraController.setFlashMode(
        _flashOn ? FlashMode.off : FlashMode.torch, // torch = constant light
      );
      setState(() => _flashOn = !_flashOn);
    } catch (e) {
      debugPrint('Flash toggle failed: $e');
      _showErrorAlert('Unable to change flash mode.\n$e');
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
        _isCapturing = false;
        return; // user cancelled
      }

      final Uint8List imageBytes = await pickedFile.readAsBytes();

      final captureChannel = WebSocketChannel.connect(Uri.parse(backendURL));
      captureChannel.sink.add(imageBytes);

      captureChannel.stream.listen((data) async {
        final response = jsonDecode(data);
        final int imageWidth = response['image_width'];
        final int imageHeight = response['image_height'];
        final String annImgBase64 = response['annotated_image'];

        final List<BoundingBox> captureBoxes =
            (response['bounding_boxes'] ?? [])
                .map<BoundingBox>((box) => BoundingBox(
                      x: box['x'],
                      y: box['y'],
                      width: box['width'],
                      height: box['height'],
                    ))
                .toList();

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GalleryResultPage(
              boxes: captureBoxes,
              imageWidth: imageWidth,
              imageHeight: imageHeight,
              annotatedImageBase64: annImgBase64,
            ),
          ),
        );

        captureChannel.sink.close();
        _isCapturing = false;
      }, onError: (e) {
        debugPrint('WebSocket (capture) error: $e');
        _showErrorAlert('WebSocket error during capture.\n$e');
        captureChannel.sink.close();
        _isCapturing = false;
      });
    } catch (e) {
      debugPrint('Capture error: $e');
      _showErrorAlert('Capture failed: $e');
      _isCapturing = false;
    }
  }

  void _uploadFromGallery() async {
    print("Upload from Gallery button pressed.");
    _isProcessingGalleryImage = true;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      print("Image selected: ${pickedFile.path}");
      final imageBytes = await pickedFile.readAsBytes();
      print("Image bytes length: ${imageBytes.length}");

      final galleryChannel = WebSocketChannel.connect(
        Uri.parse(backendURL),
      );
      print("WebSocket connection established for gallery upload.");

      galleryChannel.sink.add(imageBytes);
      print("Image bytes sent to WebSocket.");

      galleryChannel.stream.listen((data) async {
        print("Received data from WebSocket: $data");
        try {
          final response = jsonDecode(data);
          final int imageWidth = response['image_width'];
          final int imageHeight = response['image_height'];
          List boxes = response['bounding_boxes'] ?? [];
          List<BoundingBox> galleryBoxes = boxes
              .map((box) => BoundingBox(
                    x: box['x'],
                    y: box['y'],
                    width: box['width'],
                    height: box['height'],
                  ))
              .toList();
          final String annotatedImageBase64 = response['annotated_image'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GalleryResultPage(
                boxes: galleryBoxes,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                annotatedImageBase64: annotatedImageBase64,
              ),
            ),
          ).then((_) {
            _isProcessingGalleryImage = false;
          });
          galleryChannel.sink.close();
        } catch (e) {
          debugPrint("Error parsing gallery response: $e");
          _showErrorAlert("Error parsing gallery response: $e");
          _isProcessingGalleryImage = false;
        }
      }, onError: (error) {
        debugPrint("WebSocket error: $error");
        _showErrorAlert("WebSocket error during gallery upload:\n$error");
        _isProcessingGalleryImage = false;
      });
    } else {
      print("No image selected.");
      _showErrorAlert("No image selected.");
      _isProcessingGalleryImage = false;
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        title: const Text(
          'Garden Weed Detector',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF735D23),
        // Deeper earthy brown
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD4FC79), // Pastel Green
              Color(0xFF96E6A1), // Leafy Green
              Color(0xFFEDE574), // Light Yellow for variety
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            children: [
              const SizedBox(height: 16),
              // Camera Box with elevation and rounded corners
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: FutureBuilder(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child:
                                    Text('Camera error:\n${snapshot.error}'));
                          }
                          return Stack(
                            children: [
                              FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width - 40,
                                  // minus total horizontal padding
                                  height:
                                      MediaQuery.of(context).size.height * 0.45,
                                  child: AspectRatio(
                                    aspectRatio:
                                        _cameraController.value.aspectRatio,
                                    child: CameraPreview(_cameraController),
                                  ),
                                ),
                              ),
                              CustomPaint(
                                painter: BoundingBoxPainter(
                                  boxes: _boxes,
                                  imageWidth: _imageWidth ?? 1,
                                  imageHeight: _imageHeight ?? 1,
                                ),
                                child: Container(),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Buttons inside a card with icons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  // decoration: BoxDecoration(
                  //   color: Colors.white.withOpacity(0.9),
                  //   borderRadius: BorderRadius.circular(16),
                  //   boxShadow: const [
                  //     BoxShadow(
                  //       color: Colors.black12,
                  //       blurRadius: 18,
                  //       offset: Offset(0, 8),
                  //     ),
                  //   ],
                  // ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
                  child: Scrollbar(
                    // Optional: shows a scrollbar when scrolling
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(
                              _flashOn ? Icons.flash_on : Icons.flash_off,
                              size: 20,
                            ),
                            label: Text(_flashOn ? 'Flash On' : 'Flash Off'),
                            onPressed: _toggleFlash,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF455A64),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(92, 38),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 10),
                              textStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon:
                                const Icon(Icons.camera_alt_outlined, size: 20),
                            label: const Text('Capture'),
                            onPressed: _captureImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(92, 38),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 14),
                              textStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library_outlined,
                                size: 20),
                            label: const Text('Upload'),
                            onPressed: _uploadFromGallery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4A02B),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(92, 38),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              textStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Red boxes highlight detected weeds',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF735D23),
                    ),
                  ),
                ],
              ),
              // const SizedBox(height: 6),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Container(
              //       width: 18,
              //       height: 18,
              //       decoration: BoxDecoration(
              //         color: Colors.green,
              //         borderRadius: BorderRadius.circular(3),
              //         border: Border.all(color: Colors.black26),
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     const Text(
              //       'Green boxes highlight detected chili plants',
              //       style: TextStyle(
              //         fontSize: 14,
              //         fontWeight: FontWeight.w500,
              //         color: Color(0xFF735D23),
              //       ),
              //     ),
              //   ],
              // ),
              const Spacer(),
              // Decorative tip (optional)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: Color(0xFF735D23)),
                    const SizedBox(width: 6),
                    Text(
                      "Make sure your camera view is clear and well lit.",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<BoundingBox> boxes;
  final int imageWidth;
  final int imageHeight;

  BoundingBoxPainter({
    required this.boxes,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var box in boxes) {
      final rect = Rect.fromLTWH(
        box.x * scaleX,
        box.y * scaleY,
        box.width * scaleX,
        box.height * scaleY,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.boxes != boxes;
  }
}

class GalleryResultPage extends StatelessWidget {
  final List<BoundingBox> boxes;
  final int imageWidth;
  final int imageHeight;
  final String annotatedImageBase64;

  const GalleryResultPage({
    super.key,
    required this.boxes,
    required this.imageWidth,
    required this.imageHeight,
    required this.annotatedImageBase64,
  });

  void _showSuccessAlert(BuildContext context, String message) {
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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSuccessAlert(context, "Image processed successfully!");
    });

    final Uint8List imageBytes = base64Decode(annotatedImageBase64);

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery Detection Result')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 238, 167, 222),
              Color(0xFF2E7D32),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.black26),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Red boxes highlight detected weeds',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF735D23),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.black26),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Green boxes highlight detected chili plants',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF735D23),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.01,
                maxScale: 3.0,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                child: Stack(
                  children: [
                    Image.memory(imageBytes, fit: BoxFit.contain),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BoundingBoxPainter(
                          boxes: boxes,
                          imageWidth: imageWidth,
                          imageHeight: imageHeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
