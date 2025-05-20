import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';
import '../services/note_service.dart';

/// Controller for managing notes in the application.
/// 
/// This controller handles all business logic related to notes,
/// including validation, state management, and coordination
/// between the view and service layers.
class NoteController {
  final NoteService _noteService = NoteService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  /// Get the current user's ID
  String? get currentUserId => _currentUser?.uid;

  /// Get stream of notes for current user
  Stream<List<Note>> getNotesStream() {
    return _noteService.getNotesStream();
  }

  /// Create a new note
  /// 
  /// Returns a list of validation errors if the note is invalid,
  /// or null if the note was created successfully.
  Future<List<String>?> createNote({
    required String title,
    required String content,
    double? latitude,
    double? longitude,
  }) async {
    if (_currentUser == null) {
      return ['User not authenticated'];
    }

    final note = Note(
      id: '',  // Will be set by Firestore
      title: title,
      content: content,
      userId: _currentUser.uid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
    );

    final errors = _validateNote(note);
    if (errors.isNotEmpty) {
      return errors;
    }

    try {
      await _noteService.createNote(note);
      return null;
    } catch (e) {
      return ['Failed to create note: ${e.toString()}'];
    }
  }

  /// Update an existing note
  /// 
  /// Returns a list of validation errors if the note is invalid,
  /// or null if the note was updated successfully.
  Future<List<String>?> updateNote(
    Note existingNote, {
    String? title,
    String? content,
    double? latitude,
    double? longitude,
  }) async {
    if (_currentUser == null) {
      return ['User not authenticated'];
    }

    if (existingNote.userId != _currentUser.uid) {
      return ['Not authorized to update this note'];
    }

    final updatedNote = Note(
      id: existingNote.id,
      title: title ?? existingNote.title,
      content: content ?? existingNote.content,
      userId: existingNote.userId,
      createdAt: existingNote.createdAt,
      updatedAt: DateTime.now(),
      latitude: latitude ?? existingNote.latitude,
      longitude: longitude ?? existingNote.longitude,
    );

    final errors = _validateNote(updatedNote);
    if (errors.isNotEmpty) {
      return errors;
    }

    try {
      await _noteService.updateNote(existingNote.id, updatedNote);
      return null;
    } catch (e) {
      return ['Failed to update note: ${e.toString()}'];
    }
  }

  /// Delete a note
  /// 
  /// Returns null if the note was deleted successfully,
  /// or an error message if the deletion failed.
  Future<String?> deleteNote(Note note) async {
    if (_currentUser == null) {
      return 'User not authenticated';
    }

    if (note.userId != _currentUser.uid) {
      return 'Not authorized to delete this note';
    }

    try {
      await _noteService.deleteNote(note.id);
      return null;
    } catch (e) {
      return 'Failed to delete note: ${e.toString()}';
    }
  }

  /// Validate a note
  List<String> _validateNote(Note note) {
    final errors = <String>[];

    if (note.title.isEmpty) {
      errors.add('Title is required');
    }

    if (note.content.isEmpty) {
      errors.add('Content is required');
    }

    if (note.userId.isEmpty) {
      errors.add('User ID is required');
    }

    if (note.latitude != null && note.longitude == null) {
      errors.add('Both latitude and longitude must be provided');
    }

    if (note.latitude == null && note.longitude != null) {
      errors.add('Both latitude and longitude must be provided');
    }

    return errors;
  }
} 