import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/category_controller.dart';
import 'package:recycle_go/models/Recycle_category.dart';

class AdminAddCategory extends StatefulWidget {
  const AdminAddCategory({super.key});

  @override
  State<AdminAddCategory> createState() => _AdminAddCategoryState();
}

class _AdminAddCategoryState extends State<AdminAddCategory> {
  final _formKey = GlobalKey<FormState>();
  final categoryController = TextEditingController();
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final baseWeightController = TextEditingController();
  final pointController = TextEditingController();

  RecycleCategory? selectedCategory;
  bool _isSaving = false;

  List<RecycleCategory> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    baseWeightController.dispose();
    pointController.dispose();
    nameController.dispose();
    descController.dispose();
    categoryController.dispose();
    super.dispose();
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
        title: Text("Add New Category", style: TextDesign.appBarTitle()),
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
              // Category label
              _buildLabel("Category"),
              const SizedBox(height: 12),

              // Category selection
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildLabel("Category Name"),

              TextFormField(
                controller: categoryController,
                style: TextDesign.normalText(),
                keyboardType: TextInputType.text,
                decoration: _inputDecoration("e.g. Plastic, Metal, Paper", theme),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter category name";
                  }
                  if (value.trim().length < 2) {
                    return "Name must be at least 2 characters";
                  }
                  return null;
                },
              ),

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
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _buildLabel("Point"),
              TextFormField(
                controller: pointController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextDesign.mediumText().copyWith(color: theme.primary),
                decoration: _inputDecoration("0.0", theme),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter point";
                  }

                  final parsed = double.tryParse(value.trim());
                  if (parsed == null) return "Invalid number";
                  if (parsed < 0) return "Cannot be negative";

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description
              _buildLabel("Description"),
              TextFormField(
                controller: descController,
                maxLines: 3,
                style: TextDesign.smallText(color: theme.onSurface),
                decoration: _inputDecoration("Briefly describe the item properties...", theme),
              ),

              const SizedBox(height: 40),

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
                  child: Text("Add Category", style: TextDesign.buttonText()),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 16.0),
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

    final categoryName = categoryController.text.trim();
    final name = nameController.text.trim(); // (Note: this isn't mapped to RecycleCategory currently)
    final desc = descController.text.trim().isEmpty ? null : descController.text.trim();

    final baseWeight = double.tryParse(baseWeightController.text) ?? 1.0;

    final point = double.tryParse(pointController.text);

    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid point value")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newCategory = RecycleCategory(
      categoryId: 0, // auto-generated by DB
      categoryName: categoryName,
      description: desc,
      baseWeight: baseWeight,
      point: point,
    );

    try {
      await CategoryController.addCategory(newCategory);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add category: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}