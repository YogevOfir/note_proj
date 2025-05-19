import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Controller for handling authentication operations.
/// 
/// This controller manages all authentication-related business logic,
/// including sign in, registration, and user data management.
class AuthController {
  final AuthService _authService = AuthService();

  /// Get the current user
  User? get currentUser => _authService.currentUser;

  /// Get stream of auth state changes
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Sign in with email and password
  /// 
  /// Returns null if successful, or an error message if failed.
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'invalid-email':
          return 'The email address is invalid.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
  }

  /// Create a new user with email and password
  /// 
  /// Returns null if successful, or an error message if failed.
  Future<String?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Create the user
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store additional user data
      await _authService.storeUserData(
        userId: userCredential.user!.uid,
        fullName: fullName,
        email: email,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'The password is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'invalid-email':
          return 'The email address is invalid.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
  }

  /// Sign out the current user
  /// 
  /// Returns null if successful, or an error message if failed.
  Future<String?> signOut() async {
    try {
      await _authService.signOut();
      return null;
    } catch (e) {
      return 'Failed to sign out: ${e.toString()}';
    }
  }

  /// Get the user's full name from Firestore
  Future<String?> getUserFullName() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final userData = await _authService.getUserData(user.uid);
      return userData?['fullName'] as String?;
    } catch (e) {
      return null;
    }
  }
} 