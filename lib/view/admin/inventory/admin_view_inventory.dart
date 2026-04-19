import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/RecycleInventory.dart';

class AdminViewInventory extends StatelessWidget {
  final RecycleInventory item;

  const AdminViewInventory({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, theme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusAndWarning(theme),
                  const SizedBox(height: 24),
                  _buildInfoCards(theme),
                  const SizedBox(height: 32),
                  _buildDescription(theme),
                  const SizedBox(height: 32),
                  _buildInventoryDetails(theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- App Bar with Image ----------
  SliverAppBar _buildAppBar(BuildContext context, AppColors theme){
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: theme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          item.inventoryName,
          style: TextDesign.appBarTitle(color: Colors.white),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildItemImage(theme),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handles both asset and network images safely
  Widget _buildItemImage(AppColors theme) {
    if (item.imgPath.isEmpty) {
      return _buildPlaceholder(theme);
    }

    // Check if it's a network URL (starts with http) or local asset
    final isNetwork = item.imgPath.startsWith('http');
    if (isNetwork) {
      return Image.network(
        item.imgPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
      );
    } else {
      return Image.asset(
        'assets/images/${item.imgPath}',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
      );
    }
  }

  Widget _buildPlaceholder(AppColors theme) {
    return Container(
      color: theme.surfaceVariant,
      child: Icon(Icons.inventory_2, size: 50, color: theme.primary),
    );
  }

  // ---------- Status Chip & Low Stock Warning ----------
  Widget _buildStatusAndWarning(AppColors theme) {
    final isLowStock = item.minWeightLevel != null &&
        item.totalWeightAvailable <= item.minWeightLevel!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatusChip(theme),
            const SizedBox(width: 12),
            if (isLowStock && item.status != InventoryStatus.inactive)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.errorContainer?.withOpacity(0.2) ?? Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.error ?? Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: theme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Low stock! Only ${item.totalWeightAvailable.toStringAsFixed(1)} ${item.minWeightLevel} left',
                          style: TextDesign.smallText().copyWith(
                            color: theme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (item.minWeightLevel != null && !isLowStock && item.status != InventoryStatus.inactive)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Min. stock level: ${item.minWeightLevel!.toStringAsFixed(1)} ${item.minWeightLevel}',
              style: TextDesign.smallText().copyWith(color: theme.hint),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(AppColors theme) {
    Color bgColor;
    Color textColor;
    String label;

    switch (item.calculatedStatus) {
      case InventoryStatus.active:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Active';
        break;
      case InventoryStatus.lowStock:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Low Stock';
        break;
      case InventoryStatus.inactive:
        bgColor = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
        label = 'Inactive';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ---------- Price & Weight Cards ----------
  Widget _buildInfoCards(AppColors theme) {
    return Row(
      children: [
        _buildInfoCard(
          "Price per ${item.pricePerKg}",
          "RM ${item.pricePerKg.toStringAsFixed(2)}",
          Icons.payments_outlined,
          theme,
        ),
        const SizedBox(width: 16),
        _buildInfoCard(
          "Total Weight",
          "${item.totalWeightAvailable.toStringAsFixed(1)} ${item.totalWeightAvailable}",
          Icons.scale_outlined,
          theme,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, AppColors theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.primary, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextDesign.smallText()),
          ],
        ),
      ),
    );
  }

  // ---------- Description ----------
  Widget _buildDescription(AppColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Description", style: TextDesign.label()),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surfaceVariant?.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border.withOpacity(0.3)),
          ),
          child: Text(
            item.description.isNotEmpty ? item.description : 'No description provided.',
            style: TextDesign.normalText(),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryDetails(AppColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Inventory Information", style: TextDesign.label()),
        const SizedBox(height: 12),
        _buildDetailRow("Inventory Code:", item.inventoryCode, theme),
        _buildDetailRow("Category ID:", item.categoryId.toString(), theme),

        // 👇 New rows for missing fields
        _buildDetailRow("Status:", item.status.name, theme),
        if (item.minWeightLevel != null)
          _buildDetailRow("Min. Stock Level:", "${item.minWeightLevel!.toStringAsFixed(1)}", theme),

        if (item.createdAt != null)
          _buildDetailRow("Created:", _formatDate(item.createdAt!), theme),
        if (item.updatedAt != null)
          _buildDetailRow("Last Updated:", _formatDate(item.updatedAt!), theme),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildDetailRow(String label, String value, AppColors theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextDesign.smallText()),
          Expanded(
            child: Text(
              value,
              style: TextDesign.mediumText().copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}