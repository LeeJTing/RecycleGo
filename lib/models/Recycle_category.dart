import 'Connector.dart';

class RecycleCategory {
  final int categoryId;
  final String categoryName;
  final String? description;
  final double? point;
  final double? baseWeight;
  final double? density;
  final String? label;
  final String? categoryStatus;

  const RecycleCategory({
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.point,
    this.baseWeight,
    this.density,
    this.label,
    this.categoryStatus, // ✅ NEW
  });

  /// 🔹 FROM JSON (Supabase → App)
  factory RecycleCategory.fromJson(Map<String, dynamic> json) {
    return RecycleCategory(
      categoryId: (json['category_id'] as num).toInt(),
      categoryName: json['category_name']?.toString() ?? 'Unknown Category',
      description: json['description']?.toString(),
      point: (json['point'] as num?)?.toDouble(),
      baseWeight: (json['base_weight'] as num?)?.toDouble(),
      density: (json['density'] as num?)?.toDouble(),
      label: json['label']?.toString(),
      categoryStatus: json['category_status']?.toString(), // ✅ NEW
    );
  }

  /// 🔹 TO JSON (App → Supabase)
  Map<String, dynamic> toJson() {
    return {
      'category_name': categoryName,
      if (description != null) 'description': description,
      if (point != null) 'point': point,
      if (baseWeight != null) 'base_weight': baseWeight,
      if (density != null) 'density': density,
      if (label != null) 'label': label,
      if (categoryStatus != null) 'category_status': categoryStatus,
    };
  }

  RecycleCategory copyWith({
    int? categoryId,
    String? categoryName,
    String? description,
    double? point,
    double? baseWeight,
    double? density,
    String? label,
    String? categoryStatus,
  }) {
    return RecycleCategory(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      point: point ?? this.point,
      baseWeight: baseWeight ?? this.baseWeight,
      density: density ?? this.density,
      label: label ?? this.label,
      categoryStatus: categoryStatus ?? this.categoryStatus,
    );
  }

  /// 🔹 EQUALITY
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecycleCategory &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.description == description &&
        other.point == point &&
        other.baseWeight == baseWeight &&
        other.density == density &&
        other.label == label &&
        other.categoryStatus == categoryStatus;
  }

  /// 🔹 HASHCODE
  @override
  int get hashCode => Object.hash(
    categoryId,
    categoryName,
    description,
    point,
    baseWeight,
    density,
    label,
    categoryStatus,
  );

  /// 🔹 DEBUG PRINT
  @override
  String toString() {
    return 'RecycleCategory('
        'id: $categoryId, '
        'name: $categoryName, '
        'point: $point, '
        'baseWeight: $baseWeight, '
        'density: $density, '
        'label: $label, '
        'status: $categoryStatus'
        ')';
  }
}

class RecycleCategoryModel extends Connector {
  static final RecycleCategoryModel _instance =
  RecycleCategoryModel._internal();

  RecycleCategoryModel._internal();

  factory RecycleCategoryModel() => _instance;

  /// 🔹 FETCH ALL
  Future<List<RecycleCategory>> fetchAllCategories() async {
    try {
      final response = await client
          .from('recycle_category')
          .select()
          .order('category_id', ascending: true);

      return (response as List)
          .map((e) => RecycleCategory.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  /// 🔹 FETCH BY ID
  Future<RecycleCategory?> fetchById(int id) async {
    try {
      final response = await client
          .from('recycle_category')
          .select()
          .eq('category_id', id)
          .maybeSingle();

      if (response == null) return null;

      return RecycleCategory.fromJson(response);
    } catch (e) {
      print('Error fetching category by id: $e');
      rethrow;
    }
  }

  /// 🔹 CREATE CATEGORY
  Future<RecycleCategory?> createCategory(
      RecycleCategory category) async {
    try {
      final response = await client
          .from('recycle_category')
          .insert(category.toJson())
          .select()
          .single();

      return RecycleCategory.fromJson(response);
    } catch (e) {
      print('Error creating category: $e');
      rethrow;
    }
  }

  /// 🔹 UPDATE CATEGORY
  Future<RecycleCategory?> updateCategory(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await client
          .from('recycle_category')
          .update(data)
          .eq('category_id', id)
          .select()
          .single();

      return RecycleCategory.fromJson(response);
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  /// 🔹 SOFT DELETE (Update status to inactive)
  Future<void> deleteCategory(int id) async {
    try {
      await client
          .from('recycle_category')
          .update({
        'category_status': 'inactive',
      })
          .eq('category_id', id);
    } catch (e) {
      print('Error archiving category: $e');
      rethrow;
    }
  }
}