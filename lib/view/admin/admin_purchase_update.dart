import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class AdminPurchaseUpdate extends StatefulWidget {
  final Map<String, dynamic> purchase;
  final List<Map<String, dynamic>> items; // List from purchaseinventory

  const AdminPurchaseUpdate({super.key, required this.purchase, required this.items});

  @override
  State<AdminPurchaseUpdate> createState() => _AdminPurchaseUpdateState();
}

class _AdminPurchaseUpdateState extends State<AdminPurchaseUpdate> {
  late String orderStatus;
  late String paymentStatus;

  // We store controllers in a list to track weight changes for each item
  List<TextEditingController> weightControllers = [];

  @override
  void initState() {
    super.initState();
    orderStatus = widget.purchase['order_status'] ?? "processing";
    paymentStatus = widget.purchase['payment_status'] ?? "pending";

    // Initialize a controller for every item in the purchase
    for (var item in widget.items) {
      weightControllers.add(TextEditingController(text: item['quantity_kg'].toString()));
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
                  // --- 1. GLOBAL STATUS UPDATES ---
                  _buildSectionLabel("Request Status", Icons.sync_problem),
                  const SizedBox(height: 12),
                  _buildStatusSelector(["processing", "completed", "cancelled"], orderStatus, (val) => setState(() => orderStatus = val), theme),

                  const SizedBox(height: 32),

                  // --- 2. ITEM UPDATES (THE NEW SECTION) ---
                  _buildSectionLabel("Adjust Item Weights", Icons.scale_outlined),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true, // Important inside SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      return _buildEditableItemTile(index, theme);
                    },
                  ),

                  const SizedBox(height: 32),

                  // --- 3. PAYMENT STATUS ---
                  _buildSectionLabel("Payment Status", Icons.account_balance_wallet_outlined),
                  const SizedBox(height: 12),
                  _buildStatusSelector(["pending", "success", "failed"], paymentStatus, (val) => setState(() => paymentStatus = val), theme),
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
    final item = widget.items[index];
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
                Text("Item ID: ${item['inventory_id'].toString().substring(0, 5)}", style: TextDesign.label()),
                Text("Current: ${item['quantity_kg']} kg", style: TextDesign.smallText()),
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

  // ... (Keep _buildSectionLabel, _buildStatusSelector, and _buildBottomAction from the previous response)

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
              onPressed: () {
                // Logic to save both Status and the New Weights
                for(int i=0; i<weightControllers.length; i++) {
                  print("Item ${widget.items[i]['inventory_id']} new weight: ${weightControllers[i].text}");
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("Update Request", style: TextDesign.buttonText()),
            ),
          ),
        ],
      ),
    );
  }
}