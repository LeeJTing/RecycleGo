import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import '../../controller/admin/category_controller.dart';

class AdminRecycleCategory extends StatefulWidget {
  const AdminRecycleCategory({super.key});

  @override
  State<AdminRecycleCategory> createState() => _AdminRecycleCategoryState();
}
// Navigator.push(
// context,
// MaterialPageRoute(
// builder: (context) => const AdminRecycleCategory(),
// fullscreenDialog: true,
// ),
// )
class _AdminRecycleCategoryState extends State<AdminRecycleCategory> {
  final CategoryController _controller = CategoryController();

  @override
  void initState() {
    super.initState();
    // 2. Tell the controller to fetch data when screen loads
    //_controller.fetchCategories();
  }

  @override
  void dispose() {
    //_controller.dispose(); // Clean up memory
    super.dispose();
  }

  // Mock data representing your public.recycle_category table
  final List<Map<String, dynamic>> _categories = [
    {'category_id': 1, 'category_name': 'Plastic', 'description': 'PET, HDPE, and PVC plastics.'},
    {'category_id': 2, 'category_name': 'Paper', 'description': 'Newspapers, magazines, and office paper.'},
    {'category_id': 3, 'category_name': 'Glasses', 'description': 'Clear, amber, and green glass bottles.'},
    {'category_id': 4, 'category_name': 'CardBoard', 'description': 'Corrugated boxes and flat cardboard.'},
    {'category_id': 5, 'category_name': 'Metal', 'description': 'Aluminum cans, steel, and tin.'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background, // A slightly off-white or light grey background
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        // The framework automatically provides an 'X' close button if pushed as a fullscreen dialog,
        // but we explicitly define it here for clarity and custom styling.
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.onSurface, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Manage Categories", style: TextDesign.appBarTitle()),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- 1. HEADER EXPLANATION ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Text(
              "Define the core material categories used to classify inventory and user submissions.",
              style: TextDesign.normalText(color: theme.hint),
              textAlign: TextAlign.center,
            ),
          ),

          // --- 2. CATEGORY LIST ---
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryCard(category, theme);
              },
            ),
          ),

          // --- 3. BOTTOM ACTION AREA (Add Category) ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddCategoryDialog(context, theme),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  label: Text("Create New Category", style: TextDesign.buttonText()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildCategoryCard(Map<String, dynamic> category, AppColors theme) {
    final String name = category['category_name']?.toString() ?? "Unknown";
    final String desc = category['description']?.toString() ?? "No description.";
    final String id = category['category_id']?.toString() ?? "-";

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // CATEGORY ICON / BADGE
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  "#$id",
                  style: TextDesign.mediumText(color: theme.primary).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextDesign.smallText(color: theme.hint),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ACTIONS (Edit & Delete)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: theme.warning, size: 22),
                  onPressed: () {
                    // Navigate to Edit screen or show Edit Dialog
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.error, size: 22),
                  onPressed: () => _confirmDelete(name, theme),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  void _confirmDelete(String categoryName, AppColors theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Category?", style: TextDesign.headingThree()),
        content: Text("Are you sure you want to delete '$categoryName'? This may affect inventory items tied to this category."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextDesign.normalText()),
          ),
          ElevatedButton(
            onPressed: () {
              // Perform Supabase Delete
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.error),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Avoid keyboard
            left: 24, right: 24, top: 24,
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
