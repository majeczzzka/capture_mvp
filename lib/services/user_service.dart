import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A service class for user-related operations.
class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the current user's ID and username.
  Future<UserInfo?> getCurrentUser() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final doc = await _firestore.collection('users').doc(uid).get();
        final username = doc.data()?['username'];
        return UserInfo(uid: uid, username: username);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }
}

class UserInfo {
  final String uid;
  final String? username;

  UserInfo({required this.uid, this.username});
}
