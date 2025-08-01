import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class PDFService {
  static Future<void> generateAndPrintPDF(String content) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Text(content),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<File> savePDFToFile(String content) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) => pw.Text(content)));

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/scanned_text.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}