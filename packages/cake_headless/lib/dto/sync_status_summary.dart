class SyncStatusSummary {
  final bool isSynced;
  final double progress;
  final int? currentHeight;
  final int? targetHeight;
  final String displayText;

  const SyncStatusSummary({
    required this.isSynced,
    required this.progress,
    this.currentHeight,
    this.targetHeight,
    required this.displayText,
  });

  Map<String, dynamic> toJson() => {
        'is_synced': isSynced,
        'progress': progress,
        if (currentHeight != null) 'current_height': currentHeight,
        if (targetHeight != null) 'target_height': targetHeight,
        'display_text': displayText,
      };
}
