import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool isProcessing = false;

  final TranslatorService translatorService = TranslatorService();
  final TTSService ttsService = TTSService();

  Future<void> pickImageAndRecognizeText() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;

    setState(() {
      imageFile = File(pickedImage.path);
      scannedText = '';
      translatedText = '';
      isProcessing = true;
    });

    final inputImage = InputImage.fromFile(imageFile!);
    final textRecognizer = TextRecognizer();
    
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      setState(() {
        scannedText = recognizedText.text;
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
    }

    textRecognizer.close();
  }

  Future<void> translateText() async {
    if (scannedText.isEmpty) return;
    setState(() => isProcessing = true);
    
    final translated = await translatorService.translate(scannedText);
    setState(() {
      translatedText = translated;
      isProcessing = false;
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

  Widget buildTextCard(String title, String text, {bool isFirst = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            blurRadius: 40,
            color: Colors.deepPurple.withOpacity(0.05),
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isFirst ? Colors.deepPurple.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFirst ? Icons.document_scanner : Icons.translate,
                  color: isFirst ? Colors.deepPurple : Colors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: isFirst ? 200.ms : 400.ms)
        .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: isFirst ? 200.ms : 400.ms)
        .scaleX(begin: 0.8, end: 1.0, duration: 600.ms, delay: isFirst ? 200.ms : 400.ms);
  }

  Widget buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isDisabled = false,
    int animationDelay = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          backgroundColor: isDisabled ? Colors.grey.shade300 : color,
          foregroundColor: isDisabled ? Colors.grey.shade600 : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isDisabled ? null : onPressed,
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: Duration(milliseconds: animationDelay))
        .slideY(begin: 0.5, end: 0, duration: 500.ms, delay: Duration(milliseconds: animationDelay))
        .scaleXY(begin: 0.8, end: 1.0, duration: 500.ms, delay: Duration(milliseconds: animationDelay));
  }

  Widget buildImageContainer() {
    if (imageFile == null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.withOpacity(0.1),
              Colors.deepPurple.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.deepPurple.withOpacity(0.2),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: Colors.deepPurple.withOpacity(0.6),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.1, duration: 2.seconds),
            const SizedBox(height: 12),
            Text(
              'Select an image to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            imageFile!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms)
            .scaleXY(begin: 0.8, end: 1.0, duration: 800.ms),
        if (isProcessing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Text Scanner",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.deepPurple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image Container
            buildImageContainer()
                .animate()
                .fadeIn(duration: 800.ms, delay: 100.ms)
                .slideY(begin: 0.3, end: 0, duration: 800.ms, delay: 100.ms),

            const SizedBox(height: 32),

            // Action Buttons Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                buildActionButton(
                  label: "Pick Image",
                  icon: Icons.image_rounded,
                  onPressed: pickImageAndRecognizeText,
                  color: Colors.deepPurple,
                  animationDelay: 200,
                ),
                buildActionButton(
                  label: "Live Camera",
                  icon: Icons.camera_alt_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LiveCameraScanner()),
                    );
                  },
                  color: Colors.blue,
                  animationDelay: 300,
                ),
                buildActionButton(
                  label: "Translate",
                  icon: Icons.translate_rounded,
                  onPressed: translateText,
                  color: Colors.teal,
                  isDisabled: scannedText.isEmpty || isProcessing,
                  animationDelay: 400,
                ),
                buildActionButton(
                  label: "Speak",
                  icon: Icons.volume_up_rounded,
                  onPressed: speakText,
                  color: Colors.orange,
                  isDisabled: scannedText.isEmpty,
                  animationDelay: 500,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // PDF Save Button (Full Width)
            SizedBox(
              width: double.infinity,
              child: buildActionButton(
                label: "Save as PDF",
                icon: Icons.picture_as_pdf_rounded,
                onPressed: saveAsPDF,
                color: Colors.redAccent,
                isDisabled: scannedText.isEmpty,
                animationDelay: 600,
              ),
            ),

            const SizedBox(height: 32),

            // Text Results
            if (scannedText.isNotEmpty)
              buildTextCard("Scanned Text", scannedText, isFirst: true),
            
            if (translatedText.isNotEmpty)
              buildTextCard("Translated Text", translatedText),

            // Loading indicator
            if (isProcessing && scannedText.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const CircularProgressIndicator()
                        .animate(onPlay: (controller) => controller.repeat())
                        .rotate(duration: 1.seconds),
                    const SizedBox(height: 16),
                    Text(
                      'Processing image...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .fadeIn(duration: 1.seconds),
                  ],
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}