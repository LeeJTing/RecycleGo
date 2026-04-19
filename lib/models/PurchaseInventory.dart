// purchase_inventory.dart
class PurchaseInventory {
  final String? inventoryId;          // UUID (auto-generated)
  final String? inventoryCode;
  final double pricePerKg;
  final double totalWeightAvailable;
  final String status;                // 'active' or 'inactive'
  final DateTime updatedAt;
  final int? categoryId;
  final String? imgPath;
  final String? inventoryName;
  final double? minWeightLevel;
  final String? description;

  PurchaseInventory({
    this.inventoryId,
    this.inventoryCode,
    required this.pricePerKg,
    required this.totalWeightAvailable,
    required this.status,
    required this.updatedAt,
    this.categoryId,
    this.imgPath,
    this.inventoryName,
    this.minWeightLevel,
    this.description,
  });

  // fromJson (for Supabase responses)
  factory PurchaseInventory.fromJson(Map<String, dynamic> json) {
    return PurchaseInventory(
      inventoryId: json['inventory_id']?.toString(),
      inventoryCode: json['inventory_code']?.toString(),
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      totalWeightAvailable: (json['total_weight_available'] as num).toDouble(),
      status: json['status'] ?? 'inactive',
      updatedAt: DateTime.parse(json['updated_at']),
      categoryId: (json['category_id'] as num?)?.toInt(),
      imgPath: json['img_path']?.toString(),
      inventoryName: json['inventory_name']?.toString(),
      minWeightLevel: (json['min_weight_level'] as num?)?.toDouble(),
      description: json['description']?.toString(),
    );
  }

  // toJson (for inserts/updates – omit auto-generated fields)
  Map<String, dynamic> toJson() {
    return {
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (inventoryCode != null) 'inventory_code': inventoryCode,
      'price_per_kg': pricePerKg,
      'total_weight_available': totalWeightAvailable,
      'status': status,
      'updated_at': updatedAt.toIso8601String(),
      if (categoryId != null) 'category_id': categoryId,
      if (imgPath != null) 'img_path': imgPath,
      if (inventoryName != null) 'inventory_name': inventoryName,
      if (minWeightLevel != null) 'min_weight_level': minWeightLevel,
      if (description != null) 'description': description,
    };
  }

  // Copy with
  PurchaseInventory copyWith({
    String? inventoryId,
    String? inventoryCode,
    double? pricePerKg,
    double? totalWeightAvailable,
    String? status,
    DateTime? updatedAt,
    int? categoryId,
    String? imgPath,
    String? inventoryName,
    double? minWeightLevel,
    String? description,
  }) {
    return PurchaseInventory(
      inventoryId: inventoryId ?? this.inventoryId,
      inventoryCode: inventoryCode ?? this.inventoryCode,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalWeightAvailable: totalWeightAvailable ?? this.totalWeightAvailable,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      imgPath: imgPath ?? this.imgPath,
      inventoryName: inventoryName ?? this.inventoryName,
      minWeightLevel: minWeightLevel ?? this.minWeightLevel,
      description: description ?? this.description,
    );
  }
}