import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/provider/CategoryProvider.dart';
import '../../../app/routes.dart';
import '../../../controller/admin/category_controller.dart';
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
  String _selectedInventory = "All";
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final items = await InventoryController.getInventory(); // caching active
      setState(() {
        _inventoryItems = items;
        _isLoading = false;
      });
    } catch (e) {
      e.toString();
    }
  }

  List<RecycleInventory> get _filteredItems {
    return _inventoryItems.where((item) {
      final searchLower = _searchQuery.toLowerCase().trim();
      final matchesSearch =
          searchLower.isEmpty ||
          item.inventoryName.toLowerCase().contains(searchLower);

      final matchesInventory =
          _selectedInventory == "All" ||
          item.inventoryName.trim().toLowerCase() ==
              _selectedInventory.trim().toLowerCase();

      return matchesSearch && matchesInventory;
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inventoryItems.isEmpty
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
                        _buildInventoryCard(_filteredItems[index], theme),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, Routes.adminAddInventory),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          Routes.adminViewInventory,
          arguments: item,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 90,
                  height: 100,
                  color: theme.surfaceVariant,
                  child: item.imgPath.isNotEmpty
                      ? (item.imgPath.startsWith('http')
                            ? Image.network(
                                item.imgPath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.inventory_2_outlined,
                                  color: theme.primary,
                                  size: 36,
                                ),
                              )
                            : Image.asset(
                                'assets/images/${item.imgPath}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.inventory_2_outlined,
                                  color: theme.primary,
                                  size: 36,
                                ),
                              ))
                      : Icon(
                          Icons.inventory_2_outlined,
                          color: theme.primary,
                          size: 36,
                        ),
                ),
              ),

              const SizedBox(width: 16),

              // CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.inventoryName.trim(),
                      style: TextDesign.mediumText().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // BADGES
                    Wrap(
                      spacing: 8,
                      children: [
                        // STOCK BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stockText,
                            style: TextStyle(
                              color: stockColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // STATUS BADGE (FIXED ENUM)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.status.name.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn(
                          "Stock",
                          "${weight.toStringAsFixed(1)} kg",
                          theme,
                        ),
                        _buildInfoColumn(
                          "Price",
                          "RM ${price.toStringAsFixed(2)}",
                          theme,
                        ),
                        _buildInfoColumn(
                          "Min",
                          "${minWeight.toStringAsFixed(1)} kg",
                          theme,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Cat ID: ${item.categoryId} • Updated: $dateFormatted",
                      style: TextDesign.smallText(color: theme.hint),
                    ),
                  ],
                ),
              ),

              // ACTIONS
              Column(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      Routes.adminUpdateInventory,
                      arguments: item,
                    ),
                    icon: Icon(Icons.edit_note_rounded, color: theme.warning),
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(item, theme),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to keep the layout clean
  Widget _buildInfoColumn(String label, String value, AppColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.hint,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: theme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, AppColors theme) {
    // 1. Read the provider correctly
    final categoryProvider = context.read<CategoryProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        // 2. Build the list dynamically using the provider's data
        final filterOptions = [
          "All",
          // Map through the provider's list of categories
          ...categoryProvider.categories.map((c) => c.categoryName),
        ];

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column( // Optional: Good practice to wrap in a column for bottom sheets
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  "Filter by Category",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold) // Use your TextDesign here
              ),
              const SizedBox(height: 16),
              Flexible( // Use Flexible to prevent overflow if the list gets too long
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filterOptions.length,
                  itemBuilder: (context, index) {
                    final cat = filterOptions[index];

                    // Assuming _selectedCategory is your state variable (you had _selectedInventory)
                    bool isSelected = _selectedCategory == cat;

                    return ListTile(
                      title: Text(cat),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: theme.primary)
                          : null,
                      onTap: () {
                        // Update the state in the parent widget
                        setState(() => _selectedCategory = cat);
                        // Close the bottom sheet using the specific context
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(RecycleInventory item, AppColors theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
              } finally {
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
