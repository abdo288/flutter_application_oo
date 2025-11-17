/// معلومات التخزين
class StorageInfo {
  StorageInfo({
    this.totalSize = 0,
    this.fileCount = 0,
    this.fileDetails = const <String>[],
  });

  final int totalSize;
  final int fileCount;
  final List<String> fileDetails;

  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
