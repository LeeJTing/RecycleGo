import 'package:supabase_flutter/supabase_flutter.dart';

class SubmissionService {
  final SupabaseClient supabase = Supabase.instance.client;

// Create submission
  Future<void> createSubmission(Map<String, dynamic> data) async {
    await supabase.from('recyclingsubmission').insert(data);
  }

// Get all submissions
  Future<List<Map<String, dynamic>>> getSubmissions() async {
    final response = await supabase
        .from('recyclingsubmission')
        .select()
        .order('submitted_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);

  }

// Get submissions by user
  Future<List<Map<String, dynamic>>> getUserSubmissions(String userId) async {
    final response = await supabase
        .from('recyclingsubmission')
        .select()
        .eq('user_id', userId)
        .order('submitted_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);

  }

// Approve submission
  Future<void> approveSubmission(
      String submissionId, double points, String adminId) async {
    await supabase.from('recyclingsubmission').update({
      'status': 'approved',
      'point_award': points,
      'reviewedBy': adminId,
      'reviewedAt': DateTime.now().toIso8601String(),
    }).eq('submission_id', submissionId);
  }

// Reject submission
  Future<void> rejectSubmission(
      String submissionId, String adminId, String reason) async {
    await supabase.from('recyclingsubmission').update({
      'status': 'rejected',
      'reviewedBy': adminId,
      'reviewedAt': DateTime.now().toIso8601String(),
      'rejection_reason': reason,
    }).eq('submission_id', submissionId);
  }
}

class SubmissionController {
  final SubmissionService _service = SubmissionService();

// Submit recycling
  Future<void> submitRecycling({
    required String userId,
    required String stationId,
    required int categoryId,
    required double weight,
  }) async {
    final data = {
      'user_id': userId,
      'station_id': stationId,
      'category_id': categoryId,
      'weight': weight,
      'submitted_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    };

    await _service.createSubmission(data);

  }

// Get user submissions
  Future<List<Map<String, dynamic>>> getUserSubmissions(String userId) async {
    return await _service.getUserSubmissions(userId);
  }

// Approve submission
  Future<void> approveSubmission(
      String submissionId, double points, String adminId) async {
    await _service.approveSubmission(submissionId, points, adminId);
  }

// Reject submission
  Future<void> rejectSubmission(
      String submissionId, String adminId, String reason) async {
    await _service.rejectSubmission(submissionId, adminId, reason);
  }
}

