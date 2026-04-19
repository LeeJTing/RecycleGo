import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    descController = TextEditingController(text: widget.voucher.description);
    pointsController = TextEditingController(
      text: widget.voucher.pointsRequired.toString(),
    );
    qtyController = TextEditingController(
      text: widget.voucher.numberOfVouchers.toString(),
    );
    durationController = TextEditingController(
      text: widget.voucher.voucherDuration?.toString() ?? '',
    );
    final normalizedCategory = widget.voucher.voucherCategory.toLowerCase();
    selectedCategory = categories.firstWhere(
      (c) => c.toLowerCase() == normalizedCategory,
      orElse: () => categories.first,
    );
    isInfinite = widget.voucher.isInfinite;

    // Add listeners to trigger form validation on change
    nameController.addListener(_updateFormState);
    descController.addListener(_updateFormState);
    pointsController.addListener(_updateFormState);
    qtyController.addListener(_updateFormState);
    durationController.addListener(_updateFormState);
  }

  void _updateFormState() {
    setState(() {});
  }

  bool _isFormValid() {
    // Voucher Name: max 25 characters, not empty
    if (nameController.text.isEmpty || nameController.text.length > 25) {
      return false;
    }

    // Value: numeric only, between 0 and 100
    final valueText = descController.text.trim();
    if (valueText.isEmpty) {
      return false;
    }
    if (!RegExp(r'^\d+$').hasMatch(valueText)) {
      return false;
    }
    final value = int.tryParse(valueText);
    if (value == null || value < 0 || value > 100) {
      return false;
    }

    // Points: must not be negative, cannot exceed 10000
    final points = int.tryParse(pointsController.text);
    if (points == null || points < 0 || points > 10000) {
      return false;
    }

    // Quantity: cannot be negative or > 10000
    final qty = int.tryParse(qtyController.text);
    if (qty == null || qty < 0 || qty > 10000) {
      return false;
    }

    // Duration: only validate if not infinite
    if (!isInfinite) {
      final duration = int.tryParse(durationController.text);
      if (duration == null || duration < 1) {
        return false;
      }
    }

    return true;
  }

  String? _getNameError() {
    if (nameController.text.isEmpty) return "Name cannot be empty";
    if (nameController.text.length > 25)
      return "Name cannot exceed 25 characters";
    return null;
  }

  String? _getDescError() {
    final valueText = descController.text.trim();
    if (valueText.isEmpty) return "Value cannot be empty";
    if (!RegExp(r'^\d+$').hasMatch(valueText)) {
      return "Value cannot contain special characters";
    }
    final value = int.tryParse(valueText);
    if (value == null) return "Value must be a valid number";
    if (value < 0) return "Value cannot be negative";
    if (value > 100) return "Value cannot exceed 100";
    return null;
  }

  String? _getPointsError() {
    if (pointsController.text.isEmpty) return "Points required";
    final points = int.tryParse(pointsController.text);
    if (points == null) return "Must be a valid number";
    if (points < 0) return "Points cannot be negative";
    if (points > 10000) return "Points cannot exceed 10000";
    return null;
  }

  String? _getQtyError() {
    if (qtyController.text.isEmpty) return "Quantity required";
    final qty = int.tryParse(qtyController.text);
    if (qty == null) return "Must be a valid number";
    if (qty < 0) return "Quantity cannot be negative";
    if (qty > 10000) return "Quantity cannot exceed 10000";
    return null;
  }

  String? _getDurationError() {
    if (isInfinite) return null;
    if (durationController.text.isEmpty) return "Duration required";
    final duration = int.tryParse(durationController.text);
    if (duration == null) return "Must be a valid number";
    if (duration < 1) return "Duration must be at least 1 day";
    return null;
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
                decoration: _inputStyle(
                  "Voucher Name",
                  theme,
                ).copyWith(errorText: _getNameError()),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Name cannot be empty";
                  if (v.length > 25) return "Name cannot exceed 25 characters";
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildLabel("Value"),
              TextFormField(
                controller: descController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextDesign.smallText(),
                decoration: _inputStyle(
                  "e.g., 10",
                  theme,
                ).copyWith(errorText: _getDescError()),
                validator: (v) {
                  final valueText = v?.trim() ?? '';
                  if (valueText.isEmpty) return "Value cannot be empty";
                  if (!RegExp(r'^\d+$').hasMatch(valueText)) {
                    return "Value cannot contain special characters";
                  }
                  final value = int.tryParse(valueText);
                  if (value == null) return "Value must be a valid number";
                  if (value < 0) return "Value cannot be negative";
                  if (value > 100) return "Value cannot exceed 100";
                  return null;
                },
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
                  errorText: _getPointsError(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Points required";
                  final points = int.tryParse(v);
                  if (points == null) return "Must be a valid number";
                  if (points < 0) return "Points cannot be negative";
                  if (points > 10000) return "Points cannot exceed 10000";
                  return null;
                },
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
                  value: categories.contains(selectedCategory)
                      ? selectedCategory
                      : 'Exchange',
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
                  errorText: _getQtyError(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Quantity required";
                  final qty = int.tryParse(v);
                  if (qty == null) return "Must be a valid number";
                  if (qty < 0) return "Quantity cannot be negative";
                  if (qty > 10000) return "Quantity cannot exceed 10000";
                  return null;
                },
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
                    errorText: _getDurationError(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Duration required" : null,
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 24),

              // --- UPDATE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isFormValid() ? _handleUpdate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: theme.onSurface.withOpacity(0.3),
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
