class RecycleCategory {
  final int categoryId;
  final String categoryName;
  final String? description;

  RecycleCategory({
    required this.categoryId,
    required this.categoryName,
    this.description,
  });

  factory RecycleCategory.fromJson(Map<String, dynamic> json) {
    return RecycleCategory(
      // We use 'as int' or 'int.parse' to ensure bigint compatibility
      categoryId: json['category_id'] as int,

      // We use ?? to provide a fallback in case the DB has a null
      categoryName: json['category_name']?.toString() ?? 'Unknown Category',

      // Description is allowed to be null in your SQL, so we keep it String?
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_name': categoryName,
      'description': description,
    };
  }
}