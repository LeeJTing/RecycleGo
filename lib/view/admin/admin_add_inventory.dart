import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class AdminAddInventory extends StatefulWidget {
  const AdminAddInventory({super.key});

  @override
  State<AdminAddInventory> createState() => _AdminAddInventoryState();
}

class _AdminAddInventoryState extends State<AdminAddInventory> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descController = TextEditingController();

  // Selection States
  String? selectedCategory;
  final List<String> categories = ["Plastic", "Paper", "Glasses", "CardBoard", "Metal"];

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descController.dispose();
    super.dispose();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. PHOTO UPLOADER ---
              _buildImagePlaceholder(theme),
              const SizedBox(height: 32),

              // --- 2. CATEGORY SELECTION (Belonging to which category) ---
              _buildLabel("Category"),
              const SizedBox(height: 12),
              _buildCategoryChips(theme),
              const SizedBox(height: 24),

              // --- 3. ITEM NAME ---
              _buildLabel("Item Name"),
              TextFormField(
                controller: nameController,
                style: TextDesign.normalText(),
                decoration: _inputDecoration("e.g. Aluminum Beverage Cans", theme),
                validator: (v) => v!.isEmpty ? "Please enter item name" : null,
              ),
              const SizedBox(height: 20),

              // --- 4. PRICE PER KG ---
              _buildLabel("Price per KG (RM)"),
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextDesign.mediumText().copyWith(
                    color: theme.success,
                    fontWeight: FontWeight.bold
                ),
                decoration: _inputDecoration("0.00", theme),
                validator: (v) => v!.isEmpty ? "Enter price" : null,
              ),
              const SizedBox(height: 20),

              // --- 5. DESCRIPTION ---
              _buildLabel("Description"),
              TextFormField(
                controller: descController,
                maxLines: 3,
                style: TextDesign.smallText(color: theme.onSurface),
                decoration: _inputDecoration("Briefly describe the item properties...", theme),
              ),
              const SizedBox(height: 40),

              // --- 6. SAVE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  // --- WIDGET BUILDERS ---

  Widget _buildImagePlaceholder(AppColors theme) {
    return Center(
      child: Container(
        height: 140,
        width: 140,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.border.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 40, color: theme.primary),
            const SizedBox(height: 8),
            Text("Add Photo", style: TextDesign.smallText(color: theme.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(AppColors theme) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: categories.map((cat) {
        bool isSelected = selectedCategory == cat;
        return ChoiceChip(
          label: Text(cat),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() => selectedCategory = selected ? cat : null);
          },
          selectedColor: theme.primary.withOpacity(0.15),
          backgroundColor: theme.surface,
          labelStyle: TextDesign.smallText(
              color: isSelected ? theme.primary : theme.onSurface
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a category first!")),
        );
        return;
      }

      // TODO: Implement Supabase Insert here
      print("Saving Item: ${nameController.text}");
      print("Category: $selectedCategory");

      Navigator.pop(context);
    }
  }
}