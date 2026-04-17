import 'package:flutter/material.dart';
import 'package:recycle_go/models/Recycle_category.dart';
import '../../services/supabase_service.dart';

class CategoryController extends ChangeNotifier {
  static const String _tableName = 'recycle_category';
  static final supabase = SupabaseService().client;

  List<RecycleCategory> _categories = [];
  List<RecycleCategory> get categories => _categories;

  // --- Fetch all categories (instance method) ---
  Future<void> fetchCategories() async {
    try {
      final fetched = await _getCategories();
      _categories = fetched;
      notifyListeners();
    } catch (e) {
      _categories = [];
      notifyListeners();
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // --- Internal method to get raw categories from Supabase ---
  Future<List<RecycleCategory>> _getCategories() async {
    final response = await supabase.from(_tableName).select();
    // response is always List<dynamic> on success, throws on error
    final data = response as List<dynamic>;
    return data.map((json) => RecycleCategory.fromJson(json)).toList();
  }

  // --- Add a new category ---
  Future<void> addCategory(RecycleCategory category) async {
    try {
      await supabase.from(_tableName).insert({
        'category_name': category.categoryName,
        'description': category.description,
      });
      // Optionally refresh the list after adding
      await fetchCategories();
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // --- Update an existing category ---
  Future<void> updateCategory(RecycleCategory category) async {
    try {
      await supabase
          .from(_tableName)
          .update({
        'category_name': category.categoryName,
        'description': category.description,
      })
          .eq('category_id', category.categoryId);
      // Refresh list after update
      await fetchCategories();
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // --- Delete a category by ID ---
  Future<void> deleteCategory(int categoryId) async {
    try {
      await supabase
          .from(_tableName)
          .delete()
          .eq('category_id', categoryId);
      // Refresh list after deletion
      await fetchCategories();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}