import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Recycle_category.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/controller/admin/category_controller.dart';
import 'package:recycle_go/controller/admin/inventory_controller.dart';
import 'package:uuid/uuid.dart';

class AdminAddInventory extends StatefulWidget {
  const AdminAddInventory({super.key});

  @override
  State<AdminAddInventory> createState() => _AdminAddInventoryState();
}

class _AdminAddInventoryState extends State<AdminAddInventory> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _weightController = TextEditingController();
  final _minWeightController = TextEditingController();

  // State Variables
  String _selectedStatus = 'active';
  int? _selectedCategoryId;

  List<RecycleCategory> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  XFile? _selectedImage;

  late final CategoryController _categoryController;

  @override
  void initState() {
    super.initState();
    _categoryController = CategoryController();
    _fetchCategories();
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

  Future<void> _fetchCategories() async {
    try {
      await _categoryController.fetchCategories();
      setState(() {
        _categories = _categoryController.categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      print("Error fetching categories: $e");
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Add New Inventory", style: TextDesign.appBarTitle()),
        backgroundColor: theme.surface,
        elevation: 0,
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
              _buildImagePlaceholder(theme),
              const SizedBox(height: 32),

              // ✨ REUSABLE INPUTS ✨
              _buildInputField(
                theme: theme,
                label: "Item Name",
                hint: "e.g. Aluminum Beverage Cans",
                controller: _nameController,
                validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
              ),

              // Category Dropdown
              _buildLabel("Category"),
              if (_isLoadingCategories)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: _inputDecoration("Select a category", theme),
                  items: _categories.map((cat) => DropdownMenuItem(value: cat.categoryId, child: Text(cat.categoryName))).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  validator: (val) => val == null ? "Please select a category" : null,
                ),
              const SizedBox(height: 20),

              // Two-Column Layout
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
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
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
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
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
              ),

              // Status Dropdown
              _buildLabel("Status"),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: _inputDecoration("Select status", theme),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text("Active (Visible)")),
                  DropdownMenuItem(value: 'inactive', child: Text("Inactive (Hidden)")),
                ],
                onChanged: (val) => setState(() => _selectedStatus = val!),
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

              // Submit Button
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("ADD INVENTORY ITEM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ✨ REUSABLE UI WIDGETS ✨
  // ==========================================

  // The new Master Input Builder!
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
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))] : null,
            style: TextStyle(color: textColor ?? theme.onSurface, fontWeight: textColor != null ? FontWeight.bold : FontWeight.normal),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border.withOpacity(0.3))),
    );
  }

  Widget _buildImagePlaceholder(AppColors theme) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 140, width: 140,
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.border.withOpacity(0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _selectedImage != null
                ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 40, color: theme.primary),
                const SizedBox(height: 8),
                Text("Upload Image", style: TextStyle(color: theme.primary, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LOGIC & SUPABASE FUNCTIONS
  // ==========================================

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) setState(() => _selectedImage = pickedFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to pick image: $e")));
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'inventory_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final supabase = Supabase.instance.client;

      // Added FileOptions for safety
      await supabase.storage.from('inventory-images').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      return supabase.storage.from('inventory-images').getPublicUrl(fileName);
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  String _generateCode(String name) {
    final prefix = name.length >= 3
        ? name.substring(0, 3).toUpperCase()
        : name.toUpperCase();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final short = timestamp.toString().substring(0, 3);

    return "$prefix-$short";
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category")),
      );
      return;
    }

    setState(() => _isSaving = true);
    String? imageUrl;

    try {
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(File(_selectedImage!.path));
        if (imageUrl == null) throw Exception("Image upload failed.");
      }

      final inventoryCode = _generateCode(_nameController.text.trim());
      final inventoryId = const Uuid().v4();
      final newItem = RecycleInventory(
        inventoryId: inventoryId,
        inventoryCode: inventoryCode,
        inventoryName: _nameController.text.trim(),
        pricePerKg: double.parse(_priceController.text.trim()),
        totalWeightAvailable: double.parse(_weightController.text.trim()),
        status: _selectedStatus == 'active' ? InventoryStatus.active : InventoryStatus.inactive,
        categoryId: _selectedCategoryId!,
        imgPath: imageUrl ?? '',
        description: _descController.text.trim().isEmpty ? '' : _descController.text.trim(),
        minWeightLevel: double.tryParse(_minWeightController.text.trim()),
      );

      await InventoryController.addInventory(newItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inventory added successfully!")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}