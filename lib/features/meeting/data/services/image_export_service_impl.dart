import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/image_export_result.dart';
import '../../domain/services/image_export_service.dart';

class ImageExportServiceImpl implements ImageExportService {
  const ImageExportServiceImpl();

  @override
  Future<ImageExportResult> exportSummaryAssistantImage({
    required String discussionTopics,
    required String actionTasks,
    required String keyObservations,
  }) async {
    final generatedAt = DateTime.now();
    final fileName =
        'row_acoes_${DateFormat('yyyyMMdd_HHmm').format(generatedAt)}.png';

    final bytes = await _buildFullPackImage(
      discussionTopics: discussionTopics,
      actionTasks: actionTasks,
      keyObservations: keyObservations,
      generatedAt: generatedAt,
    );

    final localPath = await _saveImageLocally(fileName: fileName, bytes: bytes);
    return ImageExportResult.savedLocally(
      fileName: fileName,
      localPath: localPath,
    );
  }

  Future<String> _saveImageLocally({
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

  Future<Uint8List> _buildFullPackImage({
    required String discussionTopics,
    required String actionTasks,
    required String keyObservations,
    required DateTime generatedAt,
  }) async {
    const canvasWidth = 1200.0;
    const horizontalPadding = 56.0;
    const verticalPadding = 56.0;
    const sectionSpacing = 28.0;
    const sectionInnerPadding = 18.0;

    final contentWidth = canvasWidth - (horizontalPadding * 2);

    final titleParagraph = _buildParagraph(
      text: 'ROW - Ações da Reunião',
      maxWidth: contentWidth,
      fontSize: 52,
      fontWeight: ui.FontWeight.w700,
      color: const ui.Color(0xFF111111),
      lineHeight: 1.1,
    );

    final generatedAtParagraph = _buildParagraph(
      text: 'Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(generatedAt)}',
      maxWidth: contentWidth,
      fontSize: 24,
      fontWeight: ui.FontWeight.w400,
      color: const ui.Color(0xFF444444),
      lineHeight: 1.25,
    );

    final sections = [
      _ImageSectionLayout(
        titleParagraph: _buildParagraph(
          text: 'Tópicos de discussão',
          maxWidth: contentWidth,
          fontSize: 28,
          fontWeight: ui.FontWeight.w700,
          color: const ui.Color(0xFF1E1E1E),
          lineHeight: 1.2,
        ),
        contentParagraph: _buildParagraph(
          text: discussionTopics,
          maxWidth: contentWidth - (sectionInnerPadding * 2),
          fontSize: 24,
          fontWeight: ui.FontWeight.w400,
          color: const ui.Color(0xFF1E1E1E),
          lineHeight: 1.45,
        ),
      ),
      _ImageSectionLayout(
        titleParagraph: _buildParagraph(
          text: 'Tarefas sugeridas',
          maxWidth: contentWidth,
          fontSize: 28,
          fontWeight: ui.FontWeight.w700,
          color: const ui.Color(0xFF1E1E1E),
          lineHeight: 1.2,
        ),
        contentParagraph: _buildParagraph(
          text: actionTasks,
          maxWidth: contentWidth - (sectionInnerPadding * 2),
          fontSize: 24,
          fontWeight: ui.FontWeight.w400,
          color: const ui.Color(0xFF1E1E1E),
          lineHeight: 1.45,
        ),
      ),
      _ImageSectionLayout(
        titleParagraph: _buildParagraph(
          text: 'Observações importantes',
          maxWidth: contentWidth,
          fontSize: 28,
          fontWeight: ui.FontWeight.w700,
          color: const ui.Color(0xFF1E1E1E),
          lineHeight: 1.2,
        ),
        contentParagraph: _buildParagraph(
          text: keyObservations,
          maxWidth: contentWidth - (sectionInnerPadding * 2),
          fontSize: 24,
          fontWeight: ui.FontWeight.w400,
          color: const ui.Color(0xFF1E1E1E),
          lineHeight: 1.45,
        ),
      ),
    ];

    var totalHeight =
        verticalPadding +
        titleParagraph.height +
        12 +
        generatedAtParagraph.height +
        24;

    for (final section in sections) {
      totalHeight +=
          section.titleParagraph.height +
          8 +
          section.contentParagraph.height +
          (sectionInnerPadding * 2) +
          sectionSpacing;
    }

    totalHeight += verticalPadding - sectionSpacing;

    final canvasHeight = totalHeight.ceil();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, canvasWidth, canvasHeight.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );

    final sectionFillPaint = ui.Paint()..color = const ui.Color(0xFFF5F5F5);
    final sectionBorderPaint = ui.Paint()
      ..color = const ui.Color(0xFFBDBDBD)
      ..strokeWidth = 2
      ..style = ui.PaintingStyle.stroke;

    var y = verticalPadding;

    canvas.drawParagraph(titleParagraph, ui.Offset(horizontalPadding, y));
    y += titleParagraph.height + 12;

    canvas.drawParagraph(generatedAtParagraph, ui.Offset(horizontalPadding, y));
    y += generatedAtParagraph.height + 24;

    for (final section in sections) {
      canvas.drawParagraph(
        section.titleParagraph,
        ui.Offset(horizontalPadding, y),
      );
      y += section.titleParagraph.height + 8;

      final blockHeight =
          section.contentParagraph.height + (sectionInnerPadding * 2);
      final blockRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(horizontalPadding, y, contentWidth, blockHeight),
        const ui.Radius.circular(12),
      );

      canvas.drawRRect(blockRect, sectionFillPaint);
      canvas.drawRRect(blockRect, sectionBorderPaint);
      canvas.drawParagraph(
        section.contentParagraph,
        ui.Offset(
          horizontalPadding + sectionInnerPadding,
          y + sectionInnerPadding,
        ),
      );

      y += blockHeight + sectionSpacing;
    }

    final image = await recorder.endRecording().toImage(
      canvasWidth.toInt(),
      canvasHeight,
    );

    final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (pngData == null) {
      throw Exception('Não foi possível gerar bytes da imagem.');
    }

    return pngData.buffer.asUint8List();
  }

  ui.Paragraph _buildParagraph({
    required String text,
    required double maxWidth,
    required double fontSize,
    required ui.FontWeight fontWeight,
    required ui.Color color,
    required double lineHeight,
  }) {
    final normalized = text.trim().isEmpty ? '-' : text.trim();

    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textDirection: ui.TextDirection.ltr,
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: lineHeight,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: lineHeight,
            ),
          )
          ..addText(normalized);

    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
    return paragraph;
  }
}

class _ImageSectionLayout {
  const _ImageSectionLayout({
    required this.titleParagraph,
    required this.contentParagraph,
  });

  final ui.Paragraph titleParagraph;
  final ui.Paragraph contentParagraph;
}
