import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/RecyclingSubmission.dart';

class AdminSubmissionFullReview extends StatefulWidget {
  const AdminSubmissionFullReview({super.key});

  @override
  State<AdminSubmissionFullReview> createState() => _AdminSubmissionFullReviewState();
}

class _AdminSubmissionFullReviewState extends State<AdminSubmissionFullReview> {
  List<RecycleSubmission> _submissions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  // --- DATABASE LOGIC ---

  Future<void> _fetchSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('recyclingsubmission')
          .select()
          .order('submitted_at', ascending: false);

      final List<RecycleSubmission> fetched = [];
      for (var json in response) {
        fetched.add(RecycleSubmission.fromJson(json));
      }
      setState(() {
        _submissions = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(RecycleSubmission submission, String newStatus,
      {String? rejectionReason}) async {
    final supabase = Supabase.instance.client;
    final adminId = supabase.auth.currentUser!.id;

    if (submission.submissionId == null) {
      throw Exception('Submission ID is null');
    }

    try {
      // Update submission
      await supabase.from('recyclingsubmission').update({
        'status': newStatus,
        'reviewed_by': adminId,
        'reviewed_at': DateTime.now().toIso8601String().split('T').first, // date only
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      }).eq('submission_id', submission.submissionId!);

      // Insert review history
      await supabase.from('submission_reviews').insert({
        'submission_id': submission.submissionId,
        'action': newStatus,
        'comment': rejectionReason ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'admin_id': adminId,
        'user_id': submission.userId,
      });

      await _fetchSubmissions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission $newStatus successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // --- DIALOGS ---

  void _showRejectDialog(RecycleSubmission submission) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Submission', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Reason for rejection...',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(ctx);
                _updateStatus(submission, 'rejected', rejectionReason: reasonController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditPointsDialog(RecycleSubmission submission) {
    final pointsController = TextEditingController(
        text: (submission.pointAward ?? 0).toStringAsFixed(0)
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Points & Approve', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: pointsController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Points to award',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final newPoints = double.tryParse(pointsController.text);
              if (newPoints != null) {
                Navigator.pop(ctx);
                final supabase = Supabase.instance.client;
                final adminId = supabase.auth.currentUser!.id;
                if (submission.submissionId == null) return;
                try {
                  await supabase.from('recyclingsubmission').update({
                    'status': 'approved',
                    'point_award': newPoints,
                    'reviewed_by': adminId,
                    'reviewed_at': DateTime.now().toIso8601String().split('T').first,
                  }).eq('submission_id', submission.submissionId!);

                  await supabase.from('submission_reviews').insert({
                    'submission_id': submission.submissionId,
                    'action': 'approved',
                    'comment': 'Points adjusted to $newPoints',
                    'created_at': DateTime.now().toIso8601String(),
                    'admin_id': adminId,
                    'user_id': submission.userId,
                  });

                  await _fetchSubmissions();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Submission approved with custom points')),
                    );
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Submission Reviews", style: TextDesign.appBarTitle()),
        backgroundColor: theme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSubmissions,
        color: theme.primary,
        child: _buildBodyContent(theme),
      ),
    );
  }

  Widget _buildBodyContent(AppColors theme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.primary));
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error', style: TextStyle(color: theme.error)));
    }
    if (_submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: theme.hint),
            const SizedBox(height: 16),
            Text('No submissions found', style: TextDesign.mediumText(color: theme.hint)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _submissions.length,
      itemBuilder: (ctx, index) {
        return _buildSubmissionCard(_submissions[index], theme);
      },
    );
  }

  Widget _buildSubmissionCard(RecycleSubmission submission, AppColors theme) {
    // Status comparisons using strings
    final isPending = submission.status == 'pending';
    final isRejected = submission.status == 'rejected';

    // Format date safely
    String dateFormatted = "Unknown Date";
    final date = submission.submittedAt;
    if (date != null) {
      dateFormatted = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }

    // Shorten submission ID
    final shortId = submission.submissionId != null && submission.submissionId!.length >= 8
        ? submission.submissionId!.substring(0, 8).toUpperCase()
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Info & Image
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100, height: 100,
                    color: theme.surfaceVariant,
                    child: (submission.photoUrl != null && submission.photoUrl!.isNotEmpty)
                        ? Image.network(
                      submission.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: theme.hint),
                    )
                        : Icon(Icons.recycling, color: theme.primary, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Sub ID: $shortId",
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.onSurface, fontSize: 14),
                            ),
                          ),
                          _buildStatusBadge(submission.status, theme),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Submitted: $dateFormatted", style: TextStyle(color: theme.hint, fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatItem("Weight", "${submission.weight ?? 0.0} kg", theme),
                          const SizedBox(width: 16),
                          _buildStatItem("Points", "${submission.pointAward ?? 0} pts", theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Rejection Reason Banner
          if (isRejected && submission.rejectionReason != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.error.withOpacity(0.05),
                border: Border(top: BorderSide(color: theme.error.withOpacity(0.1))),
              ),
              child: Text(
                "Reason: ${submission.rejectionReason}",
                style: TextStyle(color: theme.error, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),

          // Action Buttons (only for pending)
          if (isPending)
            Container(
              decoration: BoxDecoration(
                color: theme.surfaceVariant.withOpacity(0.3),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(submission),
                      icon: Icon(Icons.close, color: theme.error, size: 18),
                      label: Text("Reject", style: TextStyle(color: theme.error)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.error.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showEditPointsDialog(submission),
                    icon: Icon(Icons.edit_note, color: theme.warning),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.warning.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(submission, 'approved'),
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: const Text("Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.success,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, AppColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.hint, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: theme.onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusBadge(String status, AppColors theme) {
    Color badgeColor;
    if (status == 'approved') {
      badgeColor = theme.success;
    } else if (status == 'rejected') {
      badgeColor = theme.error;
    } else {
      badgeColor = theme.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}