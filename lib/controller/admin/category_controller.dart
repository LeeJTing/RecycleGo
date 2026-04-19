import 'package:flutter/material.dart';
import 'package:recycle_go/models/Recycle_category.dart';
import '../../services/supabase_service.dart';

class CategoryController {
  final RecycleCategoryModel _model = RecycleCategoryModel();

  Future<List<RecycleCategory>> getAllCategories() {
    return _model.fetchAllCategories();
  }

  Future<void> addCategory(RecycleCategory category) async {
    final newCategory = category.copyWith(
      categoryStatus: "active",
    );

    await _model.createCategory(newCategory);
  }

  Future<void> updateCategory(RecycleCategory category) {
    return _model.updateCategory(category.categoryId, category.toJson());
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _model.deleteCategory(id);
    } catch (e) {
      print('Controller Error: $e');
      rethrow;
    }
  }

  Future<void> toggleCategoryStatus(int id, String currentStatus) {
    final newStatus =
    currentStatus == "active" ? "inactive" : "active";

    return _model.updateCategory(id, {
      "category_status": newStatus,
    });
  }
}