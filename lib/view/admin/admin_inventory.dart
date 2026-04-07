import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import '../../app/routes.dart';

class AdminInventory extends StatefulWidget {
  const AdminInventory({super.key});

  @override
  State<AdminInventory> createState() => _AdminInventoryState();
}

class _AdminInventoryState extends State<AdminInventory> {
  // Mock data matching your Supabase 'recycleinventory' table structure
  final List<Map<String, dynamic>> _inventoryItems = [
    {
      'inventory_id': '29405d44-a4df-46b9-940b-fe69c50fcd7f',
      'inventory_name': 'Metal',
      'price_per_kg': 4.50,
      'total_weight': 120.5,
      'description': 'UBC (Used Beverage Cans) - Aluminum only. Ensure cans are crushed if possible to save space in the bin.',
      'url_image': 'assets/images/used_beverage_cans.webp',
    },
    {
      'inventory_id': '3b763107-aae6-4158-b0c6-5994e664ce4c',
      'inventory_name': 'Plastic',
      'price_per_kg': 0.85,
      'total_weight': 45.0,
      'description': 'Clear PET (Mineral water bottles). Remove caps and labels if possible for higher grade recycling quality.',
      'url_image': 'assets/images/mineral_water_bootle.webp',
    },
    {
      'inventory_id': '5db93eab-8bb8-4dd2-acc2-27aa62c16559',
      'inventory_name': 'Glasses',
      'price_per_kg': 0.15,
      'total_weight': 0.0,
      'description': 'Cullet (Crushed or whole glass bottles). Separated by color: Clear, Amber, and Green for processing.',
      'url_image': 'assets/images/cullet.webp',
    },
    {
      'inventory_id': 'bb180179-1297-4f11-ade4-8d18cf093cf2',
      'inventory_name': 'CardBoard',
      'price_per_kg': 0.55,
      'total_weight': 500.0,
      'description': 'OCC (Old Corrugated Containers/Kotak). Must be kept dry and flattened to optimize transport volume.',
      'url_image': 'assets/images/old_corrugated_containers.webp',
    },
  ];

  String _searchQuery = "";
  String _selectedCategory = "All";

  // Filter Logic
  List<Map<String, dynamic>> get _filteredItems {
    return _inventoryItems.where((item) {
      final matchesSearch = item['inventory_name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == "All" ||
          item['inventory_name'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final displayData = _filteredItems;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchHeader(theme),
          Padding(
            padding: const EdgeInsets.only(left: 28.0, top: 12.0, bottom: 8.0),
            child: Text(
              "Items",
              style: TextDesign.headingThree().copyWith(letterSpacing: 0.5),
            ),
          ),
          Expanded(
            child: displayData.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: displayData.length,
              itemBuilder: (context, index) => _buildInventoryCard(displayData[index], theme),
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

  // --- UI COMPONENTS ---

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
                style: TextDesign.normalText(),
                decoration: InputDecoration(
                  hintText: "Search items...",
                  hintStyle: TextDesign.hintText(),
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

  Widget _buildInventoryCard(Map<String, dynamic> item, AppColors theme) {
    // FIX: Safe Type Conversion for Weight and Price
    final double weight = double.tryParse(item['total_weight']?.toString() ?? '0') ?? 0.0;
    final double price = double.tryParse(item['price_per_kg']?.toString() ?? '0') ?? 0.0;

    // Status Logic
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
          onTap: () => Navigator.pushNamed(context, Routes.adminViewInventory, arguments: item),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. IMAGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90, height: 90,
                    color: theme.surfaceVariant,
                    child: item['url_image'] != null
                        ? Image.asset(item['url_image'], fit: BoxFit.cover)
                        : Icon(Icons.inventory_2_outlined, color: theme.primary, size: 30),
                  ),
                ),
                const SizedBox(width: 16),

                // 2. CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['inventory_name'] ?? "Unknown",
                          style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextDesign.badgeText(color: statusColor).copyWith(fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description (Full Display)
                      Text(item['description'] ?? "No description provided.",
                          style: TextDesign.smallText(color: theme.onSurface)),
                      const SizedBox(height: 12),

                      // Metadata
                      Wrap(
                        spacing: 12,
                        children: [
                          Text("Stock: ${weight.toStringAsFixed(1)} kg",
                              style: TextDesign.smallText().copyWith(fontWeight: FontWeight.bold)),
                          Text("RM ${price.toStringAsFixed(2)}/kg",
                              style: TextDesign.priceText(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. ACTION COLUMN
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, Routes.adminUpdateInventory, arguments: item),
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

  // --- HELPERS ---

  void _showFilterSheet(BuildContext context, AppColors theme) {
    final categories = ["All", "Plastic", "Paper", "Glasses", "CardBoard", "Metal"];
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                      title: Text(cat, style: TextDesign.mediumText(color: isSelected ? theme.primary : theme.onSurface)),
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

  void _confirmDelete(Map<String, dynamic> item, AppColors theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Remove Item?", style: TextDesign.headingThree()),
        content: Text("Are you sure you want to delete ${item['inventory_name']}? This action is permanent."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextDesign.normalText())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
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
          Text("No materials match your search", style: TextDesign.mediumText(color: theme.hint)),
        ],
      ),
    );
  }
}