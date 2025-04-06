import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/jar_data.dart';
import '../data_sources/firebase_data_source.dart';

/// Repository class responsible for handling jar data operations
class JarRepository {
  final String userId;
  final FirebaseDataSource _firebaseDataSource;

  JarRepository({
    required this.userId,
    FirebaseDataSource? firebaseDataSource,
  }) : _firebaseDataSource = firebaseDataSource ?? FirebaseDataSource();

  /// Get a stream of jars for the current user
  Stream<List<JarData>> getJarsStream() {
    final path = 'users/$userId/jars';
    return _firebaseDataSource.getCollectionStream(path).map((snapshot) =>
        snapshot.docs.map((doc) => JarData.fromFirestore(doc)).toList());
  }

  /// Get a single jar by ID
  Future<JarData?> getJarById(String jarId) async {
    try {
      final path = 'users/$userId/jars/$jarId';
      final docSnapshot = await _firebaseDataSource.getDocument(path);

      if (docSnapshot != null && docSnapshot.exists) {
        return JarData.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print('❌ Error getting jar: $e');
      return null;
    }
  }

  /// Create a new jar
  Future<String?> createJar(JarData jarData) async {
    try {
      // Create the jar in the main jars collection
      final jarRef = await _firebaseDataSource.createDocument(
          'jars', jarData.toFirestore());

      if (jarRef == null) {
        throw Exception('Failed to create jar in main collection');
      }

      // Add the jar to each collaborator's collection
      for (final collaboratorId in jarData.collaborators) {
        final collaboratorPath = 'users/$collaboratorId/jars/${jarRef.id}';
        await _firebaseDataSource.setDocument(
            collaboratorPath, jarData.toFirestore());
      }

      return jarRef.id;
    } catch (e) {
      print('❌ Error creating jar: $e');
      return null;
    }
  }

  /// Update a jar
  Future<bool> updateJar(String jarId, JarData jarData) async {
    try {
      final path = 'users/$userId/jars/$jarId';
      return await _firebaseDataSource.updateDocument(
          path, jarData.toFirestore());
    } catch (e) {
      print('❌ Error updating jar: $e');
      return false;
    }
  }

  /// Delete an item from a jar
  Future<bool> deleteJarItem(String jarId, String itemUrl) async {
    try {
      final path = 'users/$userId/jars/$jarId';
      final jarSnapshot = await _firebaseDataSource.getDocument(path);

      if (jarSnapshot == null || !jarSnapshot.exists) {
        return false;
      }

      final jarData = JarData.fromFirestore(jarSnapshot);
      final updatedContent = jarData.content.map((item) {
        if (item.url == itemUrl) {
          // Add the current user to the deletedByUsers list if not already there
          final updatedDeletedByUsers = List<String>.from(item.deletedByUsers);
          if (!updatedDeletedByUsers.contains(userId)) {
            updatedDeletedByUsers.add(userId);
          }

          return ContentItem(
            type: item.type,
            url: item.url,
            uploadedBy: item.uploadedBy,
            uploadedAt: item.uploadedAt,
            deletedByUsers: updatedDeletedByUsers,
          );
        }
        return item;
      }).toList();

      // Update the jar with the modified content
      final updatedJarData = jarData.copyWith(content: updatedContent);
      return await _firebaseDataSource.updateDocument(
          path, updatedJarData.toFirestore());
    } catch (e) {
      print('❌ Error deleting jar item: $e');
      return false;
    }
  }

  /// Restore a deleted item from a jar
  Future<bool> restoreJarItem(String jarId, String itemUrl) async {
    try {
      final path = 'users/$userId/jars/$jarId';
      final jarSnapshot = await _firebaseDataSource.getDocument(path);

      if (jarSnapshot == null || !jarSnapshot.exists) {
        return false;
      }

      final jarData = JarData.fromFirestore(jarSnapshot);
      final updatedContent = jarData.content.map((item) {
        if (item.url == itemUrl) {
          // Remove the current user from the deletedByUsers list
          final updatedDeletedByUsers = List<String>.from(item.deletedByUsers)
            ..remove(userId);

          return ContentItem(
            type: item.type,
            url: item.url,
            uploadedBy: item.uploadedBy,
            uploadedAt: item.uploadedAt,
            deletedByUsers: updatedDeletedByUsers,
          );
        }
        return item;
      }).toList();

      // Update the jar with the modified content
      final updatedJarData = jarData.copyWith(content: updatedContent);
      return await _firebaseDataSource.updateDocument(
          path, updatedJarData.toFirestore());
    } catch (e) {
      print('❌ Error restoring jar item: $e');
      return false;
    }
  }

  /// Get all deleted items from all jars
  Future<List<Map<String, dynamic>>> getAllDeletedItems() async {
    try {
      final List<Map<String, dynamic>> deletedItems = [];

      // Get items from active jars
      final activePath = 'users/$userId/jars';
      final activeSnapshot =
          await _firebaseDataSource.getCollection(activePath);

      if (activeSnapshot != null) {
        for (final doc in activeSnapshot.docs) {
          final jarData = JarData.fromFirestore(doc);

          for (final item in jarData.content) {
            if (item.isDeletedByUser(userId)) {
              deletedItems.add({
                'item': item.toS3Item(),
                'jarId': jarData.id,
                'jarName': jarData.name,
                'isArchived': false,
              });
            }
          }
        }
      }

      // Get items from archived jars
      final archivedPath = 'users/$userId/archived_jars';
      final archivedSnapshot =
          await _firebaseDataSource.getCollection(archivedPath);

      if (archivedSnapshot != null) {
        for (final doc in archivedSnapshot.docs) {
          final jarData = JarData.fromFirestore(doc);

          for (final item in jarData.content) {
            if (item.isDeletedByUser(userId)) {
              deletedItems.add({
                'item': item.toS3Item(),
                'jarId': jarData.id,
                'jarName': jarData.name,
                'isArchived': true, // Mark as archived
              });
            }
          }
        }
      }

      return deletedItems;
    } catch (e) {
      print('❌ Error getting all deleted items: $e');
      return [];
    }
  }

  /// Filter jars by search query (case-insensitive)
  Stream<List<JarData>> getFilteredJarsStream(String searchQuery) {
    return getJarsStream().map((jars) {
      return jars.where((jar) {
        return jar.name.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  /// Leave a jar (remove the user from its collaborators)
  Future<bool> leaveJar(String jarId) async {
    try {
      print('🗑 Attempting to leave jar: $jarId for user: $userId');

      // Get the jar document
      final path = 'users/$userId/jars/$jarId';
      final jarDoc = await _firebaseDataSource.getDocument(path);

      if (jarDoc == null || !jarDoc.exists) {
        print('❌ Jar not found: $jarId');
        return false;
      }

      // Archive all content in the jar for this user before removing it
      print("🗄️ Archiving all jar content before removing");

      final jarData = jarDoc.data() as Map<String, dynamic>;
      List<dynamic> contentList = List.from(jarData['content'] ?? []);
      print("🗄️ Processing ${contentList.length} items for archiving");

      // Create a copy of the jar document in the archived_jars collection
      final archivedPath = 'users/$userId/archived_jars/$jarId';

      // Add deletion timestamp and copy the jar data
      final archivedJarData = Map<String, dynamic>.from(jarData);
      archivedJarData['archivedAt'] = DateTime.now().toIso8601String();
      archivedJarData['originalJarId'] = jarId;

      // Calculate deletion date (for 90-day auto cleanup)
      final deleteExpiry = DateTime.now().add(const Duration(days: 90));

      // Mark each content item as deleted by this user
      for (int i = 0; i < contentList.length; i++) {
        if (contentList[i] is Map) {
          Map<String, dynamic> item = Map<String, dynamic>.from(contentList[i]);

          // Initialize or get the deletedByUsers list
          List<String> deletedByUsers = [];
          if (item.containsKey('deletedByUsers') &&
              item['deletedByUsers'] != null) {
            deletedByUsers = List<String>.from(item['deletedByUsers']);
          }

          // Ensure this user is in the deletedByUsers list
          if (!deletedByUsers.contains(userId)) {
            deletedByUsers.add(userId);
            print("🗄️ Adding user $userId to deletedByUsers for item");
          }

          // Update the item with deletion info
          item['deletedByUsers'] = deletedByUsers;
          item['deleteExpiry'] = deleteExpiry.toIso8601String();
          item['isDeleted'] = true;

          contentList[i] = item;
        }
      }

      // Update the jar data with marked deleted items
      archivedJarData['content'] = contentList;

      // Save to archived_jars collection
      await _firebaseDataSource.setDocument(archivedPath, archivedJarData);
      print(
          "✅ Jar archived for user $userId with ${contentList.length} items marked as deleted");

      // Update the jar with marked deleted items (this is for consistency before deletion)
      await _firebaseDataSource.updateDocument(path, {'content': contentList});
      print("✅ All jar content marked as deleted for user $userId");

      // Now delete the jar document for this user
      final deleteResult = await _firebaseDataSource.deleteDocument(path);

      if (deleteResult) {
        print('✅ Successfully left jar: $jarId');
      } else {
        print('❌ Failed to leave jar: $jarId');
      }

      return deleteResult;
    } catch (e) {
      print('❌ Error leaving jar: $e');
      return false;
    }
  }
}
