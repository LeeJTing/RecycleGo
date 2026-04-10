import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/inventory_controller.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/utils/async_task_runner.dart';

class AdminUpdateInventory extends StatefulWidget {
  final RecycleInventory item;

  const AdminUpdateInventory({super.key, required this.item});

  @override
  State<AdminUpdateInventory> createState() => _AdminUpdateInventoryState();
}

class _AdminUpdateInventoryState extends State<AdminUpdateInventory> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController weightController;
  late TextEditingController descController;

  bool _isUpdating = false;
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.inventoryName);
    priceController = TextEditingController(
      text: widget.item.pricePerKg.toString(),
    );
    weightController = TextEditingController(
      text: widget.item.totalWeight.toString(),
    );
    descController = TextEditingController(text: widget.item.description ?? "");
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    weightController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Update Inventory", style: TextDesign.appBarTitle()),
        centerTitle: true,
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePreview(theme),
              const SizedBox(height: 32),
              _buildLabel("Item Name"),
              TextFormField(
                controller: nameController,
                style: TextDesign.normalText(),
                decoration: _inputStyle("Item Name", theme),
                validator: (v) => v!.isEmpty ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 20),
              _buildLabel("Price per KG (RM)"),
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextDesign.mediumText().copyWith(
                  color: theme.success,
                  fontWeight: FontWeight.bold,
                ),
                decoration: _inputStyle("0.00", theme),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return "Price required";
                  final price = double.tryParse(v);
                  if (price == null) return "Invalid number";
                  if (price <= 0) return "Price must be > 0";
                  if (price > 50) return "Price too high (max RM 50)";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildLabel("Current Stock Weight (kg)"),
              TextFormField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextDesign.mediumText().copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: _inputStyle("0.0", theme).copyWith(
                  suffixText: "kg",
                  suffixStyle: TextDesign.smallText(color: theme.primary),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return "Weight is required";
                  final weight = double.tryParse(v);
                  if (weight == null) return "Must be a valid number";
                  if (weight < 0) return "Weight cannot be negative";
                  if (weight > 20) return "Weight exceeds maximum limit";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildLabel("Description"),
              TextFormField(
                controller: descController,
                maxLines: 4,
                style: TextDesign.smallText(),
                decoration: _inputStyle("Description...", theme),
              ),
              const SizedBox(height: 40),
              // ✅ Replace the old button with AsyncTaskRunner
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Update Inventory",
                    style: TextDesign.buttonText(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    await TaskRunner.run(
      context: context,
      loadingMessage: "Updating inventory...",
      successMessage: "Inventory updated successfully!",
      task: () async {
        final updatedItem = _buildUpdatedInventory();
        await InventoryController.updateInventory(updatedItem);
      },
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  RecycleInventory _buildUpdatedInventory() {
    return RecycleInventory(
      inventoryId: widget.item.inventoryId,
      inventoryName: nameController.text.trim(),
      pricePerKg: _parseDouble(priceController.text),
      totalWeight: _parseDouble(weightController.text),
      description: descController.text.trim().isEmpty
          ? null
          : descController.text.trim(),
      categoryId: widget.item.categoryId,
      urlImage: widget.item.urlImage,
    );
  }

  double _parseDouble(String value) {
    final parsed = double.tryParse(value) ?? 0.0;
    return double.parse(parsed.toStringAsFixed(2));
  }

  Widget _buildImagePreview(AppColors theme) {
    final imagePath = widget.item.urlImage;
    return Center(
      child: Stack(
        children: [
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: imagePath != null && imagePath.isNotEmpty
                    ? AssetImage(imagePath) as ImageProvider
                    : const AssetImage('assets/images/placeholder.webp'),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: theme.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: theme.primary,
              radius: 18,
              child: const Icon(Icons.edit, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: TextDesign.label()),
  );

  InputDecoration _inputStyle(String hint, AppColors theme) {
    return InputDecoration(
      filled: true,
      fillColor: theme.surface,
      hintText: hint,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.border.withOpacity(0.3)),
      ),
    );
  }
}
