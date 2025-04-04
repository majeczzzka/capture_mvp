import 'package:cloud_firestore/cloud_firestore.dart';

class S3Item {
  final String key;
  final String url;
  final String type; // 'image', 'video', 'audio', etc.
  final DateTime uploadedAt;
  final bool isDeleted;
  final List<String>
      deletedByUsers; // List of user IDs who have deleted this item

  S3Item({
    required this.key,
    required this.url,
    required this.type,
    required this.uploadedAt,
    this.isDeleted = false,
    this.deletedByUsers = const [], // Default empty list
  });

  /// Check if a specific user has deleted this item
  bool isDeletedByUser(String userId) {
    return deletedByUsers.contains(userId);
  }

  S3Item copyWith({
    String? key,
    String? url,
    String? type,
    DateTime? uploadedAt,
    bool? isDeleted,
    List<String>? deletedByUsers,
  }) {
    return S3Item(
      key: key ?? this.key,
      url: url ?? this.url,
      type: type ?? this.type,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedByUsers: deletedByUsers ?? this.deletedByUsers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'url': url,
      'type': type,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedByUsers': deletedByUsers,
    };
  }

  /// Create an S3Item from a Firebase document
  factory S3Item.fromFirestore(Map<String, dynamic> data) {
    return S3Item(
      key: data['data'] ?? '',
      url: data['data'] ?? '',
      type: data['type'] ?? 'unknown',
      uploadedAt:
          data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
      deletedByUsers: data['deletedByUsers'] != null
          ? List<String>.from(data['deletedByUsers'])
          : [],
    );
  }
}
