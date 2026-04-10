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
      final matchesSearch = searchLower.isEmpty ||
          item.inventoryName.toLowerCase().contains(searchLower);

      final matchesCategory = _selectedCategory == "All" ||
          item.inventoryName.trim().toLowerCase() == _selectedCategory.trim().toLowerCase();

      return matchesSearch && matchesCategory;
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
    final double weight = item.totalWeight;
    final double price = item.pricePerKg;

    String statusText;
    Color statusColor;
    if (weight <= 0) {
      statusText = "OUT OF STOCK";
      statusColor = theme.error;
    } else if (weight < 50) {
      statusText = "LOW STOCK";
      statusColor = theme.warning;
    } else {
      statusText = "AVAILABLE";
      statusColor = theme.success;
    }
    print('Navigating with item: ${item.inventoryName}, ${item.inventoryId}');
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
            Routes.adminViewInventory,
            arguments: item,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    height: 90,
                    color: theme.surfaceVariant,
                    child: item.urlImage != null
                        ? Image.asset(item.urlImage!, fit: BoxFit.cover)
                        : Icon(Icons.inventory_2_outlined, color: theme.primary, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.inventoryName,
                        style: TextDesign.mediumText().copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextDesign.badgeText(color: statusColor).copyWith(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
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
                        children: [
                          Text(
                            "Stock: ${weight.toStringAsFixed(1)} kg",
                            style: TextDesign.smallText().copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "RM ${price.toStringAsFixed(2)}/kg",
                            style: TextDesign.priceText(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        Routes.adminUpdateInventory,
                        arguments: item,
                      ),
                      icon: Icon(Icons.edit_note_rounded, color: theme.warning, size: 24),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
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
      ),
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
              Text("Filter by Category", style: TextDesign.headingThree()),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => Divider(color: theme.border.withOpacity(0.5)),
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
                      trailing: isSelected ? Icon(Icons.check_circle, color: theme.primary) : null,
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
                await _loadInventory(); // refresh list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
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