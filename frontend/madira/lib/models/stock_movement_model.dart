//  Stock Movement Model
import 'package:intl/intl.dart';

class StockMovementModel {
  final int id;
  final int product;
  final String productName;
  final int? order;
  final String? orderNumber;
  final String movementType; // 'in' or 'out'
  final String quantity;
  final String price;
  final String date;
  final String createdAt;

  StockMovementModel({
    required this.id,
    required this.product,
    required this.productName,
    this.order,
    this.orderNumber,
    required this.movementType,
    required this.quantity,
    required this.price,
    required this.date,
    required this.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'] as int,
      product: json['product'] as int,
      productName: json['product_name'] as String? ?? '',
      order: json['order'] as int?,
      orderNumber: json['order_number'] as String?,
      movementType: json['movement_type'] as String,
      quantity: json['quantity'].toString(),
      price: json['price'].toString(),
      date: json['date'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'product_name': productName,
      if (order != null) 'order': order,
      if (orderNumber != null) 'order_number': orderNumber,
      'movement_type': movementType,
      'quantity': quantity,
      'price': price,
      'date': date,
      'created_at': createdAt,
    };
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy HH:mm').format(dt);
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

  String get formattedQuantity {
    final qty = double.tryParse(quantity) ?? 0;
    return qty.toStringAsFixed(2);
  }

  String get formattedPrice {
    final pr = double.tryParse(price) ?? 0;
    return pr.toStringAsFixed(2);
  }

  bool get isInMovement => movementType == 'in';
  bool get isOutMovement => movementType == 'out';
}

class ProductStockSummary {
  final int id;
  final String name;
  final double currentQuantity;
  final String unit;
  final double calculatedFromMovements;
  final double totalIn;
  final double totalOut;

  ProductStockSummary({
    required this.id,
    required this.name,
    required this.currentQuantity,
    required this.unit,
    required this.calculatedFromMovements,
    required this.totalIn,
    required this.totalOut,
  });

  factory ProductStockSummary.fromJson(Map<String, dynamic> json) {
    return ProductStockSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      currentQuantity: (json['current_quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      calculatedFromMovements:
          (json['calculated_from_movements'] as num).toDouble(),
      totalIn: (json['total_in'] as num).toDouble(),
      totalOut: (json['total_out'] as num).toDouble(),
    );
  }

  String get formattedCurrentQuantity =>
      '${currentQuantity.toStringAsFixed(2)} $unit';
  String get formattedTotalIn => '${totalIn.toStringAsFixed(2)} $unit';
  String get formattedTotalOut => '${totalOut.toStringAsFixed(2)} $unit';
}

class StockMovementsByProductResponse {
  final ProductStockSummary product;
  final List<StockMovementModel> movements;
  final int count;

  StockMovementsByProductResponse({
    required this.product,
    required this.movements,
    required this.count,
  });

  factory StockMovementsByProductResponse.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    return StockMovementsByProductResponse(
      product: ProductStockSummary.fromJson(
        results['product'] as Map<String, dynamic>,
      ),
      movements:
          (results['movements'] as List?)
              ?.map(
                (item) =>
                    StockMovementModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      count: json['count'] as int,
    );
  }
}
