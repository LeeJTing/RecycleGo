import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';

class AdminAddVoucher extends StatefulWidget {
  const AdminAddVoucher({super.key});

  @override
  State<AdminAddVoucher> createState() => _AdminAddVoucherState();
}

class _AdminAddVoucherState extends State<AdminAddVoucher> {
  final _formKey = GlobalKey<FormState>();
  final voucherCtrl = VoucherCtrl();
  bool _isLoading = false;

  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController pointsController;
  late TextEditingController qtyController;
  late TextEditingController durationController;
  String selectedCategory = 'Food';
  bool isInfinite = true;

  final List<String> categories = ['Food', 'Shopping', 'Exchange'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descController = TextEditingController();
    pointsController = TextEditingController();
    qtyController = TextEditingController();
    durationController = TextEditingController();

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
    // Voucher Name: max 15 characters, not empty
    if (nameController.text.isEmpty || nameController.text.length > 15) {
      return false;
    }

    // Description: max 20 characters, not empty
    if (descController.text.isEmpty || descController.text.length > 20) {
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
    if (nameController.text.length > 15)
      return "Name cannot exceed 15 characters";
    return null;
  }

  String? _getDescError() {
    if (descController.text.isEmpty) return "Description cannot be empty";
    if (descController.text.length > 20)
      return "Description cannot exceed 20 characters";
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
        title: Text("Add Voucher", style: TextDesign.appBarTitle()),
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
                  "e.g., \$10 Money Exchange",
                  theme,
                ).copyWith(errorText: _getNameError()),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Name cannot be empty";
                  if (v.length > 15) return "Name cannot exceed 15 characters";
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildLabel("Description"),
              TextFormField(
                controller: descController,
                maxLines: 3,
                style: TextDesign.smallText(),
                decoration: _inputStyle(
                  "e.g., via Stripe Gateway",
                  theme,
                ).copyWith(errorText: _getDescError()),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return "Description cannot be empty";
                  if (v.length > 20)
                    return "Description cannot exceed 20 characters";
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
                  errorText: _getPointsError(),
                  suffixText: "pts",
                  suffixStyle: TextDesign.smallText(color: theme.primary),
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
                  errorText: _getQtyError(),
                  suffixStyle: TextDesign.smallText(color: theme.primary),
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
                    errorText: _getDurationError(),
                    suffixStyle: TextDesign.smallText(color: theme.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Duration required";
                    final duration = int.tryParse(v);
                    if (duration == null) return "Must be a valid number";
                    if (duration < 1) return "Duration must be at least 1 day";
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _isFormValid() ? _handleAdd : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          disabledBackgroundColor: theme.onSurface.withOpacity(
                            0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Add Voucher",
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

  Future<void> _handleAdd() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final newVoucher = Vouchers(
          voucherName: nameController.text,
          description: descController.text,
          pointsRequired: int.parse(pointsController.text),
          voucherStatus: 'active',
          voucherCategory: selectedCategory,
          numberOfVouchers: int.parse(qtyController.text),
          createdAt: DateTime.now(),
          isInfinite: isInfinite,
          voucherDuration: isInfinite
              ? null
              : int.tryParse(durationController.text),
        );

        await voucherCtrl.addVoucher(newVoucher);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Voucher added successfully!")),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
