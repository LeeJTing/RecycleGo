import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/view/admin/admin_purchase_detail.dart';
import 'package:recycle_go/view/admin/admin_purchase_update.dart';

class AdminViewPurchase extends StatefulWidget {
  const AdminViewPurchase({super.key});

  @override
  State<AdminViewPurchase> createState() => _AdminViewPurchaseState();
}

class _AdminViewPurchaseState extends State<AdminViewPurchase> {
  String _selectedStatus = "All Requests";

  // Using your SQL-based mock data
  final List<Map<String, dynamic>> _mockData = [
    {
      'purchase_id': '88888888-0001',
      'user_id': 'Michael Chen',
      'total_price': 650.00,
      'order_status': 'processing',
      'fulfillment_type': 'delivery',
      'total_weight': 500.0,
    },
    {
      'purchase_id': '88888888-0002',
      'user_id': 'GreenTrade Inc',
      'total_price': 20.00,
      'order_status': 'completed',
      'fulfillment_type': 'pickup',
      'pickup_address': 'City Hub Recycling Center',
      'total_weight': 1200.0,
    },
    {
      'purchase_id': '88888888-0003',
      'user_id': 'EcoPoly Solutions',
      'total_price': 0.00,
      'order_status': 'cancelled',
      'fulfillment_type': 'delivery',
      'total_weight': 0.0,
    },
  ];

  // Helper: Filter Logic
  List<Map<String, dynamic>> get _filteredData {
    if (_selectedStatus == "All Requests") return _mockData;
    return _mockData.where((item) =>
    item['order_status'].toString().toLowerCase() == _selectedStatus.toLowerCase()
    ).toList();
  }

  // Helper: Get Button Label based on Recommendation
  String _getButtonLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return "View Details";
      case 'processing': return "Update Status";
      case 'cancelled': return "View Reason";
      default: return "Review";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final displayData = _filteredData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(theme),
        const SizedBox(height: 10),
        _buildFilterRow(theme),
        const SizedBox(height: 16),
        Expanded(
          child: displayData.isEmpty
              ? Center(child: Text("No records found", style: TextDesign.normalText()))
              : ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: displayData.length,
            itemBuilder: (context, index) => _buildHistoryCard(displayData[index], theme),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AppColors theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: theme.onBackground.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: "Search by Buyer or Request ID...",
            hintStyle: TextDesign.hintText(),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 18.0, right: 8.0),
              child: Icon(Icons.search, color: theme.hint, size: 20),
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(AppColors theme) {
    final options = ["All Requests", "Processing", "Completed", "Cancelled"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: options.map((label) {
          bool isActive = _selectedStatus == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? theme.primary : theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label, style: TextDesign.badgeText(color: isActive ? Colors.white : theme.onSurface)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> purchase, AppColors theme) {
    final status = purchase['order_status'].toString().toLowerCase();
    final isCancelled = status == 'cancelled';
    final isCompleted = status == 'completed';
    final Map<String, dynamic> samplePurchase = {
      'purchase_id': '88888888-0009',
      'user_id': '11111111-0009',
      'station_id': '33333333-0009',
      'total_price': '55.00',
      'order_status': 'processing',
      'fulfillment_type': 'pickup',
      'logistics_status': 'arrived',
      'payment_status': 'success',
      'pickup_address': 'Sri Rampai, Setapak',
    };

    final List<Map<String, dynamic>> sampleItems = [
      {
        'inventory_id': '29405d44-a4df-46b9-940b-fe69c50fcd7f',
        'quantity_kg': '12.222',
        'subtotal_price': '55.00',
        'material_name': 'Metal' // Useful for the Admin to see
      }
    ];
    // Status Colors
    Color mainColor = isCompleted ? theme.success : (isCancelled ? theme.error : theme.warning);
    Color bgColor = isCompleted ? theme.successContainer : (isCancelled ? theme.error.withOpacity(0.1) : theme.warningContainer);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: theme.onBackground.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Image + ID + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 50, height: 50,
                      color: theme.surfaceVariant,
                      child: Icon(Icons.inventory_2_outlined, color: theme.primary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ID: ${purchase['purchase_id'].substring(0, 8)}", style: TextDesign.label()),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(purchase['fulfillment_type'] == 'delivery' ? Icons.local_shipping : Icons.location_on, color: theme.hint, size: 14),
                          const SizedBox(width: 4),
                          Text(purchase['fulfillment_type'].toUpperCase(), style: TextDesign.smallText(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), style: TextDesign.badgeText(color: mainColor)),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(purchase['user_id'], style: TextDesign.headingThree()),

          const SizedBox(height: 16),

          // DATA GRID
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.surfaceVariant.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("QUANTITY", style: TextDesign.label()),
                      const SizedBox(height: 4),
                      Text("${purchase['total_weight']} kg", style: TextDesign.mediumText(fontSize: 18)),
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
                        Text("OFFER PRICE", style: TextDesign.label()),
                        const SizedBox(height: 4),
                        Text("RM ${purchase['total_price']}",
                            style: TextDesign.priceText(color: isCancelled ? theme.hint : theme.success)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- SMART ACTION ROW ---
          Row(
            children: [
              // Show "Details" button only if NOT completed
              if (!isCompleted)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                          MaterialPageRoute(
                            builder: (context) => AdminPurchaseDetail(
                              purchase: samplePurchase,
                              items: sampleItems,
                            ),
                          )
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text("Details", style: TextDesign.mediumText(fontSize: 14)),
                  ),
                ),

              if (!isCompleted) const SizedBox(width: 12),

              // Primary Action (Changes based on Status)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminPurchaseUpdate(
                            purchase: samplePurchase,
                            items: sampleItems,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCancelled ? theme.error.withOpacity(0.1) : theme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                      _getButtonLabel(status),
                      style: isCancelled
                          ? TextDesign.badgeText(color: theme.error)
                          : TextDesign.buttonText()
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}