import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class AdminUpdateInventory extends StatefulWidget {
  final Map<String, dynamic> item;

  const AdminUpdateInventory({super.key, required this.item});

  @override
  State<AdminUpdateInventory> createState() => _AdminUpdateInventoryState();
}

class _AdminUpdateInventoryState extends State<AdminUpdateInventory> {
  final _formKey = GlobalKey<FormState>();

  // Controllers initialized with existing data
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController weightController;
  late TextEditingController descController;
  String? selectedCategory;

  final List<String> categories = ["Plastic", "Paper", "Glasses", "CardBoard", "Metal"];

  @override
  void initState() {
    super.initState();
    // 2. Initialize the controllers with the EXISTING data
    nameController = TextEditingController(text: widget.item['inventory_name'] ?? "");
    priceController = TextEditingController(text: widget.item['price_per_kg']?.toString() ?? "0.0");
    weightController = TextEditingController(text: widget.item['total_weight']?.toString() ?? "0.0");
    descController = TextEditingController(text: widget.item['description'] ?? "");
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. CURRENT IMAGE PREVIEW ---
              _buildImagePreview(theme),
              const SizedBox(height: 32),

              // --- 2. ITEM NAME (Disabled/Read-only if needed) ---
              _buildLabel("Item Name"),
              TextFormField(
                controller: nameController,
                style: TextDesign.normalText(),
                decoration: _inputStyle("Item Name", theme),
                validator: (v) => v!.isEmpty ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 20),

              // --- 3. PRICE PER KG ---
              _buildLabel("Price per KG (RM)"),
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextDesign.mediumText().copyWith(color: theme.success, fontWeight: FontWeight.bold),
                decoration: _inputStyle("0.00", theme),
              ),
              const SizedBox(height: 20),

              // --- 4. TOTAL WEIGHT (STOCK) ---
              _buildLabel("Current Stock Weight (kg)"),
              TextFormField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold),
                decoration: _inputStyle("0.0", theme).copyWith(
                  suffixText: "kg",
                  suffixStyle: TextDesign.smallText(color: theme.primary),
                ),
              ),
              const SizedBox(height: 20),

              // --- 5. DESCRIPTION ---
              _buildLabel("Description"),
              TextFormField(
                controller: descController,
                maxLines: 4,
                style: TextDesign.smallText(),
                decoration: _inputStyle("Description...", theme),
              ),
              const SizedBox(height: 40),

              // --- 6. UPDATE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text("Update Inventory", style: TextDesign.buttonText()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildImagePreview(AppColors theme) {
    return Center(
      child: Stack(
        children: [
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: AssetImage(widget.item['url_image'] ?? 'assets/images/placeholder.webp'),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: theme.primary.withOpacity(0.2), width: 2),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border.withOpacity(0.3))),
    );
  }

  void _handleUpdate() {
    if (_formKey.currentState!.validate()) {
      // Logic to send data back to Supabase
      final updatedData = {
        'inventory_id': widget.item['inventory_id'],
        'inventory_name': nameController.text,
        'price_per_kg': double.tryParse(priceController.text) ?? 0.0,
        'total_weight': double.tryParse(weightController.text) ?? 0.0,
        'description': descController.text,
      };

      print("Updating Database with: $updatedData");
      Navigator.pop(context);
    }
  }
}