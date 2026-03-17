class BackupResult {
  final String filePath;
  final int sizeBytes;

  const BackupResult({
    required this.filePath,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'file_path': filePath,
        'size_bytes': sizeBytes,
      };
}
