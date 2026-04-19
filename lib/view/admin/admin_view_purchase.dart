import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/view/admin/admin_purchase_detail.dart';
import 'package:recycle_go/view/admin/admin_purchase_update.dart';
import '../../models/RecyclePurchases.dart';

class AdminViewPurchase extends StatefulWidget {
  const AdminViewPurchase({super.key});

  @override
  State<AdminViewPurchase> createState() => _AdminViewPurchaseState();
}

class _AdminViewPurchaseState extends State<AdminViewPurchase> {
  String _selectedStatus = "All Requests";
  String _searchQuery = "";

  // State variables for real database data
  List<RecyclePurchases> _allPurchases = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- DATABASE FETCH ---
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await RecyclePurchasesModel().fetchAllPurchases();
      if (mounted) {
        setState(() {
          _allPurchases = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // --- DYNAMIC FILTERING ---
  List<RecyclePurchases> get _filteredData {
    return _allPurchases.where((item) {
      // 1. Filter by Status Tab
      bool matchesStatus = true;
      if (_selectedStatus != "All Requests") {
        matchesStatus = item.paymentStatus.toLowerCase() == _selectedStatus.toLowerCase();
      }

      // 2. Filter by Search Bar (checking User ID or Purchase ID)
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesSearch = (item.purchaseId?.toLowerCase().contains(query) ?? false) ||
            (item.userId.toLowerCase().contains(query));
      }

      return matchesStatus && matchesSearch;
    }).toList();
  }

  String _getButtonLabel(String status) {
    switch (status.toLowerCase()) {
      case 'success': return "View Details";
      case 'pending': return "Update Status";
      case 'failed': return "View Reason";
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

        // --- DATA DISPLAY WITH LOADING & ERROR STATES ---
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : _errorMessage != null
              ? Center(child: Text("Error: $_errorMessage", style: TextStyle(color: theme.error)))
              : displayData.isEmpty
              ? Center(child: Text("No records found", style: TextDesign.normalText()))
              : RefreshIndicator(
            onRefresh: _fetchData,
            color: theme.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: displayData.length,
              itemBuilder: (context, index) => _buildHistoryCard(displayData[index], theme),
            ),
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
          onChanged: (val) => setState(() => _searchQuery = val), // Trigger search
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
    // Uses the actual payment_status values from your Supabase DB
    final options = ["All Requests", "Pending", "Success", "Failed"];
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

  Widget _buildHistoryCard(RecyclePurchases purchase, AppColors theme) {
    final status = purchase.paymentStatus.toLowerCase();
    final isFailed = status == 'failed';
    final isSuccess = status == 'success';

    // Status Colors
    Color mainColor = isSuccess ? theme.success : (isFailed ? theme.error : theme.warning);
    Color bgColor = isSuccess ? theme.successContainer : (isFailed ? theme.error.withOpacity(0.1) : theme.warningContainer);

    // Secure Date formatting
    String dateStr = "Unknown Date";
    if (purchase.createdAt != null) {
      dateStr = "${purchase.createdAt!.year}-${purchase.createdAt!.month.toString().padLeft(2, '0')}-${purchase.createdAt!.day.toString().padLeft(2, '0')}";
    }

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
                      Text("ID: ${purchase.purchaseId?.substring(0, 8) ?? 'N/A'}", style: TextDesign.label()),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: theme.hint, size: 12),
                          const SizedBox(width: 4),
                          Text(dateStr, style: TextDesign.smallText(fontSize: 11)),
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
          Text(purchase.itemName ?? "Unspecified Item", style: TextDesign.headingThree()),
          const SizedBox(height: 4),
          Text(purchase.pickupLocationName ?? "No location specified", style: TextDesign.smallText(color: theme.hint)),

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
                      // Display the quantity from the new model
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
                        Text("RM ${purchase.totalPrice.toStringAsFixed(2)}",
                            style: TextDesign.priceText(color: isFailed ? theme.hint : theme.success)),
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
              // Details Button
              if (!isSuccess)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminPurchaseDetail(
                              purchase: purchase,
                              items: const [], // Assuming items are now directly inside the purchase object
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

              if (!isSuccess) const SizedBox(width: 12),

              // Primary Action Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminPurchaseUpdate(
                          purchase: purchase,
                          items: const [],
                        ),
                      ),
                    ).then((value) {
                      // Refresh list when returning from update screen!
                      if (value == true) _fetchData();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFailed ? theme.error.withOpacity(0.1) : theme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                      _getButtonLabel(status),
                      style: isFailed
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