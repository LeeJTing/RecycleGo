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
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appeal.appealStatus.toUpperCase(),
                  style: TextDesign.badgeText(color: statusColor, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoTile(
              label: "Submission ID",
              value: appeal.submissionId,
              icon: Icons.assignment_outlined,
              theme: theme,
            ),
            _buildInfoTile(
              label: "Created At",
              value: appeal.createdAt != null ? _formatDate(appeal.createdAt!) : "N/A",
              icon: Icons.calendar_today_outlined,
              theme: theme,
            ),
            _buildInfoTile(
              label: "Appeal Reason",
              value: appeal.appealReason,
              icon: Icons.help_outline,
              theme: theme,
            ),
            if (appeal.appealStatus == 'approved' && appeal.pointsGiven != null)
              _buildInfoTile(
                label: "Points Given",
                value: "+${appeal.pointsGiven} pts",
                icon: Icons.stars,
                theme: theme,
                valueColor: theme.success,
              ),
            if (appeal.adminComment != null && appeal.adminComment!.isNotEmpty)
              _buildInfoTile(
                label: "Admin Comment",
                value: appeal.adminComment!,
                icon: Icons.comment_outlined,
                theme: theme,
              ),
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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextDesign.label()),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextDesign.normalText(color: valueColor ?? theme.onSurface).copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
