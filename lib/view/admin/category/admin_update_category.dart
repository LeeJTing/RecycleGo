import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Recycle_category.dart';

class AdminUpdateCategory extends StatefulWidget {
  final RecycleCategory category;

  const AdminUpdateCategory({super.key, required this.category});

  @override
  State<AdminUpdateCategory> createState() => _AdminUpdateCategoryState();
}

class _AdminUpdateCategoryState extends State<AdminUpdateCategory> {
  final RecycleCategoryModel _model = RecycleCategoryModel();

  final _formKey = GlobalKey<FormState>();

  final categoryController = TextEditingController();
  final descController = TextEditingController();
  final baseWeightController = TextEditingController();
  final pointController = TextEditingController();
  final densityController = TextEditingController();

  String? selectedStatus;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    categoryController.text = widget.category.categoryName;
    descController.text = widget.category.description ?? '';
    baseWeightController.text =
        widget.category.baseWeight?.toString() ?? '';
    pointController.text =
        widget.category.point?.toString() ?? '';
    densityController.text =
        widget.category.density?.toString() ?? '';

    selectedStatus = widget.category.categoryStatus ?? "active";
  }

  @override
  void dispose() {
    categoryController.dispose();
    descController.dispose();
    baseWeightController.dispose();
    pointController.dispose();
    densityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Edit Category", style: TextDesign.appBarTitle()),
        backgroundColor: theme.onPrimary,
        elevation: 0,
        centerTitle: true,
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
              // --- SECTION: IDENTITY ---
              _buildSectionTitle("General Information", theme),
              const SizedBox(height: 16),
              _buildCustomTextField(
                label: "CATEGORY NAME",
                controller: categoryController,
                hint: "e.g. Plastic",
                icon: Icons.label_important_outline,
                theme: theme,
              ),
              const SizedBox(height: 20),

              // --- SECTION: STATUS ---
              _buildLabel("CURRENT STATUS"),
              const SizedBox(height: 8),
              _buildStatusDropdown(theme),

              const SizedBox(height: 32),

              // --- SECTION: CALCULATIONS (Grouped) ---
              _buildSectionTitle("Measurement Metrics", theme),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCustomTextField(
                      label: "POINTS",
                      controller: pointController,
                      hint: "0.0",
                      keyboardType: TextInputType.number,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCustomTextField(
                      label: "DENSITY",
                      controller: densityController,
                      hint: "0.5",
                      keyboardType: TextInputType.number,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildCustomTextField(
                label: "BASE WEIGHT (KG)",
                controller: baseWeightController,
                hint: "1.0",
                keyboardType: TextInputType.number,
                theme: theme,
              ),

              const SizedBox(height: 32),

              // --- SECTION: DESCRIPTION ---
              _buildSectionTitle("Additional Details",theme),
              const SizedBox(height: 16),
              _buildCustomTextField(
                label: "DESCRIPTION",
                controller: descController,
                hint: "Optional category notes...",
                maxLines: 3,
                theme: theme,
              ),

              const SizedBox(height: 48),

              // --- ACTION BUTTON ---
              _buildUpdateButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton(AppColors theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _updateCategory,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // Style when button is disabled (during saving)
          disabledBackgroundColor: theme.primary.withOpacity(0.5),
        ),
        child: _isSaving
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : Text(
          "SAVE CHANGES",
          style: TextDesign.buttonText(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColors theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        title,
        style: TextDesign.sectionHeader(color: theme.primary),
      ),
    );
  }

  Widget _buildStatusDropdown(AppColors theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: selectedStatus,
          style: TextDesign.mediumText(),
          decoration: const InputDecoration(border: InputBorder.none),
          items: ["active", "inactive"]
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e.toUpperCase(), style: TextStyle(
              color: e == 'active' ? theme.success : theme.error,
              fontWeight: FontWeight.bold,
            )),
          ))
              .toList(),
          onChanged: (value) => setState(() => selectedStatus = value),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required AppColors theme,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
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
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: theme.primary, size: 20) : null,
            hintText: hint,
            hintStyle: TextDesign.hintText(),
            filled: true,
            fillColor: theme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextDesign.label());
  }

  InputDecoration _inputDecoration(String hint, AppColors theme) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: theme.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _updateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedData = {
      'category_name': categoryController.text.trim(),
      'description': descController.text.trim().isEmpty
          ? null
          : descController.text.trim(),
      'point': double.tryParse(pointController.text),
      'base_weight': double.tryParse(baseWeightController.text),
      'density': double.tryParse(densityController.text),
      'category_status': selectedStatus,
    };

    setState(() => _isSaving = true);

    try {

      await _model.updateCategory(widget.category.categoryId, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category updated successfully")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}