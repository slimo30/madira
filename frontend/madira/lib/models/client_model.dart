class ClientModel {
  final int id;
  final String name;
  final String phone;
  final String address;
  final String creditBalance;
  final String clientType;
  final String notes;
  final bool isActive;
  final String createdAt;

  ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.creditBalance,
    required this.clientType,
    required this.notes,
    required this.isActive,
    required this.createdAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      creditBalance: json['credit_balance']?.toString() ?? '0.00',
      clientType: json['client_type'] as String? ?? 'new',
      notes: json['notes'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'credit_balance': creditBalance,
      'client_type': clientType,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }

  String get formattedCreatedAt {
    try {
      final dateTime = DateTime.parse(createdAt);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return createdAt;
    }
  }

  String get formattedCreditBalance {
    try {
      final amount = double.parse(creditBalance);
      return '${amount.toStringAsFixed(2)} DA';
    } catch (e) {
      return '$creditBalance DA';
    }
  }

  String get clientTypeDisplay {
    switch (clientType.toLowerCase()) {
      case 'new':
        return 'New';
      case 'old':
        return 'Regular';
      case 'vip':
        return 'VIP';
      default:
        return clientType;
    }
  }
}
