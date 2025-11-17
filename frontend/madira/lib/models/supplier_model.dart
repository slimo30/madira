import 'package:intl/intl.dart';

class SupplierModel {
  final int id;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final bool isActive;
  final DateTime createdAt;

  SupplierModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.notes,
    required this.isActive,
    required this.createdAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Formatted date
  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  // Display type (for UI)
  String get status => isActive ? 'Active' : 'Inactive';
}
