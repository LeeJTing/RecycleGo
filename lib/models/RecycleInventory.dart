import 'package:flutter/foundation.dart';

enum InventoryStatus {
  active,
  inactive,
  lowStock,
}

@immutable
class RecycleInventory {
  final String inventoryId;
  final String inventoryCode;
  final double pricePerKg;
  final double totalWeightAvailable;
  final InventoryStatus status;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final int categoryId;
  final String imgPath;
  final String inventoryName;
  final double? minWeightLevel;
  final String description;

  const RecycleInventory({
    required this.inventoryId,
    required this.inventoryCode,
    required this.pricePerKg,
    required this.totalWeightAvailable,
    this.status = InventoryStatus.active,
    this.updatedAt,
    this.createdAt,
    required this.categoryId,
    required this.imgPath,
    required this.inventoryName,
    this.minWeightLevel,
    this.description = ''
  })  : assert(pricePerKg >= 0, 'pricePerKg cannot be negative'),
        assert(totalWeightAvailable >= 0, 'totalWeightAvailable cannot be negative'),
        assert(minWeightLevel == null || minWeightLevel >= 0, 'minWeightLevel cannot be negative');

  // --- Factory from JSON ---
  factory RecycleInventory.fromJson(Map<String, dynamic> json) {
    return RecycleInventory(
      inventoryId: json['inventory_id']?.toString() ?? '',
      inventoryCode: json['inventory_code']?.toString() ?? '',
      pricePerKg: (json['price_per_kg'] as num?)?.toDouble() ?? 0.0,
      totalWeightAvailable: (json['total_weight_available'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(json['status']?.toString()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      categoryId: (json['category_id'] as num?)?.toInt() ?? 0,
      imgPath: json['img_path']?.toString() ?? '',
      inventoryName: json['inventory_name']?.toString() ?? '',
      minWeightLevel: (json['min_weight_level'] as num?)?.toDouble(),
      description: json['description']?.toString() ?? '',
    );
  }

  // --- JSON serialization ---
  Map<String, dynamic> toJson() {
    return {
      'inventory_id': inventoryId,
      'inventory_code': inventoryCode,
      'price_per_kg': pricePerKg,
      'total_weight_available': totalWeightAvailable,
      'status': status.name,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'category_id': categoryId,
      'img_path': imgPath,
      'inventory_name': inventoryName,
      if (minWeightLevel != null) 'min_weight_level': minWeightLevel,
      'description': description,
    };
  }

  static InventoryStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return InventoryStatus.active;
      case 'low_stock':
      case 'lowstock':
        return InventoryStatus.lowStock;
      case 'inactive':
      default:
        return InventoryStatus.inactive;
    }
  }

  // --- Computed status ---
  InventoryStatus get calculatedStatus {
    if (status == InventoryStatus.inactive) return InventoryStatus.inactive;
    if (minWeightLevel != null && totalWeightAvailable <= minWeightLevel!) {
      return InventoryStatus.lowStock;
    }
    return InventoryStatus.active;
  }

  RecycleInventory copyWith({
    String? inventoryId,
    String? inventoryCode,
    double? pricePerKg,
    double? totalWeightAvailable,
    InventoryStatus? status,
    DateTime? updatedAt,
    DateTime? createdAt,
    int? categoryId,
    String? imgPath,
    String? inventoryName,
    double? minWeightLevel,
    String? description,
  }) {
    return RecycleInventory(
      inventoryId: inventoryId ?? this.inventoryId,
      inventoryCode: inventoryCode ?? this.inventoryCode,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalWeightAvailable: totalWeightAvailable ?? this.totalWeightAvailable,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      categoryId: categoryId ?? this.categoryId,
      imgPath: imgPath ?? this.imgPath,
      inventoryName: inventoryName ?? this.inventoryName,
      minWeightLevel: minWeightLevel ?? this.minWeightLevel,
      description: description ?? this.description,
    );
  }

  // --- Equality ---
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecycleInventory &&
        other.inventoryId == inventoryId &&
        other.inventoryCode == inventoryCode &&
        other.pricePerKg == pricePerKg &&
        other.totalWeightAvailable == totalWeightAvailable &&
        other.status == status &&
        other.updatedAt == updatedAt &&
        other.createdAt == createdAt &&
        other.categoryId == categoryId &&
        other.imgPath == imgPath &&
        other.inventoryName == inventoryName &&
        other.minWeightLevel == minWeightLevel &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(
    inventoryId,
    inventoryCode,
    pricePerKg,
    totalWeightAvailable,
    status,
    updatedAt,
    createdAt,
    categoryId,
    imgPath,
    inventoryName,
    minWeightLevel,
    description,
  );

  @override
  String toString() {
    return 'RecycleInventory('
        'id: $inventoryId, '
        'name: $inventoryName, '
        'price: $pricePerKg, '
        'weight: $totalWeightAvailable, '
        'status: $status'
        ')';
  }
}