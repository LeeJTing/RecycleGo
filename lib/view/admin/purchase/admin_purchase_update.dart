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

    final originalPayment = widget.purchase.paymentStatus;
    final originalPickup = widget.purchase.pickupStatus ?? 'pending';

    List<String> pickupDisabled = [];

    if (paymentStatus != 'success') {
      pickupDisabled = ["pending", "completed", "cancelled"];
    }

    if (originalPickup == 'completed' || originalPickup == 'cancelled') {
      pickupDisabled = ["pending", "completed", "cancelled"];
    }

    bool isUnchanged =
        paymentStatus == originalPayment &&
            pickupStatus == originalPickup;

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

                  // --- PAYMENT STATUS ---
                  _buildSectionLabel(
                    "Payment Status",
                    Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildStatusSelector(
                    ["pending", "success", "failed"],
                    paymentStatus,
                        (val) => setState(() => paymentStatus = val),
                    theme,
                    originalPayment, // ✅ non-null
                    [], // no restriction
                  ),

                  const SizedBox(height: 32),

                  // --- PICKUP STATUS ---
                  _buildSectionLabel(
                    "Pickup Status",
                    Icons.local_shipping_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildStatusSelector(
                    ["pending", "completed", "cancelled"],
                    pickupStatus,
                        (val) => setState(() => pickupStatus = val),
                    theme,
                    originalPickup, // ✅ fixed null issue
                    pickupDisabled,
                  ),

                  const SizedBox(height: 32),

                  // --- PURCHASE DETAILS ---
                  _buildSectionLabel(
                    "Request Details",
                    Icons.inventory_2_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildPurchaseSummaryCard(widget.purchase, theme),
                ],
              ),
            ),
          ),

          // --- BOTTOM ACTION ---
          _buildBottomAction(theme, isUnchanged),
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
        boxShadow: [
          BoxShadow(color: theme.onBackground.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(purchase.itemName ?? "Unspecified Item",
              style: TextDesign.headingThree()),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: theme.hint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  purchase.pickupLocationName ?? purchase.pickupAddress ??
                      "No location specified",
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
                    Text("${purchase.quantity ?? 0.0} kg",
                        style: TextDesign.mediumText(fontSize: 18)),
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
                      Text("RM ${purchase.totalPrice.toStringAsFixed(2)}",
                          style: TextDesign.priceText()),
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

  Widget _buildStatusSelector(List<String> options,
      String current,
      Function(String) onSelect,
      AppColors theme,
      String originalStatus,
      List<String> disabledOptions,) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((option) {
          bool isSelected = current == option;

          // 🔥 Disable logic
          bool isDisabled =
              option == originalStatus || disabledOptions.contains(option);

          return Expanded(
            child: GestureDetector(
              onTap: isDisabled ? null : () => onSelect(option),
              child: Opacity(
                opacity: isDisabled ? 0.5 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primary.withOpacity(0.2)
                        : theme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? theme.primary
                          : theme.border.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option.toUpperCase(),
                      style: TextDesign.badgeText(
                        color: isDisabled
                            ? theme.hint
                            : (isSelected
                            ? theme.primary
                            : theme.onSurface.withOpacity(0.7)),
                      ).copyWith(fontSize: 10),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomAction(AppColors theme, bool isUnchanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isUnchanged ? null : _updateStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor:
              isUnchanged ? theme.border : theme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Update Status",
              style: TextDesign.buttonText(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus() async {
    try {
      await RecyclePurchasesModel().updatePurchaseStatus(
        purchaseId: widget.purchase.purchaseId!,
        paymentStatus: paymentStatus,
        pickupStatus: pickupStatus,
      );

      // 🔥 return true to trigger refresh
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }
}