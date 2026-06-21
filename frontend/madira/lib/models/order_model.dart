import 'package:intl/intl.dart';

class OrderModel {
  final int id;
  final String orderNumber;
  final int client;
  final String clientName;
  final String totalAmount;
  final double paidAmount;
  final String remainingAmount;
  final String totalExpenses;
  final String totalBenefit;
  final bool isFullyPaid;
  final String status;
  final String description;
  final String deliveryDate;
  final DateTime orderDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.client,
    required this.clientName,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.totalExpenses,
    required this.totalBenefit,
    required this.isFullyPaid,
    required this.status,
    required this.description,
    required this.deliveryDate,
    required this.orderDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int? ?? 0,
      orderNumber: json['order_number'] as String? ?? '',
      client: json['client'] as int? ?? 0,
      clientName: json['client_name'] as String? ?? '',
      totalAmount: json['total_amount'] as String? ?? '0.00',
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: json['remaining_amount'] as String? ?? '0.00',
      totalExpenses: json['total_expenses'] as String? ?? '0.00',
      totalBenefit: json['total_benefit'] as String? ?? '0.00',
      isFullyPaid: json['is_fully_paid'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
      description: json['description'] as String? ?? '',
      deliveryDate: json['delivery_date'] as String? ?? '',
      orderDate: DateTime.parse(
        json['order_date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'client': client,
      'client_name': clientName,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'total_expenses': totalExpenses,
      'total_benefit': totalBenefit,
      'is_fully_paid': isFullyPaid,
      'status': status,
      'description': description,
      'delivery_date': deliveryDate,
      'order_date': orderDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Formatted dates
  String get formattedOrderDate {
    return DateFormat('dd/MM/yyyy').format(orderDate);
  }

  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  // Status display
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  // Payment status
  String get paymentStatus {
    if (isFullyPaid) return 'Fully Paid';
    if (paidAmount == 0) return 'Unpaid';
    return 'Partially Paid';
  }

  // Percentage paid
  String get percentagePaid {
    final total = double.tryParse(totalAmount) ?? 0;
    if (total == 0) return '0%';
    final percentage = (paidAmount / total * 100).toStringAsFixed(1);
    return '$percentage%';
  }
}
