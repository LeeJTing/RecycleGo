import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import '../../app/routes.dart';
import '../../controller/admin/inventory_controller.dart';
import '../../models/RecycleInventory.dart';

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
      final matchesSearch = searchLower.isEmpty ||
          item.inventoryName!.toLowerCase().contains(searchLower);

      final matchesInventory = _selectedInventory == "All" ||
          item.inventoryName?.trim().toLowerCase() == _selectedInventory.trim().toLowerCase();

      return matchesSearch && matchesInventory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final displayData = _filteredItems;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body:  _isLoading
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
            padding: const EdgeInsets.only(left: 28.0, top: 12.0, bottom: 8.0),
            child: Text("Items", style: TextDesign.headingThree()),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Icon(Icons.inventory_2_outlined, size: 80, color: theme.hint.withOpacity(0.3)),
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
                  prefixIcon: Icon(Icons.search, color: theme.primary, size: 20),
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
    // 1. Map variables exactly to your model
    final double weight = item.totalWeightAvailable;
    final double price = item.pricePerKg;
    final double minWeight = item.minWeightLevel ?? 50.0; // Fallback to 50 if null
    final String name = item.inventoryName ?? "Unnamed Item";

    // 2. Dynamic Stock Status Logic (Using minWeightLevel!)
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

    // 3. Format the date beautifully (e.g., 2026-04-15)
    String dateFormatted = "Unknown";
    if (item.updatedAt != null) {
      dateFormatted = "${item.updatedAt!.year}-${item.updatedAt!.month.toString().padLeft(2, '0')}-${item.updatedAt!.day.toString().padLeft(2, '0')}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            Routes.adminViewInventory,
            arguments: item,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- LEFT: Image ---
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    height: 100,
                    color: theme.surfaceVariant,
                    child: (item.imgPath != null && item.imgPath!.isNotEmpty)
                        ? Image.asset(
                      'assets/images/${item.imgPath!}', // 👈 important
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.broken_image_outlined, color: theme.hint),
                    )
                        : Icon(Icons.inventory_2_outlined,
                        color: theme.primary, size: 36),
                  ),
                ),
                const SizedBox(width: 16),

                // --- MIDDLE: Content & Details ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        name,
                        style: TextDesign.mediumText().copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Badges Row (Stock Level & DB Status)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Stock Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          // DB Status Badge (Active/Inactive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.status == 'active'
                                  ? theme.primary.withOpacity(0.1)
                                  : theme.hint.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: TextStyle(
                                color: item.status == 'active' ? theme.primary : theme.hint,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Information Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn("Stock", "${weight.toStringAsFixed(1)} kg", theme),
                          _buildInfoColumn("Price", "RM ${price.toStringAsFixed(2)}", theme),
                          _buildInfoColumn("Min", "${minWeight.toStringAsFixed(1)} kg", theme),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Footer Data (Category & Updated At)
                      Text(
                        "Cat ID: ${item.categoryId ?? 'N/A'} • Updated: $dateFormatted",
                        style: TextDesign.smallText(color: theme.hint).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // --- RIGHT: Action Buttons ---
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        Routes.adminUpdateInventory,
                        arguments: item,
                      ),
                      icon: Icon(Icons.edit_note_rounded, color: theme.warning, size: 26),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(bottom: 12, left: 8),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(item, theme), // Assuming you have this method
                      icon: Icon(Icons.delete_outline_rounded, color: theme.error, size: 24),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(left: 8),
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

  // Helper widget to keep the layout clean
  Widget _buildInfoColumn(String label, String value, AppColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.hint, fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: theme.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, AppColors theme) {
    final categories = ["All", "Plastic", "Paper", "Glasses", "CardBoard", "Metal"];
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
              Text("Filter by Inventory", style: TextDesign.headingThree()),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => Divider(color: theme.border.withOpacity(0.5)),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    bool isSelected = _selectedInventory == cat;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        cat,
                        style: TextDesign.mediumText(
                          color: isSelected ? theme.primary : theme.onSurface,
                        ),
                      ),
                      trailing: isSelected ? Icon(Icons.check_circle, color: theme.primary) : null,
                      onTap: () {
                        setState(() => _selectedInventory = cat);
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
                await InventoryController.deleteInventory(item.inventoryId);
                await _loadInventory();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
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