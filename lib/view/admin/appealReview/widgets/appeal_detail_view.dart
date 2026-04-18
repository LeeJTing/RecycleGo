import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/appeal_controller.dart';
import 'package:recycle_go/models/Appeals.dart';

class AppealDetailView extends StatefulWidget {
  final Appeals appeal;
  const AppealDetailView({super.key, required this.appeal});

  @override
  State<AppealDetailView> createState() => _AppealDetailViewState();
}

class _AppealDetailViewState extends State<AppealDetailView> {
  final AppealController _controller = AppealController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pointsController.text = (widget.appeal.pointsGiven ?? (widget.appeal.submissionPoints?.toInt() ?? 0)).toString();
    _commentController.text = widget.appeal.adminComment ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final isPending = widget.appeal.appealStatus.toLowerCase() == 'pending';

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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Header
                if (widget.appeal.photoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Image.network(
                          widget.appeal.photoUrl!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        if (widget.appeal.photoCount > 1)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_library, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${widget.appeal.photoCount} Photos",
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.image_not_supported, size: 50, color: theme.hint),
                  ),
                
                const SizedBox(height: 24),
                
                // User & Date
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primary.withOpacity(0.1),
                      radius: 24,

                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.appeal.userName ?? 'Unknown User', style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold)),
                        Text(widget.appeal.userEmail ?? '', style: TextDesign.smallText(color: theme.hint)),
                      ],
                    ),
                    const Spacer(),
                    _buildStatusBadge(widget.appeal.appealStatus, theme),
                  ],
                ),
                
                const SizedBox(height: 24),
                Text("Appeal Reason", style: TextDesign.headingThree()),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.border),
                  ),
                  child: Text(widget.appeal.appealReason, style: TextDesign.normalText()),
                ),
                
                const SizedBox(height: 24),
                Text("Submission Info", style: TextDesign.headingThree()),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.pin_drop, "Station", widget.appeal.stationName ?? 'N/A', theme),
                _buildInfoRow(Icons.category, "Category", widget.appeal.category ?? 'N/A', theme),
                _buildInfoRow(Icons.scale, "Weight", "${widget.appeal.weight?.toStringAsFixed(2) ?? '0'} kg", theme),
                _buildInfoRow(Icons.stars, "Original Points", "${widget.appeal.submissionPoints?.toInt() ?? 0} pts", theme),
                
                if (isPending) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text("Review Action", style: TextDesign.headingTwo()),
                  const SizedBox(height: 16),
                  Text("Points to Award", style: TextDesign.smallText(color: theme.hint)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pointsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter points",
                      fillColor: theme.surface,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Admin Comment", style: TextDesign.smallText(color: theme.hint)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Add a comment for the user",
                      fillColor: theme.surface,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _handleAction('approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("APPROVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _handleAction('rejected'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.error,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("REJECT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ] else ...[
                  const SizedBox(height: 24),
                  Text("Admin Review", style: TextDesign.headingThree()),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.stars, "Points Awarded", "${widget.appeal.pointsGiven ?? 0} pts", theme),
                  _buildInfoRow(Icons.comment, "Admin Comment", widget.appeal.adminComment ?? 'No comment', theme),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, AppColors theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.primary),
          const SizedBox(width: 12),
          Text(label, style: TextDesign.smallText(color: theme.hint)),
          const Spacer(),
          Text(value, style: TextDesign.normalText().copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppColors theme) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = theme.success; break;
      case 'rejected': color = theme.error; break;
      default: color = theme.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _handleAction(String status) async {
    setState(() => _isLoading = true);
    try {
      await _controller.updateAppealStatus(
        widget.appeal,
        status,
        points: int.tryParse(_pointsController.text),
        comment: _commentController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Appeal ${status == 'approved' ? 'approved' : 'rejected'} successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e")),
        );
      }
    }
  }
}
