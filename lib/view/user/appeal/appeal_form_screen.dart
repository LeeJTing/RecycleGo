import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class AppealPage extends StatefulWidget {
  final String submissionId;

  const AppealPage({super.key, required this.submissionId});

  @override
  State<AppealPage> createState() => _AppealPageState();
}

class _AppealPageState extends State<AppealPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _reasonController = TextEditingController();

  bool isLoading = true;
  bool isSubmitting = false;

  Map<String, dynamic>? appealData;
  Map<String, dynamic>? submissionData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1️⃣ Get submission - CHANGED BACK to 'recyclingsubmission'
      final submission = await supabase
          .from('recyclingsubmission')
          .select()
          .eq('submission_id', widget.submissionId)
          .single();

      // 2️⃣ Check existing appeal
      final appeal = await supabase
          .from('appeals')
          .select()
          .eq('submission_id', widget.submissionId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          submissionData = submission;
          appealData = appeal;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading appeal data: $e");
      if (mounted) {
        setState(() => isLoading = false);
        // Show the error on screen so we know what broke!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load submission: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitAppeal() async {
    if (_reasonController.text.trim().isEmpty) return;

    setState(() => isSubmitting = true);

    try {
      await supabase.from('appeals').insert({
        'submission_id': widget.submissionId,
        'appeal_reason': _reasonController.text.trim(),
        'appeal_status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appeal submitted successfully"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // --- UI HELPERS ---
  Color _getStatusColor(String status, AppColors theme) {
    switch (status) {
      case 'approved':
        return theme.success;
      case 'rejected':
        return theme.error;
      case 'pending':
        return theme.warning;
      default:
        return theme.hint;
    }
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSubmissionInfo(AppColors theme) {
    if (submissionData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.error.withOpacity(0.5)),
        ),
        child: Text(
          "Could not load submission data. Please check your database connection or table name.",
          style: TextDesign.normalText(color: theme.error),
        ),
      );
    }

    final status = (submissionData!['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final statusColor = _getStatusColor(status, theme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Submission Details", style: TextDesign.headingThree()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow("Weight", "${submissionData!['weight']?.toStringAsFixed(1) ?? '0.0'} kg", theme),
          const SizedBox(height: 8),
          _buildDetailRow("Points", "${submissionData!['point_award'] ?? '0'}", theme),

          if (submissionData!['rejection_reason'] != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow("Reason", submissionData!['rejection_reason'], theme, isError: true),
          ],

          if (submissionData!['photo_url'] != null) ...[
            const SizedBox(height: 20),
            Text("Attached Photo", style: TextDesign.label()),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                submissionData!['photo_url'],
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: theme.surfaceVariant,
                  child: Center(child: Icon(Icons.broken_image_outlined, color: theme.hint)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppealStatus(AppColors theme) {
    final status = appealData!['appeal_status']?.toString() ?? 'Pending';
    final statusColor = _getStatusColor(status, theme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text("Appeal Status", style: TextDesign.headingThree(color: statusColor)),
            ],
          ),
          const SizedBox(height: 16),

          _buildDetailRow("Current Status", status.toUpperCase(), theme, customColor: statusColor),
          const SizedBox(height: 8),
          _buildDetailRow("Your Reason", appealData!['appeal_reason'] ?? '', theme),

          if (appealData!['admin_comment'] != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildDetailRow("Admin Reply", appealData!['admin_comment'], theme),
          ],

          if (appealData!['points_given'] != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow("Points Awarded", "+${appealData!['points_given']}", theme, customColor: theme.success),
          ],
        ],
      ),
    );
  }

  Widget _buildForm(AppColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Submit an Appeal", style: TextDesign.headingThree()),
        const SizedBox(height: 8),
        Text(
          "If you believe your submission was rejected by mistake, please explain why below.",
          style: TextDesign.normalText(color: theme.hint),
        ),
        const SizedBox(height: 16),

        Text("Appeal Reason *", style: TextDesign.label()),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          maxLines: 4,
          style: TextDesign.normalText(),
          decoration: InputDecoration(
            hintText: "E.g., The items were cleaned properly before submission...",
            hintStyle: TextDesign.hintText(),
            filled: true,
            fillColor: theme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),

        if (appealData!['admin_comment'] != null) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildDetailRow(
            "Admin Reply",
            appealData!['admin_comment']?.toString().isNotEmpty == true
                ? appealData!['admin_comment']
                : "No response yet",
            theme,
          ),
        ],

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _submitAppeal,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("SUBMIT APPEAL", style: TextDesign.buttonText()),
          ),
        ),
      ],
    );
  }


  Widget _buildDetailRow(String label, String value, AppColors theme, {bool isError = false, Color? customColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextDesign.smallText(color: theme.hint)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextDesign.normalText(color: customColor ?? (isError ? theme.error : theme.onSurface))
                .copyWith(fontWeight: isError || customColor != null ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Submission Appeal", style: TextDesign.appBarTitle()),
        backgroundColor: theme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubmissionInfo(theme),
            const SizedBox(height: 32),

            appealData != null
                ? _buildAppealStatus(theme)
                : _buildForm(theme),
          ],
        ),
      ),
    );
  }
}