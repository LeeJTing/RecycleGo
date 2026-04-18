import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Connector.dart';

import '../../models/RecyclePurchases.dart';

class AdminPurchaseUpdate extends StatefulWidget {
  final RecyclePurchases purchase;
  final List<dynamic> items;

  const AdminPurchaseUpdate({super.key, required this.purchase, required this.items});

  @override
  State<AdminPurchaseUpdate> createState() => _AdminPurchaseUpdateState();
}

class _AdminPurchaseUpdateState extends State<AdminPurchaseUpdate> {
  late String paymentStatus;

  bool _isSaving = false;
  bool _isLoadingItems = true;

  List<Map<String, dynamic>> _fetchedItems = [];
  List<TextEditingController> weightControllers = [];

  @override
  void initState() {
    super.initState();
    // 1. Set initial real payment status
    paymentStatus = widget.purchase.paymentStatus;

    // 2. Fetch real items from the database!
    _fetchItems();
  }

  // --- DYNAMIC DATABASE FETCH ---
  Future<void> _fetchItems() async {
    try {
      if (widget.purchase.purchaseId == null) return;

      final supabase = Supabase.instance.client;

      // Fetch items from purchaseinventory and join the name from recycleinventory
      final response = await supabase
          .from('purchaseinventory')
          .select('*, recycleinventory(inventory_name)')
          .eq('purchase_id', widget.purchase.purchaseId!);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      setState(() {
        _fetchedItems = data;
        // Create a controller for each fetched item so it can be edited
        for (var item in _fetchedItems) {
          weightControllers.add(TextEditingController(text: item['quantity_kg'].toString()));
        }
        _isLoadingItems = false;
      });
    } catch (e) {
      print("Error fetching items: $e");
      setState(() => _isLoadingItems = false);
    }
  }

  @override
  void dispose() {
    for (var controller in weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Modify Request", style: TextDesign.appBarTitle()),
        centerTitle: true,
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
                  // Matched to your DB ENUM array: 'success', 'pending', 'failed'
                  _buildStatusSelector(["pending", "success", "failed"], paymentStatus, (val) => setState(() => paymentStatus = val), theme),

                  const SizedBox(height: 32),

                  // --- 2. ITEM UPDATES ---
                  _buildSectionLabel("Adjust Item Weights", Icons.scale_outlined),
                  const SizedBox(height: 12),

                  // Handle loading and empty states!
                  if (_isLoadingItems)
                    Center(child: CircularProgressIndicator(color: theme.primary))
                  else if (_fetchedItems.isEmpty)
                    Text("No items found for this purchase.", style: TextDesign.smallText(color: theme.hint))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _fetchedItems.length,
                      itemBuilder: (context, index) {
                        return _buildEditableItemTile(index, theme);
                      },
                    ),
                ],
              ),
            ),
          ),
          _buildBottomAction(theme),
        ],
      ),
    );
  }

  Widget _buildEditableItemTile(int index, AppColors theme) {
    final item = _fetchedItems[index];
    // Extract name from the joined table
    final itemName = item['recycleinventory']?['inventory_name'] ?? "Item ${item['inventory_id'].toString().substring(0, 5)}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.eco_outlined, color: theme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemName, style: TextDesign.label()),
                Text("RM ${item['price_per_kg']} / kg", style: TextDesign.smallText()),
              ],
            ),
          ),
          // WEIGHT INPUT FIELD
          SizedBox(
            width: 100,
            child: TextField(
              controller: weightControllers[index],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                suffixText: " kg",
                suffixStyle: TextDesign.label(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
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
              onPressed: _isSaving ? null : _saveUpdates, // Disable button if loading
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("Update Request", style: TextDesign.buttonText()),
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
      final supabase = Supabase.instance.client;

      // 1. Save the Payment Status to `recyclepurchases`
      if (widget.purchase.purchaseId != null) {
        await RecyclePurchasesModel().updatePaymentStatus(
            widget.purchase.purchaseId!,
            paymentStatus
        );
      }

      // 2. Save the updated weights and subtotal for each item to `purchaseinventory`
      double newGrandTotal = 0.0;

      for (int i = 0; i < _fetchedItems.length; i++) {
        final item = _fetchedItems[i];
        final newWeight = double.tryParse(weightControllers[i].text) ?? 0.0;
        final pricePerKg = double.tryParse(item['price_per_kg'].toString()) ?? 0.0;

        // Auto-calculate the new subtotal based on the new weight
        final newSubtotal = newWeight * pricePerKg;
        newGrandTotal += newSubtotal;

        await supabase.from('purchaseinventory').update({
          'quantity_kg': newWeight,
          'subtotal_price': newSubtotal,
        }).eq('purchase_id', widget.purchase.purchaseId!)
            .eq('inventory_id', item['inventory_id']);
      }

      // 3. Update the overall grand total price in `recyclepurchases`
      if (widget.purchase.purchaseId != null) {
        await supabase.from('recyclepurchases').update({
          'total_price': newGrandTotal,
        }).eq('purchase_id', widget.purchase.purchaseId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchase Updated successfully!")));
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