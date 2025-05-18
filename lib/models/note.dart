import 'package:cloud_firestore/cloud_firestore.dart';

/// A class representing a note in the application.
/// 
/// Each note contains:
/// - Basic information (id, title, content)
/// - User association (userId)
/// - Timestamps (createdAt, updatedAt)
/// - Location data (latitude, longitude)
class Note {
  /// Unique identifier for the note
  final String id;
  
  /// Title of the note
  final String title;
  
  /// Content/body of the note
  final String content;
  
  /// ID of the user who owns this note
  final String userId;
  
  /// When the note was created
  final DateTime createdAt;
  
  /// When the note was last updated
  final DateTime updatedAt;
  
  /// Optional latitude coordinate of where the note was created
  final double? latitude;
  
  /// Optional longitude coordinate of where the note was created
  final double? longitude;

  /// Creates a new Note instance.
  /// 
  /// All fields except [latitude] and [longitude] are required.
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
  });

  /// Converts the Note to a Map for Firestore storage.
  /// 
  /// This method is used when saving the note to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Creates a Note instance from Firestore data.
  /// 
  /// [id] is the document ID from Firestore.
  /// [map] is the document data from Firestore.
  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }

  /// Creates a copy of this Note with the given fields replaced with new values.
  /// 
  /// This is useful when updating a note, as it allows you to create a new
  /// instance with only the fields you want to change.
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
} 