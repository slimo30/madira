//  Input Model
import 'package:intl/intl.dart';

class InputModel {
  final int id;
  final String reference;
  final String type;
  final String amount;
  final String description;
  final int? order; // Nullable for shop deposits
  final String? orderNumber; // Nullable for shop deposits
  final String? clientName; // Nullable for shop deposits
  final int createdBy;
  final String createdByName;
  final double remainingAmount;
  final String date;
  final String createdAt;
  final String updatedAt;

  InputModel({
    required this.id,
    required this.reference,
    required this.type,
    required this.amount,
    required this.description,
    this.order, // Nullable
    this.orderNumber, // Nullable
    this.clientName, // Nullable
    required this.createdBy,
    required this.createdByName,
    required this.remainingAmount,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InputModel.fromJson(Map<String, dynamic> json) {
    return InputModel(
      id: json['id'] as int,
      reference: json['reference'] as String,
      type: json['type'] as String,
      amount: json['amount'] as String,
      description: json['description'] as String,
      order: json['order'] as int?,
      orderNumber: json['order_number'] as String?,
      clientName: json['client_name'] as String?,
      createdBy: json['created_by'] as int,
      createdByName: json['created_by_name'] as String,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'type': type,
      'amount': amount,
      'description': description,
      'order': order,
      'order_number': orderNumber,
      'client_name': clientName,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'remaining_amount': remainingAmount,
      'date': date,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (e) {
      return date;
    }
  }

  String get formattedAmount {
    final amount = double.tryParse(this.amount) ?? 0;
    return '${amount.toStringAsFixed(2)} DA';
  }

  String get formattedRemainingAmount {
    return '${remainingAmount.toStringAsFixed(2)} DA';
  }

  // Helper to check if input has remaining amount
  bool get hasRemainingAmount {
    return remainingAmount > 0;
  }
}
