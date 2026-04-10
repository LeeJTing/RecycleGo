import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';

class AdminEditVoucher extends StatefulWidget {
  final Vouchers voucher;
  final int index;

  const AdminEditVoucher({
    super.key,
    required this.voucher,
    required this.index,
  });

  @override
  State<AdminEditVoucher> createState() => _AdminEditVoucherState();
}

class _AdminEditVoucherState extends State<AdminEditVoucher> {
  final _formKey = GlobalKey<FormState>();
  final voucherCtrl = VoucherCtrl();

  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController pointsController;
  late TextEditingController qtyController;
  late TextEditingController durationController;
  late String selectedCategory;
  bool isInfinite = false;

  final List<String> categories = ['Food', 'Shopping', 'Exchange'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    nameController = TextEditingController(text: widget.voucher.voucherName);
    descController = TextEditingController(
      text: widget.voucher.description ?? '',
    );
    pointsController = TextEditingController(
      text: widget.voucher.pointsRequired.toString(),
    );
    qtyController = TextEditingController(
      text: widget.voucher.numberOfVouchers.toString(),
    );
    durationController = TextEditingController(
      text: widget.voucher.voucherDuration?.toString() ?? '',
    );
    selectedCategory = widget.voucher.voucherCategory;
    isInfinite = widget.voucher.isInfinite ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    pointsController.dispose();
    qtyController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Edit Voucher", style: TextDesign.appBarTitle()),
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
              _buildLabel("Voucher Name"),
              TextFormField(
                controller: nameController,
                style: TextDesign.normalText(),
                decoration: _inputStyle("Voucher Name", theme),
                validator: (v) => v!.isEmpty ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 24),

              _buildLabel("Description"),
              TextFormField(
                controller: descController,
                maxLines: 3,
                style: TextDesign.smallText(),
                decoration: _inputStyle("Description...", theme),
                validator: (v) =>
                    v!.isEmpty ? "Description cannot be empty" : null,
              ),
              const SizedBox(height: 24),

              _buildLabel("Points Required"),
              TextFormField(
                controller: pointsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                style: TextDesign.mediumText().copyWith(
                  color: theme.success,
                  fontWeight: FontWeight.bold,
                ),
                decoration: _inputStyle("800", theme).copyWith(
                  suffixText: "pts",
                  suffixStyle: TextDesign.smallText(color: theme.primary),
                ),
                validator: (v) => v!.isEmpty ? "Points required" : null,
              ),
              const SizedBox(height: 24),

              _buildLabel("Category"),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border.withOpacity(0.3)),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCategory,
                  underline: const SizedBox(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  items: categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextDesign.normalText()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => selectedCategory = newValue!);
                  },
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel("Quantity"),
              TextFormField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                style: TextDesign.mediumText().copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: _inputStyle("50", theme).copyWith(
                  suffixText: "vouchers",
                  suffixStyle: TextDesign.smallText(color: theme.primary),
                ),
                validator: (v) => v!.isEmpty ? "Quantity required" : null,
              ),
              const SizedBox(height: 24),

              _buildLabel("Duration Type"),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border.withOpacity(0.3)),
                  color: theme.surface,
                ),
                child: CheckboxListTile(
                  title: const Text("Infinite Duration"),
                  value: isInfinite,
                  onChanged: (value) {
                    setState(() => isInfinite = value ?? true);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 24),

              if (!isInfinite) ...[
                _buildLabel("Duration (Days)"),
                TextFormField(
                  controller: durationController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  style: TextDesign.mediumText().copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: _inputStyle("7", theme).copyWith(
                    suffixText: "days",
                    suffixStyle: TextDesign.smallText(color: theme.primary),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Duration required" : null,
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 24),

              // --- 8. UPDATE BUTTON ---
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
                  child: Text("Update Voucher", style: TextDesign.buttonText()),
                ),
              ),
            ],
          ),
        ),
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

  void _handleUpdate() {
    if (_formKey.currentState!.validate()) {
      final updatedVoucher = Vouchers(
        voucherId: widget.voucher.voucherId,
        voucherName: nameController.text,
        description: descController.text,
        pointsRequired: int.parse(pointsController.text),
        voucherStatus: widget.voucher.voucherStatus,
        voucherCategory: selectedCategory,
        numberOfVouchers: int.parse(qtyController.text),
        createdAt: widget.voucher.createdAt,
        updatedAt: DateTime.now(),
        isInfinite: isInfinite,
        voucherDuration: isInfinite
            ? null
            : int.tryParse(durationController.text),
      );

      voucherCtrl.updateVoucher(widget.voucher.voucherId ?? '', updatedVoucher);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voucher updated successfully!")),
      );
      Navigator.pop(context, true);
    }
  }
}
