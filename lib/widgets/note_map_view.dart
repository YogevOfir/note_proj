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

  /// Create markers for each note with location data
  void _createMarkers() {
    _markers = widget.notes
        .where((note) => note.latitude != null && note.longitude != null)
        .map((note) {
      return Marker(
        markerId: MarkerId(note.id),
        position: LatLng(note.latitude!, note.longitude!),
        infoWindow: InfoWindow(
          title: note.title.isEmpty ? 'Untitled' : note.title,
          snippet: 'Tap to view details',
        ),
        onTap: () => widget.onNoteTap(note),
      );
    }).toSet();
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