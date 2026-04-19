import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

import '../../../app/routes.dart';
import '../../../controller/admin/category_controller.dart';
import '../../../models/Recycle_category.dart';
import '../../../provider/CategoryProvider.dart';
import 'admin_add_category.dart';

class AdminCategory extends StatefulWidget {
  const AdminCategory({super.key});

  @override
  State<AdminCategory> createState() => _AdminCategoryState();
}

class _AdminCategoryState extends State<AdminCategory> {

  List<RecycleCategory> get _categoryItems =>
      context.watch<CategoryProvider>().categories;
  bool _isLoading = true;

  String _searchQuery = "";
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  // =========================
  // LOAD DATA (FIXED)
  // =========================
  Future<void> _loadCategory() async {
    setState(() => _isLoading = true);

    try {
      await context.read<CategoryProvider>().fetchCategories();

      if (!mounted) return;

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final provider = context.watch<CategoryProvider>();
    final displayData = _filteredItems(provider.categories);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayData.isEmpty
          ? _buildEmptyState(theme)
          : Column(
        children: [
          _buildSearchHeader(theme),

          Padding(
            padding: const EdgeInsets.only(left: 20, top: 10),
            child: Text("Categories",
                style: TextDesign.headingThree()),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayData.length,
              itemBuilder: (context, index) =>
                  _buildCategoryCard(displayData[index], theme),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            Routes.adminAddCategory,
          );
          if (result == true) {
            _loadCategory();
          }
        },
        backgroundColor: theme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // =========================
  // CATEGORY CARD
  // =========================
  Widget _buildCategoryCard(RecycleCategory item, AppColors theme) {
    return Card(
      child: ListTile(
        title: Text(item.categoryName),
        subtitle: Text(item.description ?? "No description"),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: theme.warning),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  Routes.adminUpdateCategory,
                  arguments: item,
                );
                if (result == true) {
                  _loadCategory(); // only refresh if updated
                }
              },
            ),

            IconButton(
              icon: Icon(Icons.delete, color: theme.error),
              onPressed: () => _confirmDelete(item, theme),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // DELETE
  // =========================
  void _confirmDelete(RecycleCategory item, AppColors theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category?"),
        content: Text("Delete '${item.categoryName}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.error),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await CategoryController().deleteCategory(item.categoryId);
                await _loadCategory();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Deleted successfully")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Delete failed: $e")),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // =========================
  // SEARCH FILTER
  // =========================
  List<RecycleCategory> _filteredItems(List<RecycleCategory> items) {
    return items.where((item) {
      final matchSearch = item.categoryName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      return matchSearch;
    }).toList();
  }

  // =========================
  // SEARCH UI
  // =========================
  Widget _buildSearchHeader(AppColors theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Search category...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // =========================
  // EMPTY STATE
  // =========================
  Widget _buildEmptyState(AppColors theme) {
    return const Center(
      child: Text("No categories found"),
    );
  }
}