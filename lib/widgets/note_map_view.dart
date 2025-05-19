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
  Set<Marker> _markers = {};
  
  // Map to store notes by location
  final Map<String, List<Note>> _notesByLocation = {};
  
  // Currently selected location
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  @override
  void didUpdateWidget(NoteMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes) {
      _createMarkers();
    }
  }

  /// Create a location key from coordinates
  String _getLocationKey(double lat, double lng) {
    // Round to 6 decimal places (roughly 11cm precision)
    return '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
  }

  /// Group notes by location
  void _groupNotesByLocation() {
    _notesByLocation.clear();
    
    for (final note in widget.notes) {
      if (note.latitude != null && note.longitude != null) {
        final locationKey = _getLocationKey(note.latitude!, note.longitude!);
        _notesByLocation.putIfAbsent(locationKey, () => []).add(note);
      }
    }
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
        _markers.add(Marker(
          markerId: MarkerId(firstNote.id),
          position: position,
          infoWindow: InfoWindow(
            title: firstNote.title.isEmpty ? 'Untitled' : firstNote.title,
            snippet: 'Tap to view details',
          ),
          onTap: () => widget.onNoteTap(firstNote),
        ));
      } else {
        // Multiple notes at this location - create cluster marker
        _markers.add(Marker(
          markerId: MarkerId(locationKey),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: '${notes.length} Notes',
            snippet: 'Tap to view all notes at this location',
          ),
          onTap: () {
            setState(() {
              _selectedLocation = locationKey;
            });
            _showNotesAtLocation(notes);
          },
        ));
      }
    });
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
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title.isEmpty ? 'Untitled' : note.title),
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
            },
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

  /// Fit the map to show all markers
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

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_markers.isEmpty) {
      return const Center(
        child: Text('No notes with location data'),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.brown,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _markers.first.position,
            zoom: 12,
          ),
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;
            _fitMapToMarkers();
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
        ),
      ),
    );
  }
} 