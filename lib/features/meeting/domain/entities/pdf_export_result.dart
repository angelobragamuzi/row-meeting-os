class PdfExportResult {
  const PdfExportResult._({
    required this.fileName,
    required this.usedLocalFallback,
    this.localPath,
  });

  final String fileName;
  final bool usedLocalFallback;
  final String? localPath;

  bool get hasLocalPath => (localPath?.trim().isNotEmpty ?? false);

  factory PdfExportResult.printDialog({required String fileName}) {
    return PdfExportResult._(fileName: fileName, usedLocalFallback: false);
  }

  factory PdfExportResult.savedLocally({
    required String fileName,
    required String localPath,
  }) {
    return PdfExportResult._(
      fileName: fileName,
      usedLocalFallback: true,
      localPath: localPath,
    );
  }
}
