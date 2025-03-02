import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/s3_item.dart';
import 'dart:io';

class S3Service {
  final String userId;

  S3Service({required this.userId});

  /// Uploads a file to S3 and ensures Firestore updates for all collaborators.
  Future<void> uploadFileToJar(String jarId, String filePath,
      List<String> collaborators, String type) async {
    try {
      final file = File(filePath);
      final key =
          'uploads/$userId/$jarId/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';

      print("📤 Uploading file to S3: $key");

      final awsFile = AWSFile.fromPath(file.path);
      await Amplify.Storage.uploadFile(
        key: key,
        localFile: awsFile,
        options: const StorageUploadFileOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      ).result;

      // Get the S3 URL after upload
      final urlResult = await Amplify.Storage.getUrl(key: key).result;
      final s3Url = urlResult.url.toString();
      print("✅ Upload completed: $s3Url");

      // Prepare the new content entry
      final Map<String, dynamic> newContent = {
        'data': s3Url,
        'type': type.toLowerCase(),
        'date': DateTime.now().toIso8601String(),
        'isDeleted': false,
      };

      // Update Firestore for owner
      final ownerJarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId);
      await ownerJarRef.update({
        'content': FieldValue.arrayUnion([newContent]),
      });

      print("✅ Content added to owner's jar: $jarId");

      // Update Firestore for each collaborator
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (String collaboratorId in collaborators) {
        final jarRef = FirebaseFirestore.instance
            .collection('users')
            .doc(collaboratorId)
            .collection('jars')
            .doc(jarId);

        batch.update(jarRef, {
          'content': FieldValue.arrayUnion([newContent])
        });

        print("✅ Content update queued for collaborator: $collaboratorId");
      }

      // Commit batch update for all collaborators
      await batch.commit();
      print("✅ Batch commit executed!");
    } catch (e) {
      print("❌ Error during upload: $e");
    }
  }

  /// Fetch contents of a specific jar (supports all collaborators)
  Future<List<S3Item>> getJarContents(String jarId) async {
    try {
      print("🔍 Fetching jar with ID: $jarId for user: $userId");

      final jarDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId)
          .get();

      if (!jarDoc.exists) {
        print('🔥 Jar does not exist for user: $userId, jarId: $jarId');
        return [];
      }

      final jarData = jarDoc.data();
      if (jarData == null || !jarData.containsKey('content')) {
        print('🔥 No content found in jar document.');
        return [];
      }

      final List<dynamic> contentList = jarData['content'];
      print("📂 Content count: ${contentList.length}");

      List<S3Item> items = contentList
          .map((item) {
            if (item is! Map || !item.containsKey('data')) return null;
            return S3Item(
              key: item['data'],
              url: item['data'],
              type: item['type'].toString().toLowerCase(),
              uploadedAt: DateTime.parse(item['date']),
              isDeleted: item['isDeleted'] ?? false,
            );
          })
          .whereType<S3Item>()
          .toList();

      print("✅ Processed ${items.length} valid items");
      return items;
    } catch (e) {
      print('❌ Error fetching jar contents: $e');
      return [];
    }
  }

  /// Syncs content for all collaborators
  Future<void> syncJarContentAcrossCollaborators(String jarId) async {
    try {
      final jarDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId)
          .get();

      if (!jarDoc.exists) {
        print('❌ Jar does not exist for current user, cannot sync');
        return;
      }

      final jarData = jarDoc.data();
      if (jarData == null) return;

      final List<String> collaborators =
          List<String>.from(jarData['collaborators'] ?? []);

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String collaboratorId in collaborators) {
        final collaboratorJarRef = FirebaseFirestore.instance
            .collection('users')
            .doc(collaboratorId)
            .collection('jars')
            .doc(jarId);

        batch.update(collaboratorJarRef, {
          'content': jarData['content'] ?? [],
        });

        print("✅ Syncing content to collaborator: $collaboratorId");
      }

      await batch.commit();
      print("✅ Content sync complete!");
    } catch (e) {
      print("❌ Error syncing jar content: $e");
    }
  }

  /// Deletes a specific item from a jar
  Future<void> deleteItemFromJar(
      String jarId, String itemKey, List<String> collaborators) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String collaboratorId in [...collaborators, userId]) {
        final jarRef = FirebaseFirestore.instance
            .collection('users')
            .doc(collaboratorId)
            .collection('jars')
            .doc(jarId);

        final jarDoc = await jarRef.get();
        if (jarDoc.exists) {
          List<dynamic> contentList =
              List.from(jarDoc.data()?['content'] ?? []);
          contentList.removeWhere((item) => item['data'] == itemKey);
          batch.update(jarRef, {'content': contentList});
        }
      }

      await batch.commit();
      print("✅ Item deleted from all collaborators!");

      // Delete from S3
      await Amplify.Storage.remove(key: itemKey);
      print("✅ Item deleted from S3: $itemKey");
    } catch (e) {
      print("❌ Error deleting item: $e");
    }
  }

  /// Deletes an entire jar and all its contents.
  Future<void> deleteJar(String jarId, List<String> collaborators) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String collaboratorId in [...collaborators, userId]) {
        final jarRef = FirebaseFirestore.instance
            .collection('users')
            .doc(collaboratorId)
            .collection('jars')
            .doc(jarId);
        batch.delete(jarRef);
      }

      await batch.commit();
      print("✅ Jar deleted from all collaborators!");

      // Get all items inside the jar to delete from S3
      final ownerJarRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId);
      final ownerJarDoc = await ownerJarRef.get();

      if (ownerJarDoc.exists) {
        List<dynamic> contentList = ownerJarDoc.data()?['content'] ?? [];
        for (var item in contentList) {
          if (item is Map && item.containsKey('data')) {
            String fileKey = item['data'];
            await Amplify.Storage.remove(key: fileKey);
            print("✅ Deleted from S3: $fileKey");
          }
        }
      }
    } catch (e) {
      print("❌ Error deleting jar: $e");
    }
  }
}
