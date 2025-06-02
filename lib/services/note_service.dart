import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';

/// Service class for handling note operations
class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user
  User? get currentUser => _auth.currentUser;

  /// Get stream of notes for current user
  Stream<List<Note>> getNotesStream() {
    final user = currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final notes = snapshot.docs.map((doc) {
        return Note.fromMap(doc.id, doc.data());
      }).toList();
      
      // Sort notes by createdAt in memory
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    });
  }

  /// Create a new note
  Future<void> createNote(Note note) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await _firestore.collection('notes').add({
      'title': note.title,
      'content': note.content,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'latitude': note.latitude,
      'longitude': note.longitude,
    });
  }

  /// Update an existing note
  Future<void> updateNote(String noteId, Note note) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await _firestore.collection('notes').doc(noteId).update({
      'title': note.title,
      'content': note.content,
      'updatedAt': FieldValue.serverTimestamp(),
      'latitude': note.latitude,
      'longitude': note.longitude,
    });
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await _firestore.collection('notes').doc(noteId).delete();
  }
} 