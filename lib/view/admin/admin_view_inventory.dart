import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/RecycleInventory.dart';

class AdminViewInventory extends StatelessWidget {
  final RecycleInventory item;

  AdminViewInventory({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    final name = item.inventoryName;
    final price = item.pricePerKg;

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: theme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name!,
                style: TextDesign.appBarTitle(color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imgPath?.isNotEmpty == true)
                    Image.asset(
                      'assets/images/${item.imgPath!}', // 👈 load from assets
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.surfaceVariant,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 50,
                          color: theme.hint,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: theme.surfaceVariant,
                      child: Icon(
                        Icons.inventory_2,
                        size: 50,
                        color: theme.primary,
                      ),
                    ),
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
                  Row(
                    children: [
                      _buildInfoCard(
                        "Price per KG",
                        "RM ${price.toStringAsFixed(2)}",
                        Icons.payments_outlined,
                        theme,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoCard(
                        "Total Weight",
                        "${item.totalWeightAvailable.toStringAsFixed(1)} kg",
                        Icons.scale_outlined,
                        theme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Text("Description", style: TextDesign.label()),
                  const SizedBox(height: 8),
                  Text(item.description!, style: TextDesign.normalText()),

                  const SizedBox(height: 32),

                  Text("Inventory Information", style: TextDesign.label()),
                  const SizedBox(height: 12),

                  _buildDetailRow("Inventory ID:", item.inventoryId, theme),
                  _buildDetailRow(
                    "Category ID:",
                    item.categoryId.toString(),
                    theme,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String label,
      String value,
      IconData icon,
      AppColors theme,
      ) {
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
              style: TextDesign.mediumText().copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
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
          Text(
            value,
            style: TextDesign.mediumText().copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}