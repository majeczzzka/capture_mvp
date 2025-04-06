import 'package:cloud_firestore/cloud_firestore.dart';

/// Data source class responsible for low-level Firestore operations
class FirebaseDataSource {
  final FirebaseFirestore _firestore;

  FirebaseDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Checks if a collection exists
  Future<bool> collectionExists(String path) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection(path).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking collection existence: $e');
      return false;
    }
  }

  /// Checks if a document exists
  Future<bool> documentExists(String path) async {
    try {
      final DocumentSnapshot snapshot = await _firestore.doc(path).get();
      return snapshot.exists;
    } catch (e) {
      print('❌ Error checking document existence: $e');
      return false;
    }
  }

  /// Get a document by path
  Future<DocumentSnapshot?> getDocument(String path) async {
    try {
      final DocumentSnapshot snapshot = await _firestore.doc(path).get();
      return snapshot;
    } catch (e) {
      print('❌ Error getting document: $e');
      return null;
    }
  }

  /// Get a collection by path with optional ordering
  Future<QuerySnapshot?> getCollection(
    String path, {
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(path);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      print('❌ Error getting collection: $e');
      return null;
    }
  }

  /// Create a document in a collection with auto-generated ID
  Future<DocumentReference?> createDocument(
      String collectionPath, Map<String, dynamic> data) async {
    try {
      return await _firestore.collection(collectionPath).add(data);
    } catch (e) {
      print('❌ Error creating document: $e');
      return null;
    }
  }

  /// Set a document at a specific path
  Future<bool> setDocument(String path, Map<String, dynamic> data,
      {bool merge = false}) async {
    try {
      await _firestore.doc(path).set(data, SetOptions(merge: merge));
      return true;
    } catch (e) {
      print('❌ Error setting document: $e');
      return false;
    }
  }

  /// Update a document at a specific path
  Future<bool> updateDocument(String path, Map<String, dynamic> data) async {
    try {
      await _firestore.doc(path).update(data);
      return true;
    } catch (e) {
      print('❌ Error updating document: $e');
      return false;
    }
  }

  /// Delete a document at a specific path
  Future<bool> deleteDocument(String path) async {
    try {
      await _firestore.doc(path).delete();
      return true;
    } catch (e) {
      print('❌ Error deleting document: $e');
      return false;
    }
  }

  /// Get a stream of documents from a collection
  Stream<QuerySnapshot> getCollectionStream(
    String path, {
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(path);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  /// Get a stream of a specific document
  Stream<DocumentSnapshot> getDocumentStream(String path) {
    return _firestore.doc(path).snapshots();
  }
}
