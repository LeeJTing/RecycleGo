import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/category_controller.dart';
import 'package:recycle_go/models/Recycle_category.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/controller/admin/inventory_controller.dart';
import 'package:image_picker/image_picker.dart';

class AdminAddInventory extends StatefulWidget {
  const AdminAddInventory({super.key});

  @override
  State<AdminAddInventory> createState() => _AdminAddInventoryState();
}

class _AdminAddInventoryState extends State<AdminAddInventory> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descController = TextEditingController();

  RecycleCategory? selectedCategory; // Now stores the full category object
  bool _isSaving = false;

  List<RecycleCategory> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _categories = await CategoryController.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Add New Item", style: TextDesign.appBarTitle()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.surface,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePlaceholder(theme),
              const SizedBox(height: 32),

              // Category label
              _buildLabel("Category"),
              const SizedBox(height: 12),

              // Category selection
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_categories.isEmpty)
                Text(
                  "No categories available. Please add categories first.",
                  style: TextDesign.smallText(color: theme.error),
                )
              else
                _buildCategoryChips(theme),

              const SizedBox(height: 24),

              // Item Name
              _buildLabel("Item Name"),
              TextFormField(
                controller: nameController,
                style: TextDesign.normalText(),
                keyboardType: TextInputType.text,
                decoration: _inputDecoration("e.g. Aluminum Beverage Cans", theme),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter item name";
                  }
                  if (value.trim().length < 2) {
                    return "Name must be at least 2 characters";
                  }
                  return null; // valid
                },
              ),

              const SizedBox(height: 20),

              // Price per KG
              _buildLabel("Price per KG (RM)"),
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextDesign.mediumText().copyWith(
                    color: theme.success, fontWeight: FontWeight.bold),
                decoration: _inputDecoration("0.00", theme),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter price";
                  }

                  final parsed = double.tryParse(value.trim());
                  if (parsed == null) {
                    return "Enter a valid number";
                  }

                  if (parsed <= 0) {
                    return "Price must be greater than 0";
                  }

                  return null; // valid
                },
              ),
              const SizedBox(height: 20),

              // Description
              _buildLabel("Description"),
              TextFormField(
                controller: descController,
                maxLines: 3,
                style: TextDesign.smallText(color: theme.onSurface),
                decoration: _inputDecoration(
                    "Briefly describe the item properties...", theme),
              ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text("Save Item", style: TextDesign.buttonText()),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  XFile? _selectedImage; // Add this in your State class

  Widget _buildImagePlaceholder(AppColors theme) {
    return Center(
      child: GestureDetector(
        onTap: _showImageSourceSheet,
        child: Container(
          height: 140,
          width: 140,
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.border.withOpacity(0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _selectedImage != null
                ? Image.file(
              File(_selectedImage!.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 40, color: theme.primary),
                const SizedBox(height: 8),
                Text("Add Photo",
                    style: TextDesign.smallText(color: theme.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showImageSourceSheet() async {
    final picker = ImagePicker();
    final selectedSource = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black45, // semi-transparent background
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  color: Colors.white,
                  height: 140,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSourceButton(
                        icon: Icons.camera_alt_outlined,
                        label: "Camera",
                        onTap: () => Navigator.pop(context, ImageSource.camera),
                      ),
                      _buildSourceButton(
                        icon: Icons.photo_library_outlined,
                        label: "Gallery",
                        onTap: () => Navigator.pop(context, ImageSource.gallery),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selectedSource == null) return;

    try {
      final pickedFile = await picker.pickImage(
        source: selectedSource,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _selectedImage = pickedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: $e")),
      );
    }
  }

// Icon button builder
  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, size: 32, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCategoryChips(AppColors theme) {
    if (_categories.isEmpty) {
      return Text(
        "No categories available. Please add categories first.",
        style: TextDesign.smallText(color: theme.error),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: _categories.map((cat) {
        bool isSelected = selectedCategory?.categoryId == cat.categoryId;
        return ChoiceChip(
          label: Text(cat.categoryName),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() => selectedCategory = selected ? cat : null);
          },
          selectedColor: theme.primary.withOpacity(0.15),
          backgroundColor: theme.surface,
          labelStyle: TextDesign.smallText(
            color: isSelected ? theme.primary : theme.onSurface,
          ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSelected ? theme.primary : theme.border.withOpacity(0.5)),
          ),
          showCheckmark: false,
        );
      }).toList(),
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
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category first!")),
      );
      return;
    }

    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text);
    final desc = descController.text
        .trim()
        .isEmpty ? null : descController.text.trim();

    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid price!")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newItem = RecycleInventory(
      inventoryId: '',
      // auto-generated
      inventoryName: name,
      pricePerKg: price,
      totalWeight: 0.0,
      description: desc,
      categoryId: selectedCategory!.categoryId,
      urlImage: null,
    );

    try {
      await InventoryController.addInventory(newItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}