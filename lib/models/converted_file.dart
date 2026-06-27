class ConvertedFile {
  final String id;
  final String originalMdPath;
  final String pdfPath;
  final String fileName;
  final DateTime convertedAt;
  final int fileSizeBytes;

  ConvertedFile({
    required this.id,
    required this.originalMdPath,
    required this.pdfPath,
    required this.fileName,
    required this.convertedAt,
    required this.fileSizeBytes,
  });

  factory ConvertedFile.fromJson(Map<String, dynamic> json) => ConvertedFile(
        id: json['id'] as String,
        originalMdPath: json['originalMdPath'] as String,
        pdfPath: json['pdfPath'] as String,
        fileName: json['fileName'] as String,
        convertedAt: DateTime.parse(json['convertedAt'] as String),
        fileSizeBytes: json['fileSizeBytes'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalMdPath': originalMdPath,
        'pdfPath': pdfPath,
        'fileName': fileName,
        'convertedAt': convertedAt.toIso8601String(),
        'fileSizeBytes': fileSizeBytes,
      };

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
