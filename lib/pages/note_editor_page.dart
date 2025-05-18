import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/note.dart';
import '../auth.dart';

/// A page for creating and editing notes.
/// 
/// This page provides functionality to:
/// - Create new notes
/// - Edit existing notes
/// - View notes in read-only mode
/// - Delete notes
/// - Save notes with location data
class NoteEditorPage extends StatefulWidget {
  /// The note to edit, or null if creating a new note
  final Note? note;
  
  /// Whether the note should be displayed in view-only mode
  final bool isViewOnly;

  const NoteEditorPage({
    super.key, 
    this.note,
    this.isViewOnly = false,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  // Controllers for text input
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = false;
  bool _isEditing = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _initializeNote();
  }

  /// Initialize the note data if editing an existing note
  void _initializeNote() {
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _latitude = widget.note!.latitude;
      _longitude = widget.note!.longitude;
    }
    _isEditing = !widget.isViewOnly;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Get the current location of the device
  Future<void> _getCurrentLocation() async {
    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.'
        );
      }

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      _latitude = position.latitude;
      _longitude = position.longitude;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
            ),
          ),
        );
      }
    }
  }

  /// Save the note to Firestore
  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Auth().currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get current location when saving
      await _getCurrentLocation();

      final note = Note(
        id: widget.note?.id ?? '',
        title: _titleController.text,
        content: _contentController.text,
        userId: user.uid,
        createdAt: widget.note?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (widget.note == null) {
        // Create new note
        await FirebaseFirestore.instance.collection('notes').add(note.toMap());
      } else {
        // Update existing note
        await FirebaseFirestore.instance
            .collection('notes')
            .doc(widget.note!.id)
            .update(note.toMap());
      }

      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving note: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Delete the current note
  Future<void> _deleteNote() async {
    if (widget.note == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(widget.note!.id)
          .delete();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting note: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Build the app bar with appropriate actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.note == null ? 'New Note' : 'Note'),
      actions: [
        if (widget.note != null)
          IconButton(
            onPressed: _isLoading ? null : _deleteNote,
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Note',
          ),
        if (_isEditing)
          IconButton(
            onPressed: _isLoading ? null : _saveNote,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: 'Save Note',
          )
        else
          IconButton(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Note',
          ),
      ],
    );
  }

  /// Build the title field
  Widget _buildTitleField() {
    if (_isEditing) {
      return TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a title';
          }
          return null;
        },
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      );
    }
  }

  /// Build the content field
  Widget _buildContentField() {
    if (_isEditing) {
      return TextFormField(
        controller: _contentController,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          hintText: 'Start writing...',
          hintStyle: TextStyle(height: 1),
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
        maxLines: 20,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter some content';
          }
          return null;
        },
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          _contentController.text,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildContentField(),
          ],
        ),
      ),
    );
  }
} 