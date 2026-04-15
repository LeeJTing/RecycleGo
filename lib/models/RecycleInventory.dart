class RecycleInventory {
  final String inventoryId;
  final double pricePerKg;
  final double totalWeightAvailable;
  final String status;
  final DateTime? updatedAt;
  final int? categoryId;
  final String? imgPath;
  final String? inventoryName;
  final double? minWeightLevel;
  final String? description; // <-- Added from your new SQL schema!

  RecycleInventory({
    required this.inventoryId,
    required this.pricePerKg,
    required this.totalWeightAvailable,
    required this.status,
    this.updatedAt,
    this.categoryId,
    this.imgPath,
    this.inventoryName,
    this.minWeightLevel,
    this.description,
  });

  // Convert from Supabase JSON to Dart Object
  factory RecycleInventory.fromJson(Map<String, dynamic> json) {
    return RecycleInventory(
      inventoryId: json['inventory_id']!.toString(),
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      totalWeightAvailable: (json['total_weight_available'] as num).toDouble(),
      status: json['status']?.toString() ?? 'inactive',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      categoryId: json['category_id'] as int?,
      imgPath: json['img_path']?.toString(),
      inventoryName: json['inventory_name']?.toString(),
      minWeightLevel: json['min_weight_level'] != null
          ? (json['min_weight_level'] as num).toDouble()
          : null,
      description: json['description']?.toString(),
    );
  }

  // Convert Dart Object to JSON for Supabase Insertions/Updates
  Map<String, dynamic> toJson() {
    return {
      if (inventoryId != null) 'inventory_id': inventoryId,
      'price_per_kg': pricePerKg,
      'total_weight_available': totalWeightAvailable,
      'status': status,
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
      if (categoryId != null) 'category_id': categoryId,
      if (imgPath != null) 'img_path': imgPath,
      if (inventoryName != null) 'inventory_name': inventoryName,
      if (minWeightLevel != null) 'min_weight_level': minWeightLevel,
      if (description != null) 'description': description,
    };
  }

  // Used for updating specific fields easily (like when editing)
  RecycleInventory copyWith({
    String? inventoryId,
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
    return RecycleInventory(
      inventoryId: inventoryId ?? this.inventoryId,
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