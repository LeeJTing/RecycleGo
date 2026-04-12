import 'package:recycle_go/models/Connector.dart';

class RecycleInventory {
  final String inventoryId;
  final String inventoryName;
  final double pricePerKg;
  final String? description;
  final int? categoryId;
  final double totalWeight;
  final String? urlImage;

  RecycleInventory({
    required this.inventoryId,
    required this.inventoryName,
    required this.pricePerKg,
    this.description,
    this.categoryId,
    this.totalWeight = 0.0,
    this.urlImage,
  });

  factory RecycleInventory.fromJson(Map<String, dynamic> json) {
    return RecycleInventory(
      // UUID is always a String
      inventoryId: json['inventory_id']?.toString() ?? '',

      // Must match your SQL CHECK constraint: 'Plastic', 'Paper', 'Glasses', 'CardBoard', 'Metal'
      inventoryName: json['inventory_name']?.toString() ?? 'Unknown',

      // SQL 'numeric(10, 2)' safely parsed to double
      pricePerKg: double.tryParse(json['price_per_kg']?.toString() ?? '0') ?? 0.0,

      description: json['description']?.toString(),

      // SQL 'bigint null' safely parsed to int?
      categoryId: json['category_id'] != null
          ? int.tryParse(json['category_id'].toString())
          : null,

      // SQL 'real null' safely parsed to double. Defaults to 0.0 if missing.
      totalWeight: double.tryParse(json['total_weight']?.toString() ?? '0') ?? 0.0,

      urlImage: json['url_image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'inventory_name': inventoryName,
      'price_per_kg': pricePerKg,
      'description': description,
      'category_id': categoryId,
      'total_weight': totalWeight,
      'url_image': urlImage,
    };

    // Only include inventory_id if it's not empty (useful if you let Supabase auto-generate it on INSERT)
    if (inventoryId.isNotEmpty) {
      map['inventory_id'] = inventoryId;
    }

    return map;
  }
}