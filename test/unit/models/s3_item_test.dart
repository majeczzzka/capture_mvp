import 'package:flutter_test/flutter_test.dart';
import 'package:capture_mvp/models/s3_item.dart';

void main() {
  group('S3Item Model Tests', () {
    // Test data
    final DateTime testDate = DateTime(2023, 1, 15, 10, 30);
    final String testKey = 'test/path/image.jpg';
    final String testUrl = 'https://example.com/test/path/image.jpg';

    test('Should create a valid S3Item with required parameters', () {
      // Arrange & Act
      final S3Item item = S3Item(
        key: testKey,
        url: testUrl,
        type: 'image',
        uploadedAt: testDate,
      );

      // Assert
      expect(item.key, equals(testKey));
      expect(item.url, equals(testUrl));
      expect(item.type, equals('image'));
      expect(item.uploadedAt, equals(testDate));
      expect(item.isDeleted, isFalse);
      expect(item.deletedByUsers, isEmpty);
    });

    test('Should create a valid S3Item with all parameters', () {
      // Arrange & Act
      final S3Item item = S3Item(
        key: testKey,
        url: testUrl,
        type: 'image',
        uploadedAt: testDate,
        isDeleted: true,
        deletedByUsers: ['user1', 'user2'],
      );

      // Assert
      expect(item.key, equals(testKey));
      expect(item.url, equals(testUrl));
      expect(item.type, equals('image'));
      expect(item.uploadedAt, equals(testDate));
      expect(item.isDeleted, isTrue);
      expect(item.deletedByUsers, hasLength(2));
      expect(item.deletedByUsers, contains('user1'));
      expect(item.deletedByUsers, contains('user2'));
    });

    test('isDeletedByUser should return correct values', () {
      // Arrange
      final S3Item item = S3Item(
        key: testKey,
        url: testUrl,
        type: 'image',
        uploadedAt: testDate,
        deletedByUsers: ['user1', 'user2'],
      );

      // Act & Assert
      expect(item.isDeletedByUser('user1'), isTrue);
      expect(item.isDeletedByUser('user2'), isTrue);
      expect(item.isDeletedByUser('user3'), isFalse);
    });

    test('copyWith should return a new instance with updated values', () {
      // Arrange
      final S3Item originalItem = S3Item(
        key: testKey,
        url: testUrl,
        type: 'image',
        uploadedAt: testDate,
      );

      // Act
      final DateTime newDate = DateTime(2023, 2, 20, 15, 45);
      final S3Item updatedItem = originalItem.copyWith(
        type: 'video',
        isDeleted: true,
        uploadedAt: newDate,
        deletedByUsers: ['user1'],
      );

      // Assert
      expect(updatedItem.key, equals(originalItem.key)); // Unchanged
      expect(updatedItem.url, equals(originalItem.url)); // Unchanged
      expect(updatedItem.type, equals('video')); // Changed
      expect(updatedItem.uploadedAt, equals(newDate)); // Changed
      expect(updatedItem.isDeleted, isTrue); // Changed
      expect(updatedItem.deletedByUsers, ['user1']); // Changed

      // Original should remain unchanged
      expect(originalItem.type, equals('image'));
      expect(originalItem.uploadedAt, equals(testDate));
      expect(originalItem.isDeleted, isFalse);
      expect(originalItem.deletedByUsers, isEmpty);
    });

    test('toJson should return the correct JSON map', () {
      // Arrange
      final S3Item item = S3Item(
        key: testKey,
        url: testUrl,
        type: 'image',
        uploadedAt: testDate,
        isDeleted: true,
        deletedByUsers: ['user1', 'user2'],
      );

      // Act
      final Map<String, dynamic> json = item.toJson();

      // Assert
      expect(json['key'], equals(testKey));
      expect(json['url'], equals(testUrl));
      expect(json['type'], equals('image'));
      expect(json['uploadedAt'], equals(testDate.toIso8601String()));
      expect(json['isDeleted'], isTrue);
      expect(json['deletedByUsers'], ['user1', 'user2']);
    });

    test('fromFirestore should correctly parse Firestore data', () {
      // Arrange
      final Map<String, dynamic> firestoreData = {
        'data': testUrl,
        'type': 'image',
        'date': testDate.toIso8601String(),
        'isDeleted': true,
        'deletedByUsers': ['user1', 'user2'],
      };

      // Act
      final S3Item item = S3Item.fromFirestore(firestoreData);

      // Assert
      expect(item.key, equals(testUrl)); // key is from data field
      expect(item.url, equals(testUrl));
      expect(item.type, equals('image'));
      expect(item.uploadedAt, equals(testDate));
      expect(item.isDeleted, isTrue);
      expect(item.deletedByUsers, hasLength(2));
      expect(item.deletedByUsers, contains('user1'));
      expect(item.deletedByUsers, contains('user2'));
    });

    test('fromFirestore should handle missing data with defaults', () {
      // Arrange
      final Map<String, dynamic> incompleteData = {'type': 'unknown'};

      // Act
      final S3Item item = S3Item.fromFirestore(incompleteData);

      // Assert
      expect(item.key, equals(''));
      expect(item.url, equals(''));
      expect(item.type, equals('unknown'));
      expect(item.isDeleted, isFalse);
      expect(item.deletedByUsers, isEmpty);
    });
  });
}
