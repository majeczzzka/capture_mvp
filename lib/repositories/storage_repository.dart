import '../models/s3_item.dart';
import '../models/jar_data.dart';
import '../data_sources/s3_data_source.dart';
import 'jar_repository.dart';
import 'archived_jar_repository.dart';

/// Repository that coordinates storage operations between different data sources
class StorageRepository {
  final String userId;
  final S3DataSource s3DataSource;
  final JarRepository jarRepository;
  final ArchivedJarRepository archivedJarRepository;

  StorageRepository({
    required this.userId,
  })  : s3DataSource = S3DataSource(),
        jarRepository = JarRepository(userId: userId),
        archivedJarRepository = ArchivedJarRepository(userId: userId);

  /// Get all deleted items from a jar
  Future<List<S3Item>> getDeletedJarContents(String jarId) async {
    final jar = await jarRepository.getJarById(jarId);
    if (jar == null) {
      return [];
    }

    return jar.content
        .where((item) => item.isDeletedByUser(userId))
        .map((item) => item.toS3Item())
        .toList();
  }

  /// Get content from archived jars
  Future<List<Map<String, dynamic>>> getArchivedContent() async {
    return await archivedJarRepository.getArchivedContent();
  }

  /// Restore an archived item from a jar
  Future<bool> restoreArchivedItem(String jarId, String itemUrl) async {
    return await jarRepository.restoreJarItem(jarId, itemUrl);
  }

  /// Permanently delete an item from a jar
  Future<bool> permanentlyDeleteItem(String jarId, String itemUrl) async {
    final jar = await jarRepository.getJarById(jarId);
    if (jar == null) {
      return false;
    }

    // Find the content item to remove
    final contentItem = jar.content.firstWhere(
      (item) => item.url == itemUrl,
      orElse: () => ContentItem(
        type: 'unknown',
        url: '',
        uploadedBy: '',
        uploadedAt: DateTime.now(),
      ),
    );

    if (contentItem.url.isEmpty) {
      return false;
    }

    // Filter out the content item
    final updatedContent =
        jar.content.where((item) => item.url != itemUrl).toList();

    // Update the jar with the filtered content
    final updatedJar = jar.copyWith(content: updatedContent);
    return await jarRepository.updateJar(jarId, updatedJar);
  }

  /// Delete an item from an archived jar
  Future<bool> deleteArchivedJarItem(String jarId, String itemUrl) async {
    return await archivedJarRepository.deleteArchivedJarItem(jarId, itemUrl);
  }

  /// Get all deleted items from all sources
  Future<List<Map<String, dynamic>>> getAllDeletedItems() async {
    // Use jarRepository.getAllDeletedItems() which already handles both active and archived jars
    return await jarRepository.getAllDeletedItems();

    // NOTE: We've removed the duplicate call to archivedJarRepository.getArchivedContent()
    // because jarRepository.getAllDeletedItems() already includes archived items
  }
}
