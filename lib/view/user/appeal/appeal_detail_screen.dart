import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Appeals.dart';

class AppealDetailScreen extends StatelessWidget {
  final Appeals appeal;

  const AppealDetailScreen({super.key, required this.appeal});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    Color statusColor;
    switch (appeal.appealStatus.toLowerCase()) {
      case 'approved': statusColor = theme.success; break;
      case 'rejected': statusColor = theme.error; break;
      default: statusColor = theme.warning;
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Appeal Details", style: TextDesign.appBarTitle()),
        backgroundColor: theme.onPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --- SECTION 1: STATUS & RESOLUTION ---
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  appeal.appealStatus.toUpperCase(),
                  style: TextDesign.badgeText(color: statusColor, fontSize: 16).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Show Resolution details at the top if the admin has responded
            if (appeal.appealStatus != 'pending') ...[
              Text("Admin Resolution", style: TextDesign.sectionHeader()),
              const SizedBox(height: 12),
              if (appeal.appealStatus == 'approved' && appeal.pointsGiven != null)
                _buildInfoTile(
                  label: "Points Recovered",
                  value: "+${appeal.pointsGiven} pts",
                  icon: Icons.stars,
                  theme: theme,
                  valueColor: theme.success,
                ),
              if (appeal.adminComment != null && appeal.adminComment!.isNotEmpty)
                _buildInfoTile(
                  label: "Admin Comment",
                  value: appeal.adminComment!,
                  icon: Icons.forum_outlined,
                  theme: theme,
                ),
              const SizedBox(height: 24),
              Divider(color: theme.border),
              const SizedBox(height: 24),
            ],

            // --- SECTION 2: THE USER's APPEAL ---
            Text("Your Appeal", style: TextDesign.sectionHeader()),
            const SizedBox(height: 12),
            _buildInfoTile(
              label: "Submitted On",
              value: appeal.createdAt != null ? _formatDate(appeal.createdAt!) : "N/A",
              icon: Icons.calendar_today_outlined,
              theme: theme,
            ),
            _buildInfoTile(
              label: "Reason for Appeal",
              value: appeal.appealReason,
              icon: Icons.edit_note,
              theme: theme,
            ),

            const SizedBox(height: 24),
            Divider(color: theme.border),
            const SizedBox(height: 24),

            // --- SECTION 3: ORIGINAL SUBMISSION CONTEXT ---
            Text("Original Submission", style: TextDesign.sectionHeader()),
            const SizedBox(height: 12),

            // TIP: Replace this with actual nested data from your backend
            // e.g., appeal.submission.stationName
            _buildInfoTile(
              label: "Submission Reference",
              value: "ID: ${appeal.submissionId.substring(0, 8)}...", // Truncate the UUID to make it prettier
              icon: Icons.assignment_outlined,
              theme: theme,
            ),
            // Example of what you SHOULD show if you fetch joined data:
            /*
            _buildInfoTile(
              label: "Station & Weight",
              value: "${appeal.submission.stationName} • ${appeal.submission.weight}kg",
              icon: Icons.recycling,
              theme: theme,
            ),
            */
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required AppColors theme,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextDesign.label(color: theme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextDesign.normalText(color: valueColor ?? theme.onSurface).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}