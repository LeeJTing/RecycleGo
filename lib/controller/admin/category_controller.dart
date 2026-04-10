import 'package:recycle_go/models/Recycle_category.dart';
import '../../services/supabase_service.dart';

class CategoryController {
  static const String _tableName = 'recycle_category';
  static final supabase = SupabaseService().client;

  static Future<List<RecycleCategory>> getCategories() async {
    final response = await supabase.from(_tableName).select();

    if (response == null) {
      throw Exception('Failed to fetch categories');
    }

    final data = response as List<dynamic>;
    return data.map((json) => RecycleCategory.fromJson(json)).toList();
  }

  static Future<void> addCategory(RecycleCategory category) async {
    final response = await supabase.from(_tableName).insert({
      'category_name': category.categoryName,
      'description': category.description,
    });

    if (response == null) {
      throw Exception('Failed to add category');
    }
  }

  static Future<void> updateCategory(RecycleCategory category) async {
    final response = await supabase
        .from(_tableName)
        .update({
      'category_name': category.categoryName,
      'description': category.description,
    })
        .eq('category_id', category.categoryId);

    if (response == null) {
      throw Exception('Failed to update category');
    }
  }

  static Future<void> deleteCategory(int categoryId) async {
    final response = await supabase
        .from(_tableName)
        .delete()
        .eq('category_id', categoryId);

    if (response == null) {
      throw Exception('Failed to delete category');
    }
  }
}