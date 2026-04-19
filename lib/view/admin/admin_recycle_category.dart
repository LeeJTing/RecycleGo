import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

// IMPORTANT: Make sure this path matches where your model actually is!
import '../../models/Recycle_category.dart';

class AdminRecycleCategory extends StatefulWidget {
  const AdminRecycleCategory({super.key});

  @override
  State<AdminRecycleCategory> createState() => _AdminRecycleCategoryState();
}

class _AdminRecycleCategoryState extends State<AdminRecycleCategory> {
  // 1. Replaced the mock map with your actual Model
  List<RecycleCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch real data on load
  }

  // --- DATABASE LOGIC ---

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      // Fetch and order by ID
      final response = await supabase.from('recycle_category').select().order('category_id');

      setState(() {
        _categories = response.map((e) => RecycleCategory.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching categories: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load categories: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCategory(RecycleCategory category) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('recycle_category').delete().eq('category_id', category.categoryId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category deleted.")));
      }
      _fetchCategories(); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot delete: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.onSurface, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Manage Categories", style: TextDesign.appBarTitle()),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Text(
              "Define core material categories, AI labels, and base points.",
              style: TextDesign.normalText(color: theme.hint),
              textAlign: TextAlign.center,
            ),
          ),

          // --- CATEGORY LIST ---
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: theme.primary))
                : _categories.isEmpty
                ? Center(child: Text("No categories found.", style: TextDesign.normalText()))
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildCategoryCard(_categories[index], theme);
              },
            ),
          ),

          // --- BOTTOM ACTION AREA ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => _showCategoryFormDialog(context, theme, null), // null means "Add New"
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

  Widget _buildCategoryCard(RecycleCategory category, AppColors theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  "#${category.categoryId}",
                  style: TextDesign.mediumText(color: theme.primary).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.categoryName, style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  // Display extra DB info nicely
                  Text(
                    "Pts: ${category.point ?? '-'} | Label: ${category.label ?? 'None'}",
                    style: TextDesign.smallText(color: theme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.description ?? "No description.",
                    style: TextDesign.smallText(color: theme.hint),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: theme.warning, size: 22),
                  // Pass the existing category to edit it!
                  onPressed: () => _showCategoryFormDialog(context, theme, category),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.error, size: 22),
                  onPressed: () => _confirmDelete(category, theme),
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

  void _confirmDelete(RecycleCategory category, AppColors theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Category?", style: TextDesign.headingThree()),
        content: Text("Are you sure you want to delete '${category.categoryName}'? This may affect inventory items tied to this category."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextDesign.normalText()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category);
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.error),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- ADD / EDIT FORM ---

  void _showCategoryFormDialog(BuildContext context, AppColors theme, RecycleCategory? existingCategory) {
    final bool isEdit = existingCategory != null;

    // Setup controllers with existing data if Editing
    final nameCtrl = TextEditingController(text: isEdit ? existingCategory.categoryName : '');
    final descCtrl = TextEditingController(text: isEdit ? existingCategory.description : '');
    final pointCtrl = TextEditingController(text: isEdit ? existingCategory.point?.toString() : '');
    final baseWeightCtrl = TextEditingController(text: isEdit ? existingCategory.baseWeight?.toString() : '');
    final densityCtrl = TextEditingController(text: isEdit ? existingCategory.density?.toString() : '');
    final labelCtrl = TextEditingController(text: isEdit ? existingCategory.label : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? "Edit Category" : "New Category", style: TextDesign.headingThree()),
                const SizedBox(height: 20),

                // Name & Label
                Row(
                  children: [
                    Expanded(child: _buildTextField(nameCtrl, "Category Name *")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(labelCtrl, "AI Label (Optional)")),
                  ],
                ),
                const SizedBox(height: 16),

                // Numbers Row
                Row(
                  children: [
                    Expanded(child: _buildTextField(pointCtrl, "Points", isNum: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(baseWeightCtrl, "Base Weight", isNum: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(densityCtrl, "Density", isNum: true)),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                _buildTextField(descCtrl, "Description (Optional)", maxLines: 2),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return; // Prevent empty names

                      final supabase = Supabase.instance.client;

                      // Build the data payload
                      final payload = {
                        'category_name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        'label': labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
                        'point': double.tryParse(pointCtrl.text.trim()),
                        'base_weight': double.tryParse(baseWeightCtrl.text.trim()),
                        'density': double.tryParse(densityCtrl.text.trim()),
                      };

                      try {
                        if (isEdit) {
                          // Update existing
                          await supabase.from('recycle_category').update(payload).eq('category_id', existingCategory.categoryId);
                        } else {
                          // Insert new (Do not send category_id, it is Auto-Generated)
                          await supabase.from('recycle_category').insert(payload);
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          _fetchCategories(); // Refresh list after saving
                        }
                      } catch (e) {
                        print("Save Error: $e");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      }
                    },
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
          ),
        );
      },
    );
  }

  // Helper widget for text fields in the bottom sheet
  Widget _buildTextField(TextEditingController controller, String label, {bool isNum = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}