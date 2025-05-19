import '../controllers/auth_controller.dart';
import '../controllers/note_controller.dart';
import '../models/note.dart';
import '../widgets/note_map_view.dart';
import 'note_editor_page.dart';
import 'package:flutter/material.dart';

/// The main page of the application that displays the list of notes.
/// 
/// This page provides functionality to:
/// - View all notes in a list or map view
/// - Create new notes
/// - Navigate to note details
/// - Sign out
/// - Toggle between list and map views
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = AuthController();
  final NoteController _noteController = NoteController();
  String? _userFullName;
  bool _isMapView = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserFullName();
  }

  /// Load the user's full name
  Future<void> _loadUserFullName() async {
    final name = await _authController.getUserFullName();
    if (mounted) {
      setState(() {
        _userFullName = name;
        _isLoading = false;
      });
    }
  }

  /// Handle sign out
  Future<void> _handleSignOut() async {
    final error = await _authController.signOut();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  /// Handle create new note
  void _handleCreateNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoteEditorPage(),
      ),
    );
  }

  /// Build the app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _buildAppTitle(),
      elevation: 0,
      actions: [_buildSignOutButton()],
    );
  }

  /// Build the app title widget
  Widget _buildAppTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.person_outline,
          color: Colors.white,
          size: 32,
        ),
        const SizedBox(width: 8),
        Text(
          'Welcome${_userFullName != null ? ', $_userFullName' : ''}!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build the sign out button
  Widget _buildSignOutButton() {
    return IconButton(
      onPressed: _handleSignOut,
      icon: const Icon(Icons.logout),
      tooltip: 'Sign Out',
    );
  }

  /// Build the view toggle button (List/Map)
  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(
            value: false,
            icon: Icon(Icons.list),
            label: Text('List'),
          ),
          ButtonSegment<bool>(
            value: true,
            icon: Icon(Icons.map),
            label: Text('Map'),
          ),
        ],
        selected: {_isMapView},
        onSelectionChanged: (Set<bool> newSelection) {
          setState(() {
            // Usually for multiple choices, works for 2 the same.
            _isMapView = newSelection.first;
          });
        },
      ),
    );
  }

  /// Build the list of notes
  Widget _buildNoteList() {
    return Expanded(
      child: StreamBuilder<List<Note>>(
        stream: _noteController.getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading notes: ${snapshot.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
      
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
      
          final notes = snapshot.data ?? [];
          // If no notes:
          if (notes.isEmpty) {
            return _buildEmptyState();
          }

          // If On map view
          if (_isMapView) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: NoteMapView(
                notes: notes,
                onNoteTap: _handleNoteTap,
              ),
            );
          }

          // If on ListView
          return _buildListView(notes);
        },
      ),
    );
  }

  /// Build the empty state widget when no notes exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first note',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  ListView _buildListView(List<Note> notes) {
    return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(
                  note.title.isEmpty ? 'Untitled' : note.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () => _handleNoteTap(note),
              ),
            );
          },
    );
  }


  /// Handle note tap
  void _handleNoteTap(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(note: note),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 30),
          _buildViewToggle(),
          const SizedBox(height: 16),
          _buildNoteList(),
          const SizedBox(height: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}