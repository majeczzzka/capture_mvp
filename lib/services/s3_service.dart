import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/s3_item.dart';

class S3Service {
  final String userId;

  S3Service({required this.userId});

  Future<List<S3Item>> getJarContents(String jarId) async {
    try {
      final jarDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId)
          .get();

      final content = jarDoc.data()?['content'] as List<dynamic>? ?? [];

      List<S3Item> items = [];
      for (var item in content) {
        if (item['isDeleted'] == true) continue;

        final String key = item['data'];
        String url = '';

        if (key.contains('amazonaws.com')) {
          // Extract the clean key without query parameters
          final uri = Uri.parse(key);
          final cleanPath = uri.path.replaceFirst('/public/', '');

          try {
            final urlResult = await Amplify.Storage.getUrl(
              key: cleanPath,
              options: const StorageGetUrlOptions(
                accessLevel: StorageAccessLevel.guest,
              ),
            ).result;
            url = urlResult.url.toString();
          } catch (e) {
            print('Error getting fresh URL: $e');
          }
        }

        items.add(S3Item(
          key: key,
          url: url,
          type: item['type'].toString().toLowerCase(),
          uploadedAt: DateTime.parse(item['date']),
          isDeleted: item['isDeleted'] ?? false,
        ));
      }

      return items;
    } catch (e) {
      print('Error fetching jar contents: $e');
      return [];
    }
  }

  /// Fetch an item by its key
  Future<S3Item> getItemById(String key) async {
    try {
      final jarDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .get();

      for (var jar in jarDoc.docs) {
        final content = jar.data()['content'] as List<dynamic>? ?? [];
        for (var item in content) {
          if (item['data'] == key) {
            return S3Item(
              key: item['data'],
              url: item['url'] ?? '',
              type: item['type'].toString().toLowerCase(),
              uploadedAt: DateTime.parse(item['date']),
              isDeleted: item['isDeleted'] ?? false,
            );
          }
        }
      }
      throw Exception('Item not found');
    } catch (e) {
      print('Error fetching item by ID: $e');
      rethrow;
    }
  }

  /// Update an existing item
  Future<void> updateItem(S3Item updatedItem) async {
    try {
      // Locate the jar containing the item
      final jars = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .get();

      for (var jar in jars.docs) {
        final content = jar.data()['content'] as List<dynamic>? ?? [];
        bool updated = false;
        for (var item in content) {
          if (item['data'] == updatedItem.key) {
            item['isDeleted'] = updatedItem.isDeleted;
            updated = true;
            break;
          }
        }
        if (updated) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('jars')
              .doc(jar.id)
              .update({'content': content});
          break;
        }
      }
    } catch (e) {
      print('Error updating item: $e');
      rethrow;
    }
  }

  /// Fetch all items from S3
  Future<List<S3Item>> fetchFromS3() async {
    // Implement your logic to fetch all items from S3
    // This might involve listing objects from an S3 bucket
    // For now, returning an empty list as a placeholder
    return [];
  }

  /// Soft delete an item by setting isDeleted to true
  Future<void> softDeleteItem(String itemId) async {
    // Fetch the item
    S3Item item = await getItemById(itemId);
    // Update isDeleted flag
    item.isDeleted = true;
    // Save the updated item
    await updateItem(item);
  }

  /// Fetch items excluding those that are soft-deleted
  Future<List<S3Item>> fetchItems() async {
    List<S3Item> allItems = await fetchFromS3();
    // Filter out deleted items
    return allItems.where((item) => !item.isDeleted).toList();
  }
}
