import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

import '../../models/RecyclePurchases.dart';

class AdminPurchaseDetail extends StatelessWidget {
  final RecyclePurchases purchase;
  final List<dynamic> items;

  const AdminPurchaseDetail({
    super.key,
    required this.purchase,
    required this.items, // Now required as a separate list
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

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
            // // --- 1. ORDER & LOGISTICS ---
            // _buildOrderHeader(purchase, theme),
            // const SizedBox(height: 16),

            // // --- 2. CUSTOMER INFO ---
            // _buildCustomerStationCard(purchase, theme),
            // const SizedBox(height: 24),

            // --- 3. ITEMS PURCHASED (Using the 'items' parameter) ---
            Text("Items Purchased", style: TextDesign.headingThree()),
            const SizedBox(height: 12),
            ...items.map((item) => _buildItemTile(item, theme)).toList(),
            const SizedBox(height: 24),

            // --- 4. SUMMARY ---
            // _buildSummaryCard(purchase, theme),
            // const SizedBox(height: 24),
            //
            // // --- 5. PAYMENT METHOD ---
            // Text("Payment Method", style: TextDesign.headingThree()),
            // const SizedBox(height: 12),
            // _buildPaymentCard(purchase, theme),

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
                // Note: Using 'inventory_name' or similar from your items list
                Text(item['inventory_name'] ?? "Recyclable Item", style: TextDesign.mediumText()),
                Text("${item['quantity_kg'] ?? '0.0'} kg", style: TextDesign.smallText()),
              ],
            ),
          ),
          Text("RM ${item['subtotal_price']}", style: TextDesign.priceText(fontSize: 16)),
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

  // ... (Keep _buildOrderHeader, _buildCustomerStationCard, _buildSummaryCard,
  // _buildPaymentCard, _cardStyle, _iconLabelRow, _summaryRow, _statusBadge,
  // _iconDetail, and _buildAdminBadge exactly as they were)

  Widget _buildOrderHeader(Map<String, dynamic> p, AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.successContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order ID: ${p['purchase_id'].toString().substring(0, 8).toUpperCase()}",
                      style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold)),
                  Text(p['completed_at'] ?? "Pending Date", style: TextDesign.smallText()),
                ],
              ),
              _statusBadge(p['order_status'], theme),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconDetail(Icons.local_shipping_outlined, "Type", p['fulfillment_type'] ?? "N/A", theme),
              _iconDetail(Icons.fact_check_outlined, "Logistics", p['logistics_status'] ?? "N/A", theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStationCard(Map<String, dynamic> p, AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconLabelRow(Icons.person_outline, p['user_id'] ?? "Guest User", theme, isBold: true),
          const Divider(height: 24),
          _iconLabelRow(Icons.account_balance_outlined, "Station: ${p['station_id'] ?? 'N/A'}", theme),
          if (p['pickup_address'] != null) ...[
            const SizedBox(height: 12),
            _iconLabelRow(Icons.location_on_outlined, p['pickup_address'], theme),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> p, AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(theme),
      child: Column(
        children: [
          _summaryRow("Subtotal", "RM ${p['total_price']}", false, theme),
          _summaryRow("Delivery Fee", "RM 0.00", false, theme),
          const Divider(height: 20),
          _summaryRow("Total Price", "RM ${p['total_price']}", true, theme),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> p, AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(theme),
      child: Column(
        children: [
          _iconLabelRow(Icons.credit_card_outlined, p['payment_method'] ?? "Credit Card •••• 4242", theme),
          const SizedBox(height: 12),
          _iconLabelRow(Icons.receipt_long_outlined, "TXN: ${p['purchase_id'].toString().substring(0, 12).toUpperCase()}", theme),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: theme.success),
              const SizedBox(width: 10),
              Text("Payment Status: ", style: TextDesign.smallText()),
              Text((p['payment_status'] ?? "Success").toUpperCase(),
                  style: TextDesign.smallText(color: theme.success).copyWith(fontWeight: FontWeight.bold)),
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
    Color color = status == 'completed' ? theme.success : (status == 'cancelled' ? theme.error : theme.warning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextDesign.badgeText(color: Colors.white)),
    );
  }

  Widget _iconDetail(IconData icon, String label, String value, AppColors theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.hint),
        const SizedBox(width: 6),
        Text("$label: ", style: TextDesign.smallText()),
        Text(value.toUpperCase(), style: TextDesign.smallText(color: theme.onSurface).copyWith(fontWeight: FontWeight.bold)),
      ],
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