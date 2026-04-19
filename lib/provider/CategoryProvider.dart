import 'package:flutter/material.dart';
import 'package:recycle_go/controller/admin/category_controller.dart';
import 'package:recycle_go/models/Recycle_category.dart';

class CategoryProvider extends ChangeNotifier {
  List<RecycleCategory> _categories = [];
  bool _isLoading = false;

  List<RecycleCategory> get categories => _categories;
  bool get isLoading => _isLoading;

  final CategoryController _controller = CategoryController();

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _controller.getAllCategories();
      _categories = data;
    } catch (e) {
      debugPrint("Provider Error fetching: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(RecycleCategory newCategory) async {
    try {
      await _controller.addCategory(newCategory);
      await fetchCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(RecycleCategory category) async {
    try {
      // Pass the entire category object directly to the controller!
      await _controller.updateCategory(category);

      // Refresh list after updating
      await fetchCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _controller.deleteCategory(id);
      _categories.removeWhere((c) => c.categoryId == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}