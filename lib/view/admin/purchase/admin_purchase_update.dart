import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Connector.dart';

import '../../../models/RecyclePurchases.dart';

class AdminPurchaseUpdate extends StatefulWidget {
  final RecyclePurchases purchase;
  final List<dynamic> items;

  const AdminPurchaseUpdate({super.key, required this.purchase, required this.items});

  @override
  State<AdminPurchaseUpdate> createState() => _AdminPurchaseUpdateState();
}

class _AdminPurchaseUpdateState extends State<AdminPurchaseUpdate> {
  late String paymentStatus;
  late String pickupStatus;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Set initial real statuses directly from the model
    paymentStatus = widget.purchase.paymentStatus;
    // Default to 'pending' if pickupStatus is null in the database
    pickupStatus = widget.purchase.pickupStatus ?? 'pending';

    // NOTE: We completely removed the _fetchItems() logic because the
    // itemName, quantity, and totalPrice are now stored directly in the purchase object!
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Modify Status", style: TextDesign.appBarTitle()),
        centerTitle: true,
        backgroundColor: theme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // --- 1. PAYMENT STATUS ---
                  _buildSectionLabel("Payment Status", Icons.account_balance_wallet_outlined),
                  const SizedBox(height: 12),
                  _buildStatusSelector(["pending", "success", "failed"], paymentStatus, (val) => setState(() => paymentStatus = val), theme),

                  const SizedBox(height: 32),

                  // --- 2. PICKUP STATUS ---
                  _buildSectionLabel("Pickup Status", Icons.local_shipping_outlined),
                  const SizedBox(height: 12),
                  _buildStatusSelector(["pending", "completed", "cancelled"], pickupStatus, (val) => setState(() => pickupStatus = val), theme),

                  const SizedBox(height: 32),

                  // --- 3. PURCHASE DETAILS (User Submitted) ---
                  _buildSectionLabel("Request Details", Icons.inventory_2_outlined),
                  const SizedBox(height: 12),
                  _buildPurchaseSummaryCard(widget.purchase, theme),

                ],
              ),
            ),
          ),
          _buildBottomAction(theme),
        ],
      ),
    );
  }

  // --- NEW: SUMMARY CARD ---
  Widget _buildPurchaseSummaryCard(RecyclePurchases purchase, AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: theme.onBackground.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(purchase.itemName ?? "Unspecified Item", style: TextDesign.headingThree()),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: theme.hint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  purchase.pickupLocationName ?? purchase.pickupAddress ?? "No location specified",
                  style: TextDesign.smallText(color: theme.hint),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("QUANTITY", style: TextDesign.label()),
                    const SizedBox(height: 4),
                    Text("${purchase.quantity ?? 0.0} kg", style: TextDesign.mediumText(fontSize: 18)),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: theme.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TOTAL PRICE", style: TextDesign.label()),
                      const SizedBox(height: 4),
                      Text("RM ${purchase.totalPrice.toStringAsFixed(2)}", style: TextDesign.priceText()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppThemes.color.primary),
        const SizedBox(width: 8),
        Text(label.toUpperCase(), style: TextDesign.label()),
      ],
    );
  }

  Widget _buildStatusSelector(List<String> options, String current, Function(String) onSelect, AppColors theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((option) {
          bool isSelected = current == option;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    option.toUpperCase(),
                    style: TextDesign.badgeText(
                      color: isSelected ? Colors.white : theme.onSurface.withOpacity(0.6),
                    ).copyWith(fontSize: 10),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomAction(AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("Discard", style: TextDesign.mediumText()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveUpdates,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("Update Status", style: TextDesign.buttonText()),
            ),
          ),
        ],
      ),
    );
  }

  // --- DYNAMIC DATABASE SAVE ---
  Future<void> _saveUpdates() async {
    setState(() => _isSaving = true);

    try {
      if (widget.purchase.purchaseId != null) {
        // 1. Update Payment Status
        await RecyclePurchasesModel().updatePaymentStatus(
            widget.purchase.purchaseId!,
            paymentStatus
        );

        // 2. Update Pickup Status
        await RecyclePurchasesModel().updatePickupStatus(
            widget.purchase.purchaseId!,
            pickupStatus
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Statuses Updated successfully!")));
        Navigator.pop(context, true); // Go back and tell the previous screen to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}