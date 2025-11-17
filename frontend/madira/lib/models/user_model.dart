import 'package:intl/intl.dart';

class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final username = json['username'] ?? 'Unknown';

    // Handle id - it must exist and be valid
    final id = json['id'];
    if (id == null) {
      throw Exception('Server Error: Missing user ID in response');
    }

    int userId = 0;
    if (id is int) {
      userId = id;
    } else if (id is String) {
      userId = int.tryParse(id) ?? 0;
    }

    if (userId == 0) {
      throw Exception('Server Error: Invalid user ID received: $id');
    }

    return UserModel(
      id: userId,
      username: username,
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'simple_user',
      isActive: json['is_active'] ?? true,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedCreatedAt {
    return DateFormat('MMM dd, yyyy - HH:mm').format(createdAt);
  }
}
