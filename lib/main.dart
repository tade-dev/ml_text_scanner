import 'package:flutter/material.dart';
import 'package:ml_text_scanner/screens/home.dart';

void main(List<String> args) {
  runApp(const MLTextScannerApp());
}

class MLTextScannerApp extends StatefulWidget {
  const MLTextScannerApp({super.key});

  @override
  State<MLTextScannerApp> createState() => _MLTextScannerAppState();
}

class _MLTextScannerAppState extends State<MLTextScannerApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ML Text Scanner',
      debugShowCheckedModeBanner: false,
      home: const OCRHomePage(),
    );
  }
}