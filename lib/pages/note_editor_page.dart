import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/note.dart';
import '../controllers/note_controller.dart';

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
  NoteEditorPageState createState() => NoteEditorPageState();
}

class NoteEditorPageState extends State<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _noteController = NoteController();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    // if we view/edit and not create a note
    if (widget.note != null) {
      // show the details
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
    _isEditing = widget.note == null; // Start in edit mode for new notes
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.note == null ? 'New Note' : 'Note'),
      actions: [
        if (widget.note != null)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteNote,
          ),
        if (_isEditing)
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveNote,
          )
        else
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => setState(() => _isEditing = true),
          ),
      ],
    );
  }


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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final error = await _noteController.deleteNote(widget.note!);
      if (error != null) {
        setState(() {
          _errorMessage = error;
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete note: ${e.toString()}';
        _isLoading = false;
      });
    }
  }


  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Title and content are required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location
      await _getCurrentLocation();

      // Creating new note
      if (widget.note == null) {
        final errors = await _noteController.createNote(
          title: _titleController.text,
          content: _contentController.text,
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
        );

        if (errors != null) {
          setState(() {
            _errorMessage = errors.join('\n');
            _isLoading = false;
          });
          return;
        }
      // Editing existing note
      } else {
        final errors = await _noteController.updateNote(
          widget.note!,
          title: _titleController.text,
          content: _contentController.text,
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
        );

        if (errors != null) {
          setState(() {
            _errorMessage = errors.join('\n');
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save note: ${e.toString()}';
        _isLoading = false;
      });
    }
  }


  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      _currentPosition = position;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildTitleField() {
    if (_isEditing) {
      return TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  Widget _buildContentField() {
    if (_isEditing) {
      return TextField(
        controller: _contentController,
        decoration: const InputDecoration(
          hintText: 'Start writing...',
          border: OutlineInputBorder(),
        ),
        maxLines: 20,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        _contentController.text,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) _buildErrorMessage(),
                  _buildTitleField(),
                  const SizedBox(height: 16.0),
                  _buildContentField(),
                ],
              ),
            ),
    );
  }

} 