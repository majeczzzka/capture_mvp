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

  S3Item copyWith({
    String? key,
    String? url,
    String? type,
    DateTime? uploadedAt,
    bool? isDeleted,
  }) {
    return S3Item(
      key: key ?? this.key,
      url: url ?? this.url,
      type: type ?? this.type,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'url': url,
      'type': type,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}
