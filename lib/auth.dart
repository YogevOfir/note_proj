import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password
    );
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // Create the user account
    final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password
    );

    // Store additional user data in Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'fullName': fullName,
      'email': email,
      'createdAt': Timestamp.now(),
    });
  }

  Future<String?> getUserFullName() async {
    if (currentUser == null) return null;
    
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data()?['fullName'] as String?;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}