import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/s3_item.dart';
import '../data_sources/firebase_data_source.dart';
import '../repositories/jar_repository.dart';
import '../services/s3_service.dart';

/// Repository for handling calendar data operations
class CalendarRepository {
  final String userId;
  final FirebaseDataSource _firebaseDataSource;
  final JarRepository _jarRepository;

  CalendarRepository({
    required this.userId,
    FirebaseDataSource? firebaseDataSource,
    JarRepository? jarRepository,
  })  : _firebaseDataSource = firebaseDataSource ?? FirebaseDataSource(),
        _jarRepository = jarRepository ?? JarRepository(userId: userId);

  /// Fetch and group content by year-month
  Future<Map<String, List<Map<String, dynamic>>>> fetchAndGroupContent() async {
    final List<Map<String, dynamic>> contentData = [];

    // Get all jars for the user
    final jarsSnapshot =
        await _firebaseDataSource.getCollection('users/$userId/jars');

    if (jarsSnapshot == null) {
      return {};
    }

    for (final jar in jarsSnapshot.docs) {
      final data = jar.data() as Map<String, dynamic>;
      final jarId = jar.id;
      final jarName = data['name'] ?? 'Unknown Jar';
      final jarColor = data['color'] ?? '#000000';

      // Use S3Service directly to maintain exact functionality
      List<S3Item> s3Items =
          await S3Service(userId: userId).getJarContents(jarId);

      for (final s3Item in s3Items) {
        contentData.add({
          'type': s3Item.type,
          'data': s3Item.url,
          'date': s3Item.uploadedAt ?? DateTime.now(),
          'jarName': jarName,
          'jarColor': jarColor,
          'jarId': jarId,
        });
      }
    }

    // Sort and group by year-month
    contentData.sort((a, b) => b['date'].compareTo(a['date']));
    final Map<String, List<Map<String, dynamic>>> groupedContent = {};

    for (final content in contentData) {
      final date = content['date'] as DateTime;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      groupedContent.putIfAbsent(key, () => []).add(content);
    }

    return groupedContent;
  }

  /// Get collaborators for a jar
  Future<List<String>> getJarCollaborators(String jarId) async {
    final jarDoc =
        await _firebaseDataSource.getDocument('users/$userId/jars/$jarId');

    if (jarDoc == null || !jarDoc.exists) {
      return [];
    }

    final jarData = jarDoc.data() as Map<String, dynamic>?;
    return List<String>.from(jarData?['collaborators'] ?? []);
  }

  /// Delete item from jar
  Future<bool> deleteItemFromJar(
      String jarId, String contentUrl, List<String> collaborators) async {
    // Use S3Service directly to maintain exact functionality
    try {
      await S3Service(userId: userId)
          .deleteItemFromJar(jarId, contentUrl, collaborators);
      return true;
    } catch (e) {
      print('❌ Error deleting item from jar: $e');
      return false;
    }
  }
}
