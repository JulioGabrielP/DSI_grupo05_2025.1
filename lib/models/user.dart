import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl; // Now stores base64 data URLs or external URLs
  final int studyTimeMinutes;
  final int completedActivities;
  final int completionRate;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.studyTimeMinutes,
    required this.completedActivities,
    required this.completionRate,
    required this.createdAt,
    required this.lastLoginAt,
  });

  // Check if profile image is a base64 data URL
  bool get hasBase64Image {
    return profileImageUrl != null &&
        profileImageUrl!.startsWith('data:image/');
  }

  // Check if profile image is an external URL
  bool get hasExternalImage {
    return profileImageUrl != null &&
        (profileImageUrl!.startsWith('http://') ||
            profileImageUrl!.startsWith('https://'));
  }

  // Get base64 image bytes for display
  Uint8List? get imageBytes {
    if (!hasBase64Image) return null;

    try {
      // Extract base64 part from data URL
      final base64String = profileImageUrl!.split(',')[1];
      return base64Decode(base64String);
    } catch (e) {
      print('Erro ao decodificar imagem base64: $e');
      return null;
    }
  }

  // Format study time as "70h23min"
  String getFormattedStudyTime() {
    int hours = studyTimeMinutes ~/ 60;
    int minutes = studyTimeMinutes % 60;
    return '${hours}h${minutes.toString().padLeft(2, '0')}min';
  }

  // Convert from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      studyTimeMinutes: json['studyTimeInMinutes'] ?? 0,
      completedActivities: json['completedActivities'] ?? 0,
      completionRate: json['completionRate'] ?? 0,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: DateTime.parse(
          json['lastLoginAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert from Map (para dados do Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      studyTimeMinutes: map['studyTimeInMinutes'] ?? 0,
      completedActivities: map['completedActivities'] ?? 0,
      completionRate: map['completionRate'] ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
      lastLoginAt: _parseDateTime(map['lastLoginAt']),
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }

    if (dateValue is DateTime) {
      return dateValue;
    }

    if (dateValue is Timestamp) {
      return dateValue.toDate();
    }

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    if (dateValue is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'studyTimeInMinutes': studyTimeMinutes,
      'completedActivities': completedActivities,
      'completionRate': completionRate,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  // Convert to Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'studyTimeInMinutes': studyTimeMinutes,
      'completedActivities': completedActivities,
      'completionRate': completionRate,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  // Copy with method for updating user data
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    int? studyTimeInMinutes,
    int? completedActivities,
    int? totalActivities,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      studyTimeMinutes: studyTimeInMinutes ?? this.studyTimeMinutes,
      completedActivities: completedActivities ?? this.completedActivities,
      completionRate: totalActivities ?? this.completionRate,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, studyTime: ${getFormattedStudyTime()}, completionRate: $completionRate%)';
  }
}
