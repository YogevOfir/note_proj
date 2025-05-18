import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth.dart';
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
  // User and state management
  final User? user = Auth().currentUser;
  String? fullName;
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    _loadUserFullName();
  }

  /// Load the user's full name from Auth service
  Future<void> _loadUserFullName() async {
    final name = await Auth().getUserFullName();
    setState(() {
      fullName = name;
    });
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await Auth().signOut();
  }

  /// Build the app title widget
  Widget _title() {
    return const Text(
      'Notes Tree',
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Build the welcome message with user's name
  Widget _welcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome${fullName != null ? ', $fullName' : ''}!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build the view toggle button (List/Map)
  Widget _viewToggle() {
    return SegmentedButton<bool>(
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
          _isMapView = newSelection.first;
        });
      },
    );
  }

  /// Build the sign out button
  Widget _signOutButton() {
    return IconButton(
      onPressed: signOut,
      icon: const Icon(Icons.logout),
      tooltip: 'Sign Out',
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

  /// Build the list of notes
  Widget _buildNoteList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notes')
          .where('userId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final notes = snapshot.data?.docs.map((doc) {
          return Note.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList() ?? [];

        // Sort notes by createdAt in memory
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (notes.isEmpty) {
          return _buildEmptyState();
        }

        if (_isMapView) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 100.0),
            child: NoteMapView(
              notes: notes,
              onNoteTap: (note) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteEditorPage(
                      note: note,
                      isViewOnly: true,
                    ),
                  ),
                );
              },
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditorPage(note: note, isViewOnly: true),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Build the floating action button to add new notes
  Widget _addNote() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NoteEditorPage(),
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: _title(),
        elevation: 0,
        actions: [
          _signOutButton(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _welcomeMessage(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _viewToggle(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildNoteList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _addNote(),
    );
  }
}