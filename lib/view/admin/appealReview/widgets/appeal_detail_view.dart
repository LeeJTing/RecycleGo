import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/appeal_controller.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/models/Appeals.dart';
import 'package:recycle_go/provider/AdminProvider.dart';

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
    _pointsController.text = (widget.appeal.pointsGiven ?? (widget.appeal.submission?.pointAward ?? 0)).toString();
    _commentController.text = widget.appeal.adminComment ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final isPending = widget.appeal.appealStatus.toLowerCase() == 'pending';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Appeal Details", style: TextDesign.appBarTitle()),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Image Section with Status Overlay
                  _buildImageHeader(theme),

                  const SizedBox(height: 20),

                  // User Info Section
                  _buildUserInfo(theme),

                  const SizedBox(height: 20),

                  // Chips Section (Station, Category, Weight)
                  _buildChips(theme),

                  const SizedBox(height: 24),

                  // Appeal Reason
                  _buildSectionTitle("APPEAL REASON"),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Text(
                      widget.appeal.appealReason,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Points Input Section (Reward point entry)
                  if (isPending) _buildPointsInputSection(theme),

                  const SizedBox(height: 20),

                  // Reward Banner (Displaying the value from input)
                  _buildRewardBanner(theme),

                  const SizedBox(height: 24),

                  // Admin Comment Section
                  if (isPending) ...[
                    _buildSectionTitle("ADMIN COMMENT"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Add a note for the user...",
                        fillColor: const Color(0xFFF8F9FA),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // Buttons Section
                  if (isPending)
                    _buildActionButtons(theme)
                  else
                    _buildCompletedReview(theme),

                  const SizedBox(height: 40),
                ],
              ),
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

  Widget _buildImageHeader(AppColors theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Image.network(
            widget.appeal.submission?.photoUrl ?? '',
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 280,
              width: double.infinity,
              color: const Color(0xFFF1F3F5),
              child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Text(
              widget.appeal.appealStatus[0].toUpperCase() + widget.appeal.appealStatus.substring(1).toLowerCase(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(AppColors theme) {
    final date = widget.appeal.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(widget.appeal.createdAt!)
        : 'N/A';
    final time = widget.appeal.createdAt != null
        ? DateFormat('HH:mm a').format(widget.appeal.createdAt!)
        : '';

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],
          backgroundImage: widget.appeal.user?.profilePhoto != null
              ? NetworkImage(widget.appeal.user!.getUserProfileURL())
              : null,
          child: widget.appeal.user?.profilePhoto == null
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.appeal.user?.userName ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "$date • $time",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChips(AppColors theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.appeal.station?.stationName ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.recycling, size: 20, color: Color(0xFF409167)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.appeal.categoryName ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.scale_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "Weight: ${widget.appeal.submission?.weight?.toStringAsFixed(2) ?? '0'} kg",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "ID: ${widget.appeal.submissionId.substring(0, 8).toUpperCase()}",
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPointsInputSection(AppColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stars_rounded, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            const Text(
              "REWARD POINT",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pointsController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            fillColor: const Color(0xFFF8F9FA),
            filled: true,
            hintText: "Enter points to award...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Admin can manually set the points to be awarded for this appeal.",
          style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildRewardBanner(AppColors theme) {
    final pointsText = _pointsController.text.trim();
    final double? val = double.tryParse(pointsText);
    final String displayValue = pointsText.isEmpty ? '0' : (val == null ? 'Invalid' : pointsText);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F3DC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Reward",
            style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Row(
            children: [
              Text(
                displayValue,
                style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(width: 4),
              const Text(
                "pts",
                style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppColors theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => _handleAction('approved'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              side: const BorderSide(color: Color(0xFFE9ECEF)),
            ),
            child: const Text(
              "Approve",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _handleAction('rejected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF05050),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text(
              "Reject",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Logic to edit or recalculate points can be added here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8F9FA),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text(
              "Edit",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedReview(AppColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        _buildSectionTitle("ADMIN REVIEW"),
        const SizedBox(height: 12),
        _buildReviewRow(Icons.stars, "Points Awarded", "${widget.appeal.pointsGiven?.toInt() ?? 0} pts"),
        _buildReviewRow(Icons.comment, "Comment", widget.appeal.adminComment ?? 'No comment'),
        _buildReviewRow(Icons.person, "Reviewed By", widget.appeal.reviewer?.username ?? 'N/A'),
      ],
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF409167)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _handleAction(String status) async {
    final admin = Provider.of<AdminProvider>(context, listen: false).admin;
    if (admin == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin session not found")));
      return;
    }

    double? points;
    if (status == 'approved') {
      final pointsText = _pointsController.text.trim();
      points = double.tryParse(pointsText);
      if (points == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid numeric value for points")),
        );
        return;
      }
    } else {
      // If rejected, do not update pointsGiven (pass null)
      points = null;
    }

    setState(() => _isLoading = true);
    try {
      await _controller.updateAppealStatus(
        widget.appeal,
        status,
        admin.adminId!,
        points: points,
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
