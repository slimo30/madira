//  Product Model
import 'package:intl/intl.dart';

class ProductModel {
  final int id;
  final String name;
  final String unit;
  final String currentQuantity;
  final String description;
  final String reference;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentQuantity,
    required this.description,
    required this.reference,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      unit: json['unit'] as String,
      currentQuantity: json['current_quantity'].toString(),
      description: json['description'] as String? ?? '',
      reference: json['reference'] as String,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'current_quantity': currentQuantity,
      'description': description,
      'reference': reference,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get formattedCreatedAt {
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (e) {
      return createdAt;
    }
  }

  String get formattedUpdatedAt {
    try {
      final dt = DateTime.parse(updatedAt);
      return DateFormat('MMM dd, yyyy HH:mm').format(dt);
    } catch (e) {
      return updatedAt;
    }
  }

  String get formattedQuantity {
    final quantity = double.tryParse(currentQuantity) ?? 0;
    return '${quantity.toStringAsFixed(2)} $unit';
  }
}
