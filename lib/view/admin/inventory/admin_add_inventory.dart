import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Recycle_category.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/controller/admin/inventory_controller.dart';
import '../../../provider/CategoryProvider.dart';

class AdminAddInventory extends StatefulWidget {
  const AdminAddInventory({super.key});

  @override
  State<AdminAddInventory> createState() => _AdminAddInventoryState();
}

class _AdminAddInventoryState extends State<AdminAddInventory> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _weightController = TextEditingController();
  final _minWeightController = TextEditingController();

  String _selectedStatus = 'active';
  int? _selectedCategoryId;
  bool _isSaving = false;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
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
    if (val == null || val.trim().isEmpty) return null;
    final number = double.tryParse(val.trim());
    if (number == null) return "Invalid number";
    if (number < 0) return "Cannot be negative";
    return null;
  }

  bool isValidInventoryName(String name) {
    final regex = RegExp(r'^[a-zA-Z0-9\s\-/()]+$');
    return regex.hasMatch(name);
  }

  String? _validateInventoryName(String? val) {
    if (val == null || val.trim().isEmpty) {
      return "Item name is required";
    }

    if (!isValidInventoryName(val.trim())) {
      return "Only letters, numbers, spaces, -, /, (), & + allowed";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final categoryProvider = context.watch<CategoryProvider>();

    // Get screen width for adaptive padding
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 32.0 : 20.0;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Add New Inventory", style: TextDesign.appBarTitle()),
        backgroundColor: theme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      // SafeArea prevents clipping on notches and dynamic islands
      body: SafeArea(
        child: _isSaving
            ? Center(child: CircularProgressIndicator(color: theme.primary))
            : Center(
                // ConstrainedBox prevents the form from stretching too wide on iPads/Tablets
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24.0,
                      horizontalPadding,
                      40.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImagePlaceholder(theme),
                          const SizedBox(height: 32),

                          _buildInputField(
                            theme: theme,
                            label: "Item Name",
                            hint: "e.g. Aluminum Beverage Cans",
                            controller: _nameController,
                            validator: _validateInventoryName,
                          ),

                          _buildLabel("Category"),
                          if (categoryProvider.isLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              decoration: _inputDecoration(
                                "Select a category",
                                theme,
                              ),
                              items: categoryProvider.categories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat.categoryId,
                                      child: Text(cat.categoryName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedCategoryId = val),
                              validator: (val) => val == null
                                  ? "Please select a category"
                                  : null,
                            ),
                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  theme: theme,
                                  label: "Price/KG (RM)",
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
                                  label: "Stock (kg)",
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
                            decoration: _inputDecoration(
                              "Select status",
                              theme,
                            ),
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
                          const SizedBox(height: 32),

                          // Standardized full-width button
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                55,
                              ), // Adapts perfectly to parent width
                              backgroundColor: theme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "ADD INVENTORY ITEM",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ==========================================
  // REUSABLE UI WIDGETS
  // ==========================================

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
              fontWeight: textColor != null
                  ? FontWeight.bold
                  : FontWeight.normal,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.error, width: 2),
      ),
    );
  }

  Widget _buildImagePlaceholder(AppColors theme) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 140,
          width: 140,
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: theme.onBackground.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _selectedImage != null
                ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: theme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Upload Image",
                        style: TextStyle(
                          color: theme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LOGIC
  // ==========================================

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) setState(() => _selectedImage = pickedFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to pick image: $e")));
      }
    }
  }

  Future<void> _submitForm() async {
    // 1. Initial UI Validation
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category.")),
      );
      return;
    }

    // ✨ NEW: Ensure an image is selected before proceeding
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload an image for this item.")),
      );
      return;
    }

    // Extract and validate text
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item name cannot be empty.")),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid price detected.")));
      return;
    }

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid weight detected.")));
      return;
    }

    double? minWeight;
    final minWeightText = _minWeightController.text.trim();
    if (minWeightText.isNotEmpty) {
      minWeight = double.tryParse(minWeightText);
      if (minWeight == null || minWeight < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid minimum weight detected.")),
        );
        return;
      }
    }

    // Validation passed! Start the loading state.
    setState(() => _isSaving = true);
    String? imageUrl;

    try {
      // ✨ NEW: Check for duplicate inventory names BEFORE uploading the image
      final existingItems = await InventoryController.getInventory();
      final isDuplicate = existingItems.any(
        (item) => item.inventoryName.trim().toLowerCase() == name.toLowerCase(),
      );

      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("An inventory item with this name already exists!"),
              backgroundColor: Colors.red,
            ),
          );
        }
        // Stop the process and turn off the loader
        setState(() => _isSaving = false);
        return;
      }

      // Phase 1: Upload the file (We now know _selectedImage is definitely not null)
      imageUrl = await InventoryController.uploadImage(
        File(_selectedImage!.path),
      );
      if (imageUrl == null) throw Exception("Image upload failed.");

      final inventoryCode = InventoryController.generateCode(name);

      final newItem = RecycleInventory(
        inventoryId: const Uuid().v4(),
        inventoryCode: inventoryCode,
        inventoryName: name,
        pricePerKg: price,
        totalWeightAvailable: weight,
        status: _selectedStatus == 'active'
            ? InventoryStatus.active
            : InventoryStatus.inactive,
        categoryId: _selectedCategoryId!,
        imgPath: imageUrl, // Safe to use directly since we enforced it above
        description: _descController.text.trim(),
        minWeightLevel: minWeight,
      );

      // Phase 2: Insert into database
      await InventoryController.addInventory(newItem);

      // If we reach here, the entire transaction was a success!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inventory added successfully!")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      // TRANSACTION ROLLBACK
      if (imageUrl != null) {
        debugPrint(
          "Database insert failed. Consider deleting orphaned image at: $imageUrl",
        );
        // await InventoryController.deleteImage(imageUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
