import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class AdminViewInventory extends StatelessWidget {
  const AdminViewInventory({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    // --- 1. EXTRACT ARGUMENTS SAFELY ---
    // This pulls the 'item' you passed in Navigator.pushNamed
    final dynamic args = ModalRoute.of(context)?.settings.arguments;

    // If arguments are missing (e.g., direct navigation error), show a fallback
    if (args == null || args is! Map<String, dynamic>) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("No item data found.")),
      );
    }

    final Map<String, dynamic> item = args;

    // --- 2. SANITIZE DATA (Prevent Null-to-String Errors) ---
    final String name = item['inventory_name']?.toString() ?? "Unknown Item";
    final String description = item['description']?.toString() ?? "No description provided.";
    final String? imagePath = item['url_image']?.toString();
    final double weight = double.tryParse(item['total_weight']?.toString() ?? '0') ?? 0.0;
    final double price = double.tryParse(item['price_per_kg']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        slivers: [
          // COLLAPSING HEADER
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: theme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(name, style: TextDesign.appBarTitle(color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Null-safe Image display
                  imagePath != null && imagePath.isNotEmpty
                      ? Image.asset(imagePath, fit: BoxFit.cover)
                      : Container(color: theme.surfaceVariant, child: Icon(Icons.inventory_2, size: 50, color: theme.primary)),
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
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KEY STATS
                  Row(
                    children: [
                      _buildInfoCard("Price/KG", "RM ${price.toStringAsFixed(2)}", Icons.payments_outlined, theme),
                      const SizedBox(width: 16),
                      _buildInfoCard("Total Stock", "${weight.toStringAsFixed(1)} kg", Icons.scale_outlined, theme),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Text("Description", style: TextDesign.label()),
                  const SizedBox(height: 8),
                  Text(description, style: TextDesign.normalText()),

                  const SizedBox(height: 32),

                  // TECHNICAL DATA
                  Text("Inventory Information", style: TextDesign.label()),
                  const SizedBox(height: 12),
                  _buildDetailRow("Inventory ID: ", item['inventory_id']?.toString() ?? "N/A", theme),
                  _buildDetailRow("Category", name, theme),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
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
            Text(value, style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: TextDesign.smallText()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, AppColors theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextDesign.smallText()),
          Text(value, style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}