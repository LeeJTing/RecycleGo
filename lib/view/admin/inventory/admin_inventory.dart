import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/provider/CategoryProvider.dart';
import '../../../app/routes.dart';
import '../../../controller/admin/inventory_controller.dart';
import '../../../models/RecycleInventory.dart';

class AdminInventory extends StatefulWidget {
  const AdminInventory({super.key});

  @override
  State<AdminInventory> createState() => _AdminInventoryState();
}

class _AdminInventoryState extends State<AdminInventory> {
  List<RecycleInventory> _inventoryItems = [];
  bool _isLoading = true;
  String _searchQuery = "";

  // Unified the filter variable to match your bottom sheet
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadInventory();

    // ✨ ADD THIS: Tell the provider to grab the categories when the screen loads!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final items = await InventoryController.getInventory(); // caching active
      if (mounted) {
        setState(() {
          _inventoryItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<RecycleInventory> get _filteredItems {
    final categoryProvider = context.read<CategoryProvider>();

    return _inventoryItems.where((item) {
      // 1. Search Filter
      final searchLower = _searchQuery.toLowerCase().trim();
      final matchesSearch =
          searchLower.isEmpty ||
              item.inventoryName.toLowerCase().contains(searchLower);

      // 2. Category Filter
      bool matchesCategory = true;
      if (_selectedCategory != "All") {
        // Find the category ID that matches the selected name
        final targetCategory = categoryProvider.categories.firstWhere(
              (c) => c.categoryName == _selectedCategory,
          orElse: () => categoryProvider.categories.first, // Fallback
        );
        matchesCategory = item.categoryId == targetCategory.categoryId;
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Color _getStatusColor(InventoryStatus status, AppColors theme) {
    switch (status) {
      case InventoryStatus.active:
        return theme.success;
      case InventoryStatus.lowStock:
        return theme.warning;
      case InventoryStatus.inactive:
        return theme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final displayData = _filteredItems;

    // Adaptive layout variables
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 32.0 : 16.0;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: theme.primary))
            : Center(
          // Constrains the list width on tablets so it doesn't stretch out
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _inventoryItems.isEmpty
                ? _buildNoDataState(theme)
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchHeader(theme, horizontalPadding),
                Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding + 12.0,
                    top: 12.0,
                    bottom: 8.0,
                  ),
                  child: Text("Items", style: TextDesign.headingThree()),
                ),
                Expanded(
                  child: displayData.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      bottom: 80, // Padding for the FAB
                    ),
                    itemCount: displayData.length,
                    itemBuilder: (context, index) =>
                        _buildInventoryCard(displayData[index], theme),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, Routes.adminAddInventory).then((_) {
          // Reload inventory when returning from the Add screen
          _loadInventory();
        }),
        backgroundColor: theme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
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
            "No inventory items found",
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

  Widget _buildSearchHeader(AppColors theme, double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
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
                style: TextDesign.normalText(),
                decoration: InputDecoration(
                  hintText: "Search items...",
                  hintStyle: TextDesign.hintText(),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.hint,
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

  Widget _buildInventoryCard(RecycleInventory item, AppColors theme) {
    final double weight = item.totalWeightAvailable;
    final double price = item.pricePerKg;
    final double minWeight = item.minWeightLevel ?? 50.0;

    final statusColor = _getStatusColor(item.status, theme);
    String stockText;
    Color stockColor;

    if (weight <= 0) {
      stockText = "OUT OF STOCK";
      stockColor = theme.error;
    } else if (weight <= minWeight) {
      stockText = "LOW STOCK";
      stockColor = theme.warning;
    } else {
      stockText = "IN STOCK";
      stockColor = theme.success;
    }

    String dateFormatted = "Unknown";
    if (item.updatedAt != null) {
      dateFormatted =
      "${item.updatedAt!.year}-${item.updatedAt!.month.toString().padLeft(2, '0')}-${item.updatedAt!.day.toString().padLeft(2, '0')}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Slightly tighter margin
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16), // Slightly smaller radius to match compact feel
        border: Border.all(color: theme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
          context,
          Routes.adminViewInventory,
          arguments: item,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced padding for a more compact card
          child: Row(
            children: [
              // IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 80, // Slightly smaller image
                  height: 90,
                  color: theme.surfaceVariant,
                  child: item.imgPath.isNotEmpty
                      ? (item.imgPath.startsWith('http')
                      ? Image.network(
                    item.imgPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.inventory_2_outlined,
                      color: theme.primary,
                      size: 30,
                    ),
                  )
                      : Image.asset(
                    'assets/images/${item.imgPath}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.inventory_2_outlined,
                      color: theme.primary,
                      size: 30,
                    ),
                  ))
                      : Icon(
                    Icons.inventory_2_outlined,
                    color: theme.primary,
                    size: 30,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✨ Smaller, compact title text (Changed from mediumText to fontSize: 14)
                    Text(
                      item.inventoryName.trim(),
                      style: TextStyle(
                        color: theme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // BADGES
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // STOCK BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stockText,
                            style: TextStyle(
                              color: stockColor,
                              fontSize: 9, // Smaller badge text
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // STATUS BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.status.name.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9, // Smaller badge text
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn("Stock", "${weight.toStringAsFixed(1)} kg", theme),
                        _buildInfoColumn("Price", "RM ${price.toStringAsFixed(2)}", theme),
                        _buildInfoColumn("Min", "${minWeight.toStringAsFixed(1)} kg", theme),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ✨ Smaller footer text
                    Text(
                      "Cat ID: ${item.categoryId} • Updated: $dateFormatted",
                      style: TextStyle(color: theme.hint, fontSize: 10),
                    ),
                  ],
                ),
              ),

              // ACTIONS (Slightly smaller icons to match text size)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      Routes.adminUpdateInventory,
                      arguments: item,
                    ).then((_) => _loadInventory()),
                    icon: Icon(Icons.edit_note_rounded, color: theme.warning, size: 22),
                    constraints: const BoxConstraints(), // Removes extra default padding
                    padding: const EdgeInsets.all(8),
                  ),
                  const SizedBox(height: 12),
                  IconButton(
                    onPressed: () => _confirmDelete(item, theme),
                    icon: Icon(Icons.delete_outline_rounded, color: theme.error, size: 22),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, AppColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.hint,
            fontSize: 9, // Reduced label size
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: theme.onSurface,
            fontSize: 11, // Reduced value size (was 13)
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, AppColors theme) {
    final categoryProvider = context.read<CategoryProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      isScrollControlled: true, // Allows sheet to size properly if list is long
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final filterOptions = [
          "All",
          ...categoryProvider.categories.map((c) => c.categoryName),
        ];

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6, // Prevents taking up whole screen
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Filter by Category",
                    style: TextDesign.headingThree(),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filterOptions.length,
                      itemBuilder: (context, index) {
                        final cat = filterOptions[index];
                        bool isSelected = _selectedCategory == cat;

                        return ListTile(
                          title: Text(cat, style: TextDesign.normalText()),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: theme.primary)
                              : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            Navigator.pop(sheetContext);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(RecycleInventory item, AppColors theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Remove Item?", style: TextDesign.headingThree()),
        content: Text(
          "Are you sure you want to delete ${item.inventoryName}? This action is permanent.",
          style: TextDesign.normalText(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextDesign.normalText()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              setState(() => _isLoading = true);
              try {
                await InventoryController.deleteInventory(item.inventoryId!);
                await _loadInventory();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
}