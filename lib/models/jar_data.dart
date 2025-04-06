import 'package:cloud_firestore/cloud_firestore.dart';
import 's3_item.dart';

/// A model representing the Firestore jar document structure.
class JarData {
  final String id;
  final String name;
  final String color;
  final List<String> collaborators;
  final bool shared;
  final List<ContentItem> content;

  /// Constructor for creating a JarData instance
  JarData({
    required this.id,
    required this.name,
    required this.color,
    required this.collaborators,
    required this.shared,
    this.content = const [],
  });

  /// Create a JarData from a Firestore document
  factory JarData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final List<ContentItem> contentItems = [];

    if (data['content'] != null && data['content'] is List) {
      for (final item in data['content']) {
        if (item is Map<String, dynamic>) {
          contentItems.add(ContentItem.fromFirestore(item));
        }
      }
    }

    return JarData(
      id: doc.id,
      name: data['name'] ?? '',
      color: data['color'] ?? '#a5c8fb',
      collaborators: data['collaborators'] != null
          ? List<String>.from(data['collaborators'])
          : [],
      shared: data['shared'] ?? false,
      content: contentItems,
    );
  }

  /// Convert JarData to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'color': color,
      'collaborators': collaborators,
      'shared': shared,
      'content': content.map((item) => item.toFirestore()).toList(),
    };
  }

  /// Create a copy of this JarData with some changes
  JarData copyWith({
    String? id,
    String? name,
    String? color,
    List<String>? collaborators,
    bool? shared,
    List<ContentItem>? content,
  }) {
    return JarData(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      collaborators: collaborators ?? this.collaborators,
      shared: shared ?? this.shared,
      content: content ?? this.content,
    );
  }
}

/// A model representing a content item in a jar's content array
class ContentItem {
  final String type;
  final String url;
  final String uploadedBy;
  final DateTime uploadedAt;
  final List<String> deletedByUsers;

  ContentItem({
    required this.type,
    required this.url,
    required this.uploadedBy,
    required this.uploadedAt,
    this.deletedByUsers = const [],
  });

  /// Create a ContentItem from Firestore data
  factory ContentItem.fromFirestore(Map<String, dynamic> data) {
    return ContentItem(
      type: data['type'] ?? 'unknown',
      url: data['data'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedAt: data['uploadedAt'] != null
          ? DateTime.parse(data['uploadedAt'])
          : DateTime.now(),
      deletedByUsers: data['deletedByUsers'] != null
          ? List<String>.from(data['deletedByUsers'])
          : [],
    );
  }

  /// Convert ContentItem to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'data': url,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
      'deletedByUsers': deletedByUsers,
    };
  }

  /// Check if a specific user has deleted this item
  bool isDeletedByUser(String userId) {
    return deletedByUsers.contains(userId);
  }

  /// Create a copy of this ContentItem with some changes
  ContentItem copyWith({
    String? type,
    String? url,
    String? uploadedBy,
    DateTime? uploadedAt,
    List<String>? deletedByUsers,
  }) {
    return ContentItem(
      type: type ?? this.type,
      url: url ?? this.url,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      deletedByUsers: deletedByUsers ?? this.deletedByUsers,
    );
  }

  /// Convert ContentItem to S3Item for backward compatibility
  S3Item toS3Item() {
    return S3Item(
      key: url,
      url: url,
      type: type,
      uploadedAt: uploadedAt,
      deletedByUsers: deletedByUsers,
    );
  }
}
