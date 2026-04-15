import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

import '../../../app/routes.dart';
import '../../../controller/admin/category_controller.dart';
import '../../../models/Recycle_category.dart';

class AdminCategory extends StatefulWidget {
  const AdminCategory({super.key});

  @override
  State<AdminCategory> createState() => _AdminCategoryState();
}

// Navigator.push(
// context,
// MaterialPageRoute(
// builder: (context) => const AdminRecycleCategory(),
// fullscreenDialog: true,
// ),
// )

class _AdminCategoryState extends State<AdminCategory> {
  List<RecycleCategory> _categoryItems = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    setState(() => _isLoading = true);
    try {
      final items = await CategoryController.getCategories(); // caching active
      setState(() {
        _categoryItems = items;
        _isLoading = false;
      });
    } catch (e) {
      e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final displayData = _filteredItems;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categoryItems.isEmpty
          ? _buildNoDataState(theme)
          : _filteredItems.isEmpty
          ? _buildEmptyState(theme)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchHeader(theme),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 28.0,
                    top: 12.0,
                    bottom: 8.0,
                  ),
                  child: Text("Items", style: TextDesign.headingThree()),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) =>
                        _buildCategoryCard(_filteredItems[index], theme),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, Routes.adminAddCategory),
        backgroundColor: theme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(RecycleCategory item, AppColors theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Category?", style: TextDesign.headingThree()),
        content: Text(
          "Are you sure you want to delete '${item.categoryName}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextDesign.normalText()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (item.categoryId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid category ID")),
                );
                return;
              }

              setState(() => _isLoading = true);

              try {
                await CategoryController.deleteCategory(item.categoryId!);
                await _loadCategory();
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.error),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(RecycleCategory item, AppColors theme) {
    final weight = item.baseWeight ?? 0;
    final point = item.point ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            Routes.adminCategory,
            arguments: item,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.categoryName,
                        style: TextDesign.mediumText().copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        item.description ?? "No description provided.",
                        style: TextDesign.smallText(),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Text(
                            "Base Weight: ${weight.toStringAsFixed(1)} kg",
                            style: TextDesign.smallText().copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            "Price per kg: RM ${point.toStringAsFixed(2)}",
                            style: TextDesign.priceText(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Actions
                Column(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        Routes.adminUpdateCategory,
                        arguments: item,
                      ),
                      icon: Icon(
                        Icons.edit_note_rounded,
                        color: theme.warning,
                        size: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(item, theme),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.error,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<RecycleCategory> get _filteredItems {
    return _categoryItems.where((item) {
      final searchLower = _searchQuery.toLowerCase().trim();
      final matchesSearch =
          searchLower.isEmpty ||
          item.categoryName.toLowerCase().contains(searchLower);

      final matchesCategory =
          _selectedCategory == "All" ||
          item.categoryName.trim().toLowerCase() ==
              _selectedCategory.trim().toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildSearchHeader(AppColors theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.border.withOpacity(0.5)),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextDesign.normalText(), // predefined
                decoration: InputDecoration(
                  hintText: "Search items...",
                  hintStyle: TextDesign.hintText(), // predefined
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.primary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.white, size: 20),
              onPressed: () => _showFilterSheet(context, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(AppColors theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: theme.hint.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No category items found",
            style: TextDesign.headingThree(color: theme.hint),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button to add your first item",
            style: TextDesign.smallText(color: theme.hint),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, AppColors theme) {
    final categories = [
      "All",
      "Plastic",
      "Paper",
      "Glasses",
      "CardBoard",
      "Metal",
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Filter by Category", style: TextDesign.headingThree()),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: theme.border.withOpacity(0.5)),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    bool isSelected = _selectedCategory == cat;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        cat,
                        style: TextDesign.mediumText(
                          color: isSelected ? theme.primary : theme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: theme.primary)
                          : null,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppColors theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: theme.hint.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "No materials match your search",
            style: TextDesign.mediumText(color: theme.hint),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, AppColors theme) {
    // A simple bottom sheet or dialog to quickly add a new category
    // This keeps the user in the flow without needing a whole new screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows it to move up with the keyboard
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Avoid keyboard
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("New Category", style: TextDesign.headingThree()),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: "Category Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("Save Category", style: TextDesign.buttonText()),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
