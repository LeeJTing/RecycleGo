import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/inventory_controller.dart';
import 'package:recycle_go/models/RecycleInventory.dart';

import '../../../provider/CategoryProvider.dart';

class AdminUpdateInventory extends StatefulWidget {
  final RecycleInventory item;

  const AdminUpdateInventory({super.key, required this.item});

  @override
  State<AdminUpdateInventory> createState() => _AdminUpdateInventoryState();
}

class _AdminUpdateInventoryState extends State<AdminUpdateInventory> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _weightController;
  late final TextEditingController _minWeightController;

  String _selectedStatus = 'active';
  int? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });

    _nameController = TextEditingController(text: widget.item.inventoryName);
    _descController = TextEditingController(text: widget.item.description);
    _priceController =
        TextEditingController(text: widget.item.pricePerKg.toStringAsFixed(2));
    _weightController =
        TextEditingController(text: widget.item.totalWeightAvailable.toStringAsFixed(1));
    _minWeightController =
        TextEditingController(text: widget.item.minWeightLevel?.toStringAsFixed(1) ?? '');

    _selectedStatus = widget.item.status.name;
    _selectedCategoryId = widget.item.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    _minWeightController.dispose();
    super.dispose();
  }

  // --- ENHANCED VALIDATORS ---
  String? _validateRequiredText(String? val) {
    if (val == null || val.trim().isEmpty) return "This field is required";
    return null;
  }

  String? _validateNumber(String? val) {
    if (val == null || val.trim().isEmpty) return "Required";
    final number = double.tryParse(val.trim());
    if (number == null) return "Invalid number";
    if (number < 0) return "Cannot be negative";
    return null;
  }

  String? _validateOptionalNumber(String? val) {
    if (val == null || val.trim().isEmpty) return null; // Optional
    final number = double.tryParse(val.trim());
    if (number == null) return "Invalid number";
    if (number < 0) return "Cannot be negative";
    return null;
  }

  Future<void> _updateInventory() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Safe Parsing
      final price = double.tryParse(_priceController.text.trim()) ?? widget.item.pricePerKg;
      final weight = double.tryParse(_weightController.text.trim()) ?? widget.item.totalWeightAvailable;
      final minWeight = double.tryParse(_minWeightController.text.trim());

      final updatedItem = widget.item.copyWith(
        inventoryName: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? ''
            : _descController.text.trim(),
        pricePerKg: price,
        totalWeightAvailable: weight,
        minWeightLevel: minWeight,
        status: _selectedStatus == 'active'
            ? InventoryStatus.active
            : InventoryStatus.inactive,
        categoryId: _selectedCategoryId!,
        updatedAt: DateTime.now(),
      );

      await InventoryController.updateInventory(updatedItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inventory updated successfully!")),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final provider = context.watch<CategoryProvider>();
    final categories = provider.categories;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Edit Inventory", style: TextDesign.appBarTitle()),
        backgroundColor: theme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, theme),
          ),
        ],
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePreview(theme),
              const SizedBox(height: 24),

              _buildInputField(
                theme: theme,
                label: "Item Name",
                hint: "e.g. Aluminum Beverage Cans",
                controller: _nameController,
                validator: _validateRequiredText,
              ),

              _buildLabel("Category"),

              provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: _inputDecoration("Select a category", theme),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.categoryId,
                    child: Text(cat.categoryName),
                  );
                }).toList(),
                onChanged: (val) =>
                    setState(() => _selectedCategoryId = val),
                validator: (val) =>
                val == null ? "Please select a category" : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      theme: theme,
                      label: "Price per KG (RM)",
                      hint: "0.00",
                      controller: _priceController,
                      isNumber: true,
                      textColor: theme.success,
                      validator: _validateNumber,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      theme: theme,
                      label: "Current Stock (kg)",
                      hint: "0.0",
                      controller: _weightController,
                      isNumber: true,
                      validator: _validateNumber,
                    ),
                  ),
                ],
              ),

              _buildInputField(
                theme: theme,
                label: "Low Stock Warning Level (kg)",
                hint: "e.g. 50.0",
                controller: _minWeightController,
                isNumber: true,
                validator: _validateOptionalNumber,
              ),

              _buildLabel("Status"),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: _inputDecoration("Select status", theme),
                items: const [
                  DropdownMenuItem(
                    value: 'active',
                    child: Text("Active (Visible)"),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text("Inactive (Hidden)"),
                  ),
                ],
                onChanged: (val) =>
                    setState(() => _selectedStatus = val!),
              ),
              const SizedBox(height: 20),

              _buildInputField(
                theme: theme,
                label: "Description",
                hint: "Briefly describe this item...",
                controller: _descController,
                maxLines: 3,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _updateInventory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "UPDATE INVENTORY",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI Helpers  ----------
  Widget _buildImagePreview(AppColors theme) {
    final imgPath = widget.item.imgPath;
    final hasImage = imgPath.isNotEmpty;

    return Center(
      child: Container(
        height: 140,
        width: 140,
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.border.withOpacity(0.5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: hasImage
              ? (imgPath.startsWith('http')
              ? Image.network(imgPath, fit: BoxFit.cover)
              : Image.asset('assets/images/$imgPath', fit: BoxFit.cover))
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined,
                  color: theme.primary, size: 40),
              const SizedBox(height: 8),
              Text("No Image", style: TextStyle(color: theme.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required AppColors theme,
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isNumber = false,
    int maxLines = 1,
    Color? textColor,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: isNumber
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
                : null,
            style: TextStyle(
              color: textColor ?? theme.onSurface,
              fontWeight: textColor != null ? FontWeight.bold : FontWeight.normal,
            ),
            decoration: _inputDecoration(hint, theme),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(text, style: TextDesign.label()),
    );
  }

  InputDecoration _inputDecoration(String hint, AppColors theme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextDesign.hintText(),
      filled: true,
      fillColor: theme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.border.withOpacity(0.3)),
      ),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.error, width: 2)),
    );
  }

  // Optional delete confirmation
  void _confirmDelete(BuildContext context, AppColors theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Inventory"),
        content: Text(
          "Are you sure you want to delete '${widget.item.inventoryName}'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSaving = true);
              try {
                await InventoryController.deleteInventory(widget.item.inventoryId!); // Added ! to assert not null
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Deleted successfully")),
                  );
                  Navigator.pop(context, true); // back to list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Delete failed: $e")),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}