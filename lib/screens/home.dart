import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_text_scanner/screens/live_camera_screen.dart';
import 'package:ml_text_scanner/services/pdf_services.dart';
import 'package:ml_text_scanner/services/translator_service.dart';
import 'package:ml_text_scanner/services/tts_service.dart';


class OCRHomePage extends StatefulWidget {
  const OCRHomePage({super.key});

  @override
  State<OCRHomePage> createState() => _OCRHomePageState();
}

class _OCRHomePageState extends State<OCRHomePage> {
  String scannedText = '';
  String translatedText = '';
  File? imageFile;

  final TranslatorService translatorService = TranslatorService();
  final TTSService ttsService = TTSService();

  Future<void> pickImageAndRecognizeText() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;

    setState(() {
      imageFile = File(pickedImage.path);
      scannedText = '';
      translatedText = '';
    });

    final inputImage = InputImage.fromFile(imageFile!);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    setState(() {
      scannedText = recognizedText.text;
    });

    textRecognizer.close();
  }

  Future<void> translateText() async {
    if (scannedText.isEmpty) return;
    final translated = await translatorService.translate(scannedText);
    setState(() {
      translatedText = translated;
    });
  }

  void speakText() {
    if (scannedText.isNotEmpty) {
      ttsService.speak(scannedText);
    }
  }

  void saveAsPDF() {
    if (scannedText.isNotEmpty) {
      PDFService.generateAndPrintPDF(scannedText);
    }
  }

  @override
  void dispose() {
    translatorService.dispose();
    ttsService.stop();
    super.dispose();
  }

  Widget buildTextCard(String title, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: color ?? Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Text Scanner"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(imageFile!, height: 200),
              ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                buildActionButton(
                  label: "Pick Image",
                  icon: Icons.image,
                  onPressed: pickImageAndRecognizeText,
                ),
                buildActionButton(
                  label: "Live Camera",
                  icon: Icons.camera_alt,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LiveCameraScanner()),
                    );
                  },
                ),
                buildActionButton(
                  label: "Translate",
                  icon: Icons.translate,
                  onPressed: translateText,
                  color: Colors.teal,
                ),
                buildActionButton(
                  label: "Speak",
                  icon: Icons.volume_up,
                  onPressed: speakText,
                  color: Colors.orange,
                ),
                buildActionButton(
                  label: "Save PDF",
                  icon: Icons.picture_as_pdf,
                  onPressed: saveAsPDF,
                  color: Colors.redAccent,
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (scannedText.isNotEmpty) buildTextCard("Scanned Text", scannedText),
            if (translatedText.isNotEmpty) buildTextCard("Translated Text", translatedText),
          ],
        ),
      ),
    );
  }
}