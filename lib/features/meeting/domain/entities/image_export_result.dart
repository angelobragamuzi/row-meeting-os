class ImageExportResult {
  const ImageExportResult._({
    required this.fileName,
    required this.usedLocalFallback,
    this.localPath,
  });

  final String fileName;
  final bool usedLocalFallback;
  final String? localPath;

  bool get hasLocalPath => (localPath?.trim().isNotEmpty ?? false);

  factory ImageExportResult.savedLocally({
    required String fileName,
    required String localPath,
  }) {
    return ImageExportResult._(
      fileName: fileName,
      usedLocalFallback: true,
      localPath: localPath,
    );
  }
}
