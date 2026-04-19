import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import '../../../models/RecyclePurchases.dart';

class AdminPurchaseUpdate extends StatefulWidget {
  final RecyclePurchases purchase;
  final List<dynamic> items;

  const AdminPurchaseUpdate({
    super.key,
    required this.purchase,
    required this.items,
  });

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
    paymentStatus = widget.purchase.paymentStatus;
    pickupStatus = widget.purchase.pickupStatus ?? 'pending';
  }

  // ===============================
  // 🔒 STATUS RULES
  // ===============================

  List<String> getPaymentOptions(String current) {
    if (current == "pending") {
      return ["success", "cancelled"];
    }
    return []; // final state
  }

  List<String> getPickupOptions(String current, String payment) {
    // 🚫 Cannot complete if not paid
    if (payment != "success") {
      if (current == "pending") return ["cancelled"];
      return [];
    }

    // ✅ Payment success → allow flow
    if (current == "pending") {
      return ["completed", "cancelled"];
    }

    return []; // final state
  }

  bool isValidUpdate() {
    if (pickupStatus == "completed" && paymentStatus != "success") {
      return false;
    }
    return true;
  }

  // ===============================
  // UI
  // ===============================

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

                  // PAYMENT
                  _buildSectionLabel("Payment Status", Icons.account_balance_wallet_outlined),
                  const SizedBox(height: 12),
                  _buildStatusSelector(
                    getPaymentOptions(paymentStatus),
                    paymentStatus,
                        (val) {
                      setState(() {
                        paymentStatus = val;

                        // 🔁 Auto cancel pickup if payment cancelled
                        if (val == "cancelled") {
                          pickupStatus = "cancelled";
                        }
                      });
                    },
                    theme,
                  ),

                  const SizedBox(height: 32),

                  // PICKUP
                  _buildSectionLabel("Pickup Status", Icons.local_shipping_outlined),
                  const SizedBox(height: 12),
                  _buildStatusSelector(
                    getPickupOptions(pickupStatus, paymentStatus),
                    pickupStatus,
                        (val) => setState(() => pickupStatus = val),
                    theme,
                  ),

                  const SizedBox(height: 32),

                  // DETAILS
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

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppThemes.color.primary),
        const SizedBox(width: 8),
        Text(label.toUpperCase(), style: TextDesign.label()),
      ],
    );
  }

  // ===============================
  // 🔘 STATUS SELECTOR (SMART)
  // ===============================
  Widget _buildStatusSelector(
      List<String> options,
      String current,
      Function(String) onSelect,
      AppColors theme,
      ) {
    // 🔒 LOCKED STATE
    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            current.toUpperCase(),
            style: TextDesign.badgeText(color: theme.onSurface),
          ),
        ),
      );
    }

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

  // ===============================
  // SUMMARY CARD
  // ===============================
  Widget _buildPurchaseSummaryCard(RecyclePurchases purchase, AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(purchase.itemName ?? "Item", style: TextDesign.headingThree()),
          const SizedBox(height: 8),
          Text("Quantity: ${purchase.quantity ?? 0} kg"),
          Text("Total: RM ${purchase.totalPrice.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  // ===============================
  // SAVE
  // ===============================
  Widget _buildBottomAction(AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(24), // Matches your standard page padding
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveUpdates,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(55), // Full width, consistent height
          backgroundColor: theme.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Your standard app radius
          ),
        ),
        child: _isSaving
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : const Text(
          "UPDATE STATUS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2, // Gives it that clean, modern button feel
          ),
        ),
      ),
    );
  }

  Future<void> _saveUpdates() async {
    setState(() => _isSaving = true);

    try {
      // 🔒 FINAL VALIDATION
      if (!isValidUpdate()) {
        throw Exception("Cannot complete pickup before payment success");
      }

      if (widget.purchase.purchaseId != null) {
        await RecyclePurchasesModel().updatePaymentStatus(
          widget.purchase.purchaseId!,
          paymentStatus,
        );

        await RecyclePurchasesModel().updatePickupStatus(
          widget.purchase.purchaseId!,
          pickupStatus,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Statuses updated successfully")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}