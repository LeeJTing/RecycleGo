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
  String _selectedStatus = 'active'; // Default to active
  int? _selectedCategoryId;

  List<RecycleCategory> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
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

  // --- 1. FETCH CATEGORIES FROM DB ---
  Future<void> _fetchCategories() async {
    try {
      final fetchedCategories = await CategoryController.getCategories();
      setState(() {
        _categories = fetchedCategories;
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
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- IMAGE UPLOADER ---
              _buildImagePlaceholder(theme),
              const SizedBox(height: 32),

              // --- ITEM NAME ---
              _buildLabel("Item Name"),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration("e.g. Aluminum Beverage Cans", theme),
                validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 20),

              // --- CATEGORY DROPDOWN ---
              _buildLabel("Category"),
              if (_isLoadingCategories)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: _inputDecoration("Select a category", theme),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<int>(
                      value: cat.categoryId,
                      child: Text(cat.categoryName),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  validator: (val) => val == null ? "Please select a category" : null,
                ),
              const SizedBox(height: 20),

              // --- TWO-COLUMN LAYOUT FOR NUMBERS ---
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Price per KG (RM)"),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          decoration: _inputDecoration("0.00", theme),
                          style: TextStyle(color: theme.success, fontWeight: FontWeight.bold),
                          validator: (val) => val == null || val.isEmpty ? "Required" : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Current Stock (kg)"),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDecoration("0.0", theme),
                          validator: (val) => val == null || val.isEmpty ? "Required" : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- LOW STOCK WARNING LEVEL ---
              _buildLabel("Low Stock Warning Level (kg)"),
              TextFormField(
                controller: _minWeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration("e.g. 50.0", theme),
              ),
              const SizedBox(height: 20),

              // --- STATUS DROPDOWN ---
              _buildLabel("Initial Status"),
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

              // --- DESCRIPTION ---
              _buildLabel("Description"),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: _inputDecoration("Briefly describe this item...", theme),
              ),
              const SizedBox(height: 40),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("ADD INVENTORY ITEM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

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

  // --- LOGIC FUNCTIONS ---

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _selectedImage = pickedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to pick image: $e")));
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'inventory_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final supabase = Supabase.instance.client;

      // Ensure you have a bucket named 'inventory-images' in Supabase!
      await supabase.storage.from('inventory-images').upload(fileName, imageFile);
      return supabase.storage.from('inventory-images').getPublicUrl(fileName);
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    String? imageUrl;

    try {
      // 1. Upload Image (If selected)
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(File(_selectedImage!.path));
        if (imageUrl == null) throw Exception("Failed to upload image. Check Supabase storage bucket.");
      }

      // 2. Build the new Inventory Object
      final newItem = RecycleInventory(
        inventoryName: _nameController.text.trim(),
        pricePerKg: double.parse(_priceController.text.trim()),
        totalWeightAvailable: double.parse(_weightController.text.trim()),
        minWeightLevel: double.tryParse(_minWeightController.text.trim()),
        status: _selectedStatus,
        categoryId: _selectedCategoryId,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        imgPath: imageUrl, inventoryId: '',
      );

      // 3. Save to database using the Controller
      await InventoryController.addInventory(newItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inventory added successfully!")));
        Navigator.pop(context, true); // Return true so the list page knows to refresh
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}