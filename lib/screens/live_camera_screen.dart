import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LiveCameraScanner extends StatefulWidget {
  const LiveCameraScanner({super.key});

  @override
  State<LiveCameraScanner> createState() => _LiveCameraScannerState();
}

class _LiveCameraScannerState extends State<LiveCameraScanner> {
  late CameraController _cameraController;
  bool _isDetecting = false;
  String _recognizedText = '';
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    _cameraController = CameraController(
      _cameras!.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController.initialize();
    _startImageStream();
    setState(() {});
  }

  void _startImageStream() {
    final textRecognizer = TextRecognizer();

    _cameraController.startImageStream((CameraImage image) async {
      if (_isDetecting) return;

      _isDetecting = true;

      try {
        final WriteBuffer allBytes = WriteBuffer();
        for (Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }

        final bytes = allBytes.done().buffer.asUint8List();

        final Size imageSize = Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );

        final inputImageRotation = InputImageRotation.rotation0deg;

        final inputImageFormat = _getImageFormat(image);

        final inputImageData = InputImageMetadata(
          size: imageSize, 
          rotation: inputImageRotation, 
          format: inputImageFormat, 
          bytesPerRow: 1
        );

        final inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: inputImageData
        );

        final RecognizedText result = await textRecognizer.processImage(inputImage);

        setState(() {
          _recognizedText = result.text;
        });
      } catch (e) {
        debugPrint("Error in image stream: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  InputImageFormat _getImageFormat(CameraImage image) {
    switch (image.format.raw) {
      case 35:
        return InputImageFormat.yuv420;
      case 17:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.nv21; // fallback
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Camera OCR"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _cameraController.value.isInitialized
          ? Stack(
              children: [
                CameraPreview(_cameraController),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withOpacity(0.7),
                    child: SingleChildScrollView(
                      child: Text(
                        _recognizedText.isEmpty ? "Scanning..." : _recognizedText,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}