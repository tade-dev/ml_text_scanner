import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LiveCameraScanner extends StatefulWidget {
  const LiveCameraScanner({super.key});

  @override
  State<LiveCameraScanner> createState() => _LiveCameraScannerState();
}

class _LiveCameraScannerState extends State<LiveCameraScanner> {
  late CameraController _controller;
  late List<CameraDescription> cameras;
  bool isBusy = false;
  String recognizedText = '';

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller.initialize();
    _controller.startImageStream(processCameraImage);
    setState(() {});
  }

  void processCameraImage(CameraImage image) async {
    if (isBusy) return;
    isBusy = true;

    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final InputImageRotation rotation = InputImageRotation.rotation0deg;
    final InputImageFormat format = InputImageFormatMethods.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: rotation,
      inputImageFormat: format,
      planeData: planeData,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    final textRecognizer = TextRecognizer();
    final result = await textRecognizer.processImage(inputImage);

    setState(() {
      recognizedText = result.text;
    });

    textRecognizer.close();
    isBusy = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Live Camera OCR")),
      body: Stack(
        children: [
          CameraPreview(_controller),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.6),
              padding: const EdgeInsets.all(16),
              child: Text(
                recognizedText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}