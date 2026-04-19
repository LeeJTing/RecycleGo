import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/utils/validators.dart';
import '../../../controller/admin/category_controller.dart';
import '../../../models/Recycle_category.dart';
import '../../../provider/CategoryProvider.dart';

class AdminAddCategory extends StatefulWidget {
  const AdminAddCategory({super.key});

  @override
  State<AdminAddCategory> createState() => _AdminAddCategoryState();
}

class _AdminAddCategoryState extends State<AdminAddCategory> {
  final CategoryController _controller = CategoryController();
  final _formKey = GlobalKey<FormState>();

  // Controllers matching your SQL Table
  final _nameController = TextEditingController();
  final _labelController = TextEditingController();
  final _descController = TextEditingController();
  final _pointController = TextEditingController();
  final _weightController = TextEditingController(text: "1.0");
  final _densityController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _labelController.dispose();
    _descController.dispose();
    _pointController.dispose();
    _weightController.dispose();
    _densityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("New Recycling Category", style: TextDesign.appBarTitle()),
        backgroundColor: theme.onPrimary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Identification", theme),
                  const SizedBox(height: 16),

                  _buildTextField(
                    label: "CATEGORY NAME",
                    hint: "e.g., Plastic Bottles",
                    controller: _nameController,
                    theme: theme,
                    validator: Validators.requiredText,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: "UNIQUE LABEL (System ID)",
                    hint: "e.g., PET_001",
                    controller: _labelController,
                    theme: theme,
                    validator: Validators.requiredText,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader("Measurement & Value", theme),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: "POINTS/KG",
                          hint: "5.0",
                          controller: _pointController,
                          keyboardType: TextInputType.number,
                          theme: theme,
                          validator: Validators.requiredNumber,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          label: "DENSITY",
                          hint: "Optional",
                          controller: _densityController,
                          keyboardType: TextInputType.number,
                          theme: theme,
                          validator: Validators.optionalNumber,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader("Description", theme),
                  const SizedBox(height: 16),

                  _buildTextField(
                    label: "NOTES",
                    hint: "Describe collection rules...",
                    controller: _descController,
                    maxLines: 3,
                    theme: theme,
                  ),

                  const SizedBox(height: 48),

                  _buildSubmitButton(theme),
                ],
              ),
            ),
          ),
          if (_isSaving) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors theme) {
    return Text(title, style: TextDesign.sectionHeader(color: theme.primary));
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required AppColors theme,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextDesign.label()),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextDesign.normalText(),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextDesign.hintText(),
            filled: true,
            fillColor: theme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AppColors theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text("ACTIVATE CATEGORY", style: TextDesign.buttonText()),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 1. Build the base object from the text fields
      final newCategory = RecycleCategory(
        categoryId: 0,
        // 0 because Supabase will auto-generate the real ID
        categoryName: _nameController.text.trim(),
        label: _labelController.text.trim().toUpperCase(),
        description: _descController.text.trim(),
        point: double.tryParse(_pointController.text.trim()) ?? 0.0,
        baseWeight: double.tryParse(_weightController.text.trim()) ?? 1.0,
        density: double.tryParse(_densityController.text.trim()),
        categoryStatus: 'active'
        // Notice we don't even need to mention status here!
      );

      // 2. Pass it to your Provider (which will use copyWith to add the status)
      await context.read<CategoryProvider>().addCategory(newCategory);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Category Added!")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
