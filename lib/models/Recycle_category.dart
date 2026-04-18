class RecycleCategory {
  final int categoryId;
  final String categoryName;
  final String? description;
  final double? point;
  final double? baseWeight;

  const RecycleCategory({
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.point,
    this.baseWeight,
  });

  factory RecycleCategory.fromJson(Map<String, dynamic> json) {
    return RecycleCategory(
      categoryId: (json['category_id'] as num).toInt(),
      categoryName: json['category_name']?.toString() ?? 'Unknown Category',
      description: json['description']?.toString(),
      point: (json['point'] as num?)?.toDouble(),
      baseWeight: (json['base_weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      if (description != null) 'description': description,
      if (point != null) 'point': point,
      if (baseWeight != null) 'base_weight': baseWeight,
    };
  }

  RecycleCategory copyWith({
    int? categoryId,
    String? categoryName,
    String? description,
    double? point,
    double? baseWeight,
  }) {
    return RecycleCategory(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      point: point ?? this.point,
      baseWeight: baseWeight ?? this.baseWeight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecycleCategory &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.description == description &&
        other.point == point &&
        other.baseWeight == baseWeight;
  }

  @override
  int get hashCode => Object.hash(
    categoryId,
    categoryName,
    description,
    point,
    baseWeight,
  );

  @override
  String toString() {
    return 'RecycleCategory('
        'id: $categoryId, '
        'name: $categoryName, '
        'point: $point, '
        'baseWeight: $baseWeight'
        ')';
  }
}