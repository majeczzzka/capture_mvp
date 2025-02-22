class S3Item {
  final String key;
  final String url;
  final String type; // 'image', 'video', 'audio', etc.
  final DateTime uploadedAt;
  bool isDeleted;

  S3Item({
    required this.key,
    required this.url,
    required this.type,
    required this.uploadedAt,
    this.isDeleted = false,
  });
}
