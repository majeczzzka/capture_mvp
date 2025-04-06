import 'package:firebase_auth/firebase_auth.dart';
import '../data_sources/firebase_data_source.dart';

/// Repository class responsible for handling authentication operations
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseDataSource _firebaseDataSource;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseDataSource? firebaseDataSource,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firebaseDataSource = firebaseDataSource ?? FirebaseDataSource();

  /// Get the current authenticated user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Get a stream of authentication state changes
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('❌ Error signing in: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  /// Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('❌ Error signing up: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  /// Save username for a user
  Future<bool> saveUsername(String userId, String username) async {
    try {
      final path = 'users/$userId';
      return await _firebaseDataSource.setDocument(
        path,
        {'username': username},
        merge: true,
      );
    } catch (e) {
      print('❌ Error saving username: $e');
      return false;
    }
  }
}
