import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/jar_data.dart';
import '../models/s3_item.dart';
import '../data_sources/firebase_data_source.dart';

/// Repository class responsible for handling archived jar operations
class ArchivedJarRepository {
  final String userId;
  final FirebaseDataSource _firebaseDataSource;

  ArchivedJarRepository({
    required this.userId,
    FirebaseDataSource? firebaseDataSource,
  }) : _firebaseDataSource = firebaseDataSource ?? FirebaseDataSource();

  /// Get all archived jars for the user
  Future<List<JarData>> getArchivedJars() async {
    try {
      print("🔍 DEBUG: Getting archived jars for user: $userId");

      // Check if the archived_jars collection exists
      final String collectionPath = 'users/$userId/archived_jars';
      final bool collectionExists =
          await _firebaseDataSource.collectionExists(collectionPath);

      if (!collectionExists) {
        print("📝 DEBUG: No archived_jars collection exists for user: $userId");
        return [];
      }

      final QuerySnapshot? snapshot = await _firebaseDataSource.getCollection(
        collectionPath,
        orderBy: 'archivedAt',
        descending: true,
      );

      if (snapshot == null) {
        return [];
      }

      return snapshot.docs.map((doc) => JarData.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error getting archived jars: $e');
      return [];
    }
  }

  /// Get all deleted content from archived jars
  Future<List<Map<String, dynamic>>> getArchivedContent() async {
    try {
      final archivedJars = await getArchivedJars();
      final List<Map<String, dynamic>> archivedContent = [];

      for (final jarData in archivedJars) {
        for (final item in jarData.content) {
          // Only include items that are explicitly deleted by this user
          if (item.isDeletedByUser(userId)) {
            archivedContent.add({
              'item': item.toS3Item(),
              'jarId': jarData.id,
              'jarName': jarData.name,
              'isArchived': true,
            });
          }
        }
      }

      return archivedContent;
    } catch (e) {
      print('❌ Error getting archived content: $e');
      return [];
    }
  }

  /// Delete an item from an archived jar
  Future<bool> deleteArchivedJarItem(String jarId, String itemUrl) async {
    try {
      final path = 'users/$userId/archived_jars/$jarId';
      final jarDoc = await _firebaseDataSource.getDocument(path);

      if (jarDoc == null || !jarDoc.exists) {
        print('❌ Archived jar not found: $jarId');
        return false;
      }

      final jarData = JarData.fromFirestore(jarDoc);
      final updatedContent =
          jarData.content.where((item) => item.url != itemUrl).toList();

      // Update the jar document with the modified content list
      final updatedJarData = jarData.copyWith(content: updatedContent);
      return await _firebaseDataSource.updateDocument(
          path, updatedJarData.toFirestore());
    } catch (e) {
      print('❌ Error deleting item from archived jar: $e');
      return false;
    }
  }

  /// Get all deleted items from all sources (active and archived jars)
  Future<List<Map<String, dynamic>>> getAllDeletedItems() async {
    try {
      final List<Map<String, dynamic>> deletedItems = [];

      // Get items from active jars where the user has deleted them
      final userJarsSnapshot = await _firebaseDataSource.getCollection(
        'users/$userId/jars',
      );

      if (userJarsSnapshot != null) {
        for (final jarDoc in userJarsSnapshot.docs) {
          final jarData = JarData.fromFirestore(jarDoc);

          for (final item in jarData.content) {
            if (item.isDeletedByUser(userId)) {
              deletedItems.add({
                'item': item.toS3Item(),
                'jarId': jarDoc.id,
                'jarName': jarData.name,
                'isArchived': false,
              });
            }
          }
        }
      }

      // Get all items from archived jars
      final archivedContent = await getArchivedContent();
      deletedItems.addAll(archivedContent);

      return deletedItems;
    } catch (e) {
      print('❌ Error getting all deleted items: $e');
      return [];
    }
  }
}
