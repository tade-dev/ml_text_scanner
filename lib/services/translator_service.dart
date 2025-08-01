import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslatorService {
  final onDeviceTranslator = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.english,
    targetLanguage: TranslateLanguage.spanish,
  );

  Future<String> translate(String text) async {
    return await onDeviceTranslator.translateText(text);
  }

  void dispose() {
    onDeviceTranslator.close();
  }
}