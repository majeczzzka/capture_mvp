import '../data_sources/firebase_data_source.dart';

/// Repository class responsible for handling user data operations
class UserRepository {
  final FirebaseDataSource _firebaseDataSource;

  UserRepository({
    FirebaseDataSource? firebaseDataSource,
  }) : _firebaseDataSource = firebaseDataSource ?? FirebaseDataSource();

  /// Get the current user data by user ID
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final path = 'users/$userId';
      final userDocument = await _firebaseDataSource.getDocument(path);

      if (userDocument != null && userDocument.exists) {
        return userDocument.data() as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  /// Update user data
  Future<bool> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      final path = 'users/$userId';
      return await _firebaseDataSource.updateDocument(path, data);
    } catch (e) {
      print('❌ Error updating user data: $e');
      return false;
    }
  }

  /// Get a stream of user data
  Stream<Map<String, dynamic>?> getUserDataStream(String userId) {
    final path = 'users/$userId';
    return _firebaseDataSource.getDocumentStream(path).map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>?;
      }
      return null;
    });
  }

  /// Get user ID by username
  Future<String?> getUserIdByUsername(String username) async {
    try {
      final path = 'users';
      final querySnapshot = await _firebaseDataSource.getCollection(
        path,
        orderBy: 'username',
      );

      if (querySnapshot == null) {
        return null;
      }

      for (final doc in querySnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        if (userData['username'] == username) {
          return doc.id;
        }
      }

      print("⚠️ No user found for username: $username");
      return null;
    } catch (e) {
      print("❌ Error finding user by username: $e");
      return null;
    }
  }
}
