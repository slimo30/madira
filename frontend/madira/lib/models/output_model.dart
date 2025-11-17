// ✅ Output Model
import 'package:intl/intl.dart';

class OutputModel {
  final int id;
  final String type;
  final String typeDisplay;
  final String amount;
  final String? product;
  final String? productName;
  final String? quantity;
  final String? price;
  final int? sourceInput;
  final String? sourceInputReference;
  final int? supplier;
  final String? supplierName;
  final int? order;
  final String? orderNumber;
  final String? clientName;
  final String description;
  final String reference;
  final String date;
  final String createdAt;
  final String? createdByUsername;
  final List<dynamic>? relatedStockMovements;
  final List<dynamic>? relatedOrderOutputs;

  OutputModel({
    required this.id,
    required this.type,
    required this.typeDisplay,
    required this.amount,
    this.product,
    this.productName,
    this.quantity,
    this.price,
    this.sourceInput,
    this.sourceInputReference,
    this.supplier,
    this.supplierName,
    this.order,
    this.orderNumber,
    this.clientName,
    required this.description,
    required this.reference,
    required this.date,
    required this.createdAt,
    this.createdByUsername,
    this.relatedStockMovements,
    this.relatedOrderOutputs,
  });

  factory OutputModel.fromJson(Map<String, dynamic> json) {
    return OutputModel(
      id: json['id'] as int,
      type: json['type'] as String,
      typeDisplay: json['type_display'] as String? ?? '',
      amount: json['amount'].toString(),
      product: json['product']?.toString(),
      productName: json['product_name'] as String?,
      quantity: json['quantity']?.toString(),
      price: json['price']?.toString(),
      sourceInput: json['source_input'] as int?,
      sourceInputReference: json['source_input_reference'] as String?,
      supplier: json['supplier'] as int?,
      supplierName: json['supplier_name'] as String?,
      order: json['order'] as int?,
      orderNumber: json['order_number'] as String?,
      clientName: json['client_name'] as String?,
      description: json['description'] as String? ?? '',
      reference: json['reference'] as String,
      date: json['date'] as String,
      createdAt: json['created_at'] as String,
      createdByUsername: json['created_by_username'] as String?,
      relatedStockMovements: json['related_stock_movements'] as List?,
      relatedOrderOutputs: json['related_order_outputs'] as List?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'type_display': typeDisplay,
      'amount': amount,
      if (product != null) 'product': product,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (price != null) 'price': price,
      if (sourceInput != null) 'source_input': sourceInput,
      if (sourceInputReference != null)
        'source_input_reference': sourceInputReference,
      if (supplier != null) 'supplier': supplier,
      if (supplierName != null) 'supplier_name': supplierName,
      if (order != null) 'order': order,
      if (orderNumber != null) 'order_number': orderNumber,
      if (clientName != null) 'client_name': clientName,
      'description': description,
      'reference': reference,
      'date': date,
      'created_at': createdAt,
      if (createdByUsername != null) 'created_by_username': createdByUsername,
      if (relatedStockMovements != null)
        'related_stock_movements': relatedStockMovements,
      if (relatedOrderOutputs != null)
        'related_order_outputs': relatedOrderOutputs,
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

  String get formattedCreatedAt {
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('MMM dd, yyyy HH:mm').format(dt);
    } catch (e) {
      return createdAt;
    }
  }

  String get formattedAmount {
    final amt = double.tryParse(amount) ?? 0;
    return amt.toStringAsFixed(2);
  }

  String get formattedQuantity {
    if (quantity == null) return '0.00';
    final qty = double.tryParse(quantity!) ?? 0;
    return qty.toStringAsFixed(2);
  }

  String get formattedPrice {
    if (price == null) return '0.00';
    final pr = double.tryParse(price!) ?? 0;
    return pr.toStringAsFixed(2);
  }

  bool get isWithdrawal => type == 'withdrawal';
  bool get isSupplierPayment => type == 'supplier_payment';
  bool get isConsumable => type == 'consumable';
  bool get isGlobalStockPurchase => type == 'global_stock_purchase';
  bool get isClientStockUsage => type == 'client_stock_usage';
  bool get isOtherExpense => type == 'other_expense';
}

class OutputStatistics {
  final double totalAmount;
  final int totalCount;
  final Map<String, dynamic> byType;
  final List<dynamic> recentOutputs;

  OutputStatistics({
    required this.totalAmount,
    required this.totalCount,
    required this.byType,
    required this.recentOutputs,
  });

  factory OutputStatistics.fromJson(Map<String, dynamic> json) {
    return OutputStatistics(
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      totalCount: json['total_count'] as int? ?? 0,
      byType: json['by_type'] as Map<String, dynamic>? ?? {},
      recentOutputs: json['recent_outputs'] as List? ?? [],
    );
  }

  String get formattedTotalAmount => totalAmount.toStringAsFixed(2);
}
