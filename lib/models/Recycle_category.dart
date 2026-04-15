class RecycleCategory {
  final int categoryId;
  final String categoryName;
  final String? description;
  final double? point;
  final double? baseWeight;
  final String? img_path;

  RecycleCategory({
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.point,
    this.baseWeight,
    this.img_path,
  });

  factory RecycleCategory.fromJson(Map<String, dynamic> json) {
    return RecycleCategory(
      categoryId: json['category_id'],
      categoryName: json['category_name']?.toString() ?? 'Unknown Category',
      description: json['description']?.toString(),

      img_path: json['img_path']?.toString(),

      point: json['point'] != null
          ? (json['point'] as num).toDouble()
          : null,

      baseWeight: json['base_weight'] != null
          ? (json['base_weight'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_name': categoryName,
      'description': description,
      'point': point,
      'base_weight': baseWeight,
      'img_path': img_path,
    };
  }
}