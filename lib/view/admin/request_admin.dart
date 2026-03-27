import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/assets.dart';
import 'package:recycle_go/app/app_theme.dart';

class RequestAdmin extends StatefulWidget {
  const RequestAdmin({super.key});

  @override
  State<RequestAdmin> createState() => _RequestAdminState();
}

class _RequestAdminState extends State<RequestAdmin> {
  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    return
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
            children: [
              // --- 1. THE IMAGE SECTION WITH PENDING TAG ---
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      '', // Your plastic bottles image
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("Pending", style: TextDesign.smallText(color: Colors.white)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- 2. USER PROFILE ROW ---
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundImage: AssetImage('assets/images/sarah.webp'), // User photo
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Sarah Jenkins", style: TextDesign.headingThree()),
                        Text("Oct 24, 2023 • 14:20 PM", style: TextDesign.smallText(color: theme.hint)),
                      ],
                    ),
                  ),
                  // ID Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "ID: SUB-492",
                      style: TextDesign.smallText(color: theme.primary).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- 3. INFO BADGES ROW (Location & Material) ---
              Row(
                children: [
                  _buildInfoChip(Icons.location_on_outlined, "Green Valley Cent", theme),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.recycling_outlined, "Plastic", theme),
                ],
              ),

              const SizedBox(height: 20), // Spacing before your buttons row

              // --- 4. YOUR BUTTON ROW (Existing Code) ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.surface,
                        foregroundColor: theme.onSurface,
                        side: BorderSide(color: theme.border),
                      ),
                      child: const Text("Approve"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.surfaceVariant,
                        foregroundColor: theme.onSurface,
                      ),
                      child: const Text("Edit"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildInfoChip(IconData icon, String label, AppColors theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceVariant, // Using your new color!
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.hint),
          const SizedBox(width: 6),
          Text(label, style: TextDesign.smallText(color: theme.onSurface)),
        ],
      ),
    );
  }
}
