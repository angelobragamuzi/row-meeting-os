import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/pdf_export_result.dart';
import '../../domain/services/pdf_export_service.dart';

class PdfExportServiceImpl implements PdfExportService {
  const PdfExportServiceImpl();

  @override
  Future<PdfExportResult> exportSummaryAssistantPdf({
    required String discussionTopics,
    required String actionTasks,
    required String keyObservations,
  }) async {
    final generatedAt = DateTime.now();
    final fileName =
        'row_acoes_${DateFormat('yyyyMMdd_HHmm').format(generatedAt)}.pdf';

    final bytes = await _buildFullPackPdf(
      discussionTopics: discussionTopics,
      actionTasks: actionTasks,
      keyObservations: keyObservations,
      generatedAt: generatedAt,
    );

    final localPath = await _savePdfLocally(fileName: fileName, bytes: bytes);
    return PdfExportResult.savedLocally(
      fileName: fileName,
      localPath: localPath,
    );
  }

  Future<String> _savePdfLocally({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final targetDir = await _resolvePreferredDirectory();
    await targetDir.create(recursive: true);
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Directory> _resolvePreferredDirectory() async {
    final downloadsDir = await _resolveDownloadsDirectory();
    if (downloadsDir != null) {
      return downloadsDir;
    }

    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir;
      }
    }

    return getApplicationDocumentsDirectory();
  }

  Future<Directory?> _resolveDownloadsDirectory() async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        return downloadsDir;
      }
    } on UnsupportedError {
      // Plataforma sem diretório de downloads exposto via path_provider.
    }

    if (Platform.isAndroid) {
      final androidDownloadsDirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (androidDownloadsDirs != null && androidDownloadsDirs.isNotEmpty) {
        return androidDownloadsDirs.first;
      }
    }

    return null;
  }

  Future<Uint8List> _buildFullPackPdf({
    required String discussionTopics,
    required String actionTasks,
    required String keyObservations,
    required DateTime generatedAt,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) {
          return [
            pw.Text(
              'ROW - Ações da Reunião',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(generatedAt)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 14),
            _pdfSection(
              title: 'Tópicos de discussão',
              content: discussionTopics,
            ),
            pw.SizedBox(height: 12),
            _pdfSection(title: 'Tarefas sugeridas', content: actionTasks),
            pw.SizedBox(height: 12),
            _pdfSection(
              title: 'Observações importantes',
              content: keyObservations,
            ),
          ];
        },
      ),
    );

    return document.save();
  }

  pw.Widget _pdfSection({required String title, required String content}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey700, width: 1),
          ),
          child: pw.Text(content, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}
