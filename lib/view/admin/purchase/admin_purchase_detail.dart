import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Connector.dart';

import '../../../models/RecyclePurchases.dart';

class AdminPurchaseDetail extends StatefulWidget {
  final RecyclePurchases purchase;
  final List<dynamic> items;

  const AdminPurchaseDetail({
    super.key,
    required this.purchase,
    required this.items,
  });

  @override
  State<AdminPurchaseDetail> createState() => _AdminPurchaseDetailState();
}

class _AdminPurchaseDetailState extends State<AdminPurchaseDetail> {
  bool _isLoadingItems = true;
  List<Map<String, dynamic>> _fetchedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  // --- DYNAMIC ITEM FETCHING ---
  Future<void> _fetchItems() async {
    try {
      if (widget.purchase.purchaseId == null) {
        setState(() => _isLoadingItems = false);
        return;
      }

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('purchaseinventory')
          .select('*, recycleinventory(inventory_name)')
          .eq('purchase_id', widget.purchase.purchaseId!);

      if (mounted) {
        setState(() {
          _fetchedItems = List<Map<String, dynamic>>.from(response);
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      print("Error fetching items: $e");
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final purchase = widget.purchase;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Purchase Details", style: TextDesign.appBarTitle()),
        actions: [_buildAdminBadge(theme)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. ORDER HEADER ---
            _buildOrderHeader(purchase, theme),
            const SizedBox(height: 16),

            // --- 2. CUSTOMER & LOCATION INFO ---
            _buildCustomerStationCard(purchase, theme),
            const SizedBox(height: 24),

            // --- 3. ITEMS PURCHASED ---
            Text("Items Purchased", style: TextDesign.headingThree()),
            const SizedBox(height: 12),
            if (_isLoadingItems)
              Center(child: CircularProgressIndicator(color: theme.primary))
            else if (_fetchedItems.isEmpty)
              Text("No items recorded.", style: TextDesign.smallText(color: theme.hint))
            else
              ..._fetchedItems.map((item) => _buildItemTile(item, theme)).toList(),
            const SizedBox(height: 24),

            // --- 4. SUMMARY ---
            _buildSummaryCard(purchase, theme),
            const SizedBox(height: 24),

            // --- 5. PAYMENT INFO ---
            Text("Payment Status", style: TextDesign.headingThree()),
            const SizedBox(height: 12),
            _buildPaymentCard(purchase, theme),

            const SizedBox(height: 40),

            // --- 6. NAVIGATION ACTION (Back Button) ---
            _buildBackButton(context, theme),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE UTILITIES ---

  Widget _buildItemTile(Map<String, dynamic> item, AppColors theme) {
    final itemName = item['recycleinventory']?['inventory_name'] ?? "Recyclable Item";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardStyle(theme),
      child: Row(
        children: [
          Icon(Icons.recycling, color: theme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemName, style: TextDesign.mediumText()),
                Text("${item['quantity_kg'] ?? '0.0'} kg  (@ RM ${item['price_per_kg']}/kg)", style: TextDesign.smallText()),
              ],
            ),
          ),
          Text("RM ${item['subtotal_price'] ?? '0.00'}", style: TextDesign.priceText(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, AppColors theme) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.surface,
          foregroundColor: theme.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.primary.withOpacity(0.5)),
          ),
        ),
        child: Text(
          "Back to History",
          style: TextDesign.mediumText(color: theme.primary).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- REWIRED UI CARDS ---

  Widget _buildOrderHeader(RecyclePurchases p, AppColors theme) {
    String dateStr = "Unknown Date";
    if (p.createdAt != null) {
      dateStr = "${p.createdAt!.year}-${p.createdAt!.month.toString().padLeft(2, '0')}-${p.createdAt!.day.toString().padLeft(2, '0')}";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.successContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Order ID: ${p.purchaseId?.substring(0, 8).toUpperCase() ?? 'N/A'}",
                  style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(dateStr, style: TextDesign.smallText()),
            ],
          ),
          _statusBadge(p.paymentStatus, theme),
        ],
      ),
    );
  }

  Widget _buildCustomerStationCard(RecyclePurchases p, AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconLabelRow(Icons.person_outline, "User ID: ${p.userId}", theme, isBold: true),
          if (p.pickupLocationName != null || p.pickupAddress != null) ...[
            const Divider(height: 24),
            _iconLabelRow(Icons.business_outlined, p.pickupLocationName ?? "Unknown Station", theme),
            const SizedBox(height: 12),
            _iconLabelRow(Icons.location_on_outlined, p.pickupAddress ?? "No address provided", theme),
          ]
        ],
      ),
    );
  }

  Widget _buildSummaryCard(RecyclePurchases p, AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(theme),
      child: Column(
        children: [
          _summaryRow("Subtotal", "RM ${p.totalPrice.toStringAsFixed(2)}", false, theme),
          const Divider(height: 20),
          _summaryRow("Total Price", "RM ${p.totalPrice.toStringAsFixed(2)}", true, theme),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(RecyclePurchases p, AppColors theme) {
    bool isSuccess = p.paymentStatus.toLowerCase() == 'success';
    bool isFailed = p.paymentStatus.toLowerCase() == 'failed';

    Color statusColor = isSuccess ? theme.success : (isFailed ? theme.error : theme.warning);
    IconData statusIcon = isSuccess ? Icons.check_circle_outline : (isFailed ? Icons.error_outline : Icons.pending_actions);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(theme),
      child: Column(
        children: [
          _iconLabelRow(Icons.receipt_long_outlined, "TXN: ${p.purchaseId?.substring(0, 12).toUpperCase() ?? 'N/A'}", theme),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(statusIcon, size: 18, color: statusColor),
              const SizedBox(width: 10),
              Text("Status: ", style: TextDesign.smallText()),
              Text(p.paymentStatus.toUpperCase(),
                  style: TextDesign.smallText(color: statusColor).copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardStyle(AppColors theme) => BoxDecoration(
    color: theme.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: theme.border.withOpacity(0.5)),
  );

  Widget _iconLabelRow(IconData icon, String text, AppColors theme, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.hint),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: isBold ? TextDesign.mediumText() : TextDesign.smallText(color: theme.onSurface)),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, bool isTotal, AppColors theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? TextDesign.mediumText() : TextDesign.smallText()),
          Text(value, style: isTotal ? TextDesign.priceText(fontSize: 20) : TextDesign.mediumText()),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, AppColors theme) {
    String lowerStatus = status.toLowerCase();
    Color color = lowerStatus == 'success' ? theme.success : (lowerStatus == 'failed' ? theme.error : theme.warning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextDesign.badgeText(color: Colors.white)),
    );
  }

  Widget _buildAdminBadge(AppColors theme) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: theme.successContainer, borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text("ADMIN", style: TextDesign.badgeText(color: theme.primary))),
    );
  }
}