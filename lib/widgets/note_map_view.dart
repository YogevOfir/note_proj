import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/note.dart';

/// A widget that displays notes on a Google Map.
/// 
/// This widget provides functionality to:
/// - Display notes as markers on the map
/// - Show note titles in marker info windows
/// - Handle marker taps to view note details
/// - Automatically fit the map to show all markers
/// - Cluster overlapping markers
class NoteMapView extends StatefulWidget {
  /// The list of notes to display on the map
  final List<Note> notes;
  
  /// Callback function when a note marker is tapped
  final Function(Note) onNoteTap;

  const NoteMapView({
    super.key,
    required this.notes,
    required this.onNoteTap,
  });

  @override
  State<NoteMapView> createState() => _NoteMapViewState();
}

class _NoteMapViewState extends State<NoteMapView> {
  // Map controller for programmatic control
  GoogleMapController? _mapController;
  
  // Set of markers to display on the map
  final Set<Marker> _markers = {};
  
  // Map to store notes by location
  final Map<String, List<Note>> _notesByLocation = {};
  
  LatLngBounds? _currentBounds;

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  /// Create markers for each note with location data
  void _createMarkers() {
    _groupNotesByLocation();
    _markers.clear();

    _notesByLocation.forEach((locationKey, notes) {
      if (notes.isEmpty) return;

      final firstNote = notes.first;
      final position = LatLng(firstNote.latitude!, firstNote.longitude!);
    
      if (notes.length < 2) {
        // Single note at this location
        _markers.add(_createSingleNoteMarker(firstNote));
      } else {
        // Multiple notes at this location - create cluster marker
        _markers.add(_createClusterMarker(locationKey, notes, position));
      }
    });

    setState(() {}); // Refresh UI after updating markers
  }


  /// Group notes by location (1.1m)
  void _groupNotesByLocation() {
    _notesByLocation.clear();
    
    for (final note in widget.notes) {
      if (note.latitude != null && note.longitude != null) {
        final position = LatLng(note.latitude!, note.longitude!);
        final locationKey = _getLocationKey(position);
        _notesByLocation.putIfAbsent(locationKey, () => []).add(note);
      }
    }
  }


  /// Create a location key from coordinates
  String _getLocationKey(LatLng position) {
    if (_currentBounds == null) {
      // If no bounds yet, use high precision
      return '${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}';
    }

    // Calculate relative position within bounds
    final latRange = _currentBounds!.northeast.latitude - _currentBounds!.southwest.latitude;
    final lngRange = _currentBounds!.northeast.longitude - _currentBounds!.southwest.longitude;
    
    // Use 10x10 grid within current bounds
    final latGrid = ((position.latitude - _currentBounds!.southwest.latitude) / latRange * 10).floor();
    final lngGrid = ((position.longitude - _currentBounds!.southwest.longitude) / lngRange * 10).floor();
    
    return '$latGrid,$lngGrid';
  }


  Marker _createSingleNoteMarker(Note note) {
    return Marker(
      markerId: MarkerId(note.id),
      position: LatLng(note.latitude!, note.longitude!),
      infoWindow: InfoWindow(
        title: note.title.isEmpty ? 'Untitled' : note.title,
        snippet: 'Tap to view details',
      ),
      onTap: () => widget.onNoteTap(note),
    );
  }

  Marker _createClusterMarker(String locationKey, List<Note> notes, LatLng position) {
    return Marker(
      markerId: MarkerId(locationKey),
      position: position,
      // violet color to group of markers
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: InfoWindow(
        title: '${notes.length} Notes',
        snippet: 'Tap to view all notes at this location',
      ),
      onTap: () {
        _showNotesAtLocation(notes);
      },
    );
  }

  /// Show a dialog with all notes at a specific location
  void _showNotesAtLocation(List<Note> notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${notes.length} Notes at this Location'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: notes.length,
            itemBuilder: (context, index) => _buildNoteListTile(notes[index]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // build a line of a note in the group of markers dialog
  Widget _buildNoteListTile(Note note) {
    return ListTile(
      title: Text(note.title.isEmpty ? 'Untitled' : note.title),
      // max 50 chars of the content
      subtitle: Text(
        note.content.length > 50 
          ? '${note.content.substring(0, 50)}...' 
          : note.content,
      ),
      onTap: () {
        Navigator.pop(context);
        widget.onNoteTap(note);
      },
    );
  }


  // creates the map border
  Widget _buildMapContainer() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.brown,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildMap(),
    );
  }


  // creates the map using googlemaps
  Widget _buildMap() {
    // a container of circular border (ensure the map have rounded corners)
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _markers.first.position,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
          _fitMapToMarkers();
        },
        onCameraMove: (position) async {
          if (_mapController != null) {
            _currentBounds = await _mapController!.getVisibleRegion();
            _createMarkers();
          }
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapToolbarEnabled: true,
      ),
    );
  }


  /// Fit the map to show all markers by set the bounds to
  /// the most southwest and northeast markers
  void _fitMapToMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    final bounds = _markers.fold<LatLngBounds>(
      LatLngBounds(
        southwest: _markers.first.position,
        northeast: _markers.first.position,
      ),
      (bounds, marker) => LatLngBounds(
        southwest: LatLng(
          min(bounds.southwest.latitude, marker.position.latitude),
          min(bounds.southwest.longitude, marker.position.longitude),
        ),
        northeast: LatLng(
          max(bounds.northeast.latitude, marker.position.latitude),
          max(bounds.northeast.longitude, marker.position.longitude),
        ),
      ),
    );

    // update camera view to the borders + 50pixels
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }


  // ensure update when new notes added/removed
  @override
  void didUpdateWidget(NoteMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes) {
      _createMarkers();
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_markers.isEmpty) {
      return const Center(
        child: Text('No notes with location data'),
      );
    }

    return _buildMapContainer();
  }
} 