import 'package:recycle_go/models/Connector.dart';

class RecycleSubmission {
  final String? submissionId;
  final DateTime? submittedAt;
  final String userId;
  final String stationId;
  final String photoUrl;
  final String status; // 'pending', 'approved', 'rejected'

  // Admin & Categorization Fields
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final int? categoryId;       // Converted to camelCase for Dart
  final String? reasonName;    // Converted to camelCase for Dart
  final String? adminNotes;    // Restored this variable

  final double? weight;
  final double totalAwardedPoints;

  // Attached 1:N Relationship
  final List<DetectedItem> detectedItems;

  RecycleSubmission({
    this.submissionId,
    this.submittedAt,
    required this.userId,
    required this.stationId,
    required this.photoUrl,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedAt,
    this.categoryId,
    this.reasonName,
    this.adminNotes,
    this.weight,
    this.totalAwardedPoints = 0.0, // Fixed default to double
    this.detectedItems = const [], // Restored to constructor!
  });

  // Convert from Supabase JSON to Dart Object
  factory RecycleSubmission.fromJson(Map<String, dynamic> json) {
    return RecycleSubmission(
      submissionId: json['submission_id'],
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      userId: json['user_id'],
      stationId: json['station_id'],
      photoUrl: json['photo_url'],
      status: json['submission_status'] ?? 'pending',

      // Admin Fields
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      categoryId: json['category_id'],
      reasonName: json['reason_name'],
      adminNotes: json['admin_notes'],

      // Safely parse numbers (Supabase can sometimes return int or double)
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      totalAwardedPoints: json['total_awarded_points'] != null ? (json['total_awarded_points'] as num).toDouble() : 0.0,

      // Map relational data safely
      detectedItems: json['detecteditems'] != null
          ? (json['detecteditems'] as List).map((i) => DetectedItem.fromJson(i)).toList()
          : [],
    );
  }

  // Convert Dart Object to JSON for Supabase Insertions/Updates
  Map<String, dynamic> toJson() {
    return {
      if (submissionId != null) 'submission_id': submissionId,
      'user_id': userId,
      'station_id': stationId,
      'photo_url': photoUrl,
      'submission_status': status,
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt?.toIso8601String(),
      if (categoryId != null) 'category_id': categoryId,
      if (reasonName != null) 'reason_name': reasonName,
      if (adminNotes != null) 'admin_notes': adminNotes,
      if (weight != null) 'weight': weight,
      'total_awarded_points': totalAwardedPoints,
    };
  }
}

class DetectedItem {
  final String? itemId;
  final String? submissionId;
  final String aiItemType;
  final double aiDetectedWeightKg;
  final double aiConfidenceScore;
  final String? adminCorrectedType;
  final double? adminCorrectedWeightKg;
  final bool isCorrected;

  DetectedItem({
    this.itemId,
    this.submissionId,
    required this.aiItemType,
    required this.aiDetectedWeightKg,
    required this.aiConfidenceScore,
    this.adminCorrectedType,
    this.adminCorrectedWeightKg,
    this.isCorrected = false,
  });

  factory DetectedItem.fromJson(Map<String, dynamic> json) {
    return DetectedItem(
      itemId: json['item_id'],
      submissionId: json['submission_id'],
      aiItemType: json['ai_item_type'],
      aiDetectedWeightKg: (json['ai_detected_weight_kg'] as num).toDouble(),
      aiConfidenceScore: (json['ai_confidence_score'] as num).toDouble(),
      adminCorrectedType: json['admin_corrected_type'],
      adminCorrectedWeightKg: json['admin_corrected_weight_kg'] != null ? (json['admin_corrected_weight_kg'] as num).toDouble() : null,
      isCorrected: json['is_corrected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    if (submissionId != null) 'submission_id': submissionId,
    'ai_item_type': aiItemType,
    'ai_detected_weight_kg': aiDetectedWeightKg,
    'ai_confidence_score': aiConfidenceScore,
    if (adminCorrectedType != null) 'admin_corrected_type': adminCorrectedType,
    if (adminCorrectedWeightKg != null) 'admin_corrected_weight_kg': adminCorrectedWeightKg,
    'is_corrected': isCorrected,
  };
}

class RecycleSubmissionModel extends Connector {

  Future<RecycleSubmission?> createSubmission(RecycleSubmission submission) async {
    try {
      final submissionResponse = await client
          .from('recyclingsubmission')
          .insert(submission.toJson())
          .select()
          .single();

      final String newSubmissionId = submissionResponse['submission_id'];

      if (submission.detectedItems.isNotEmpty) {
        final itemsToInsert = submission.detectedItems.map((i) {
          final json = i.toJson();
          json['submission_id'] = newSubmissionId;
          return json;
        }).toList();

        await client.from('detecteditems').insert(itemsToInsert);
      }

      return await getSubmissionDetails(newSubmissionId);
    } catch (e) {
      print("Error creating submission: $e");
      rethrow; // Good practice to rethrow so the UI can show an error popup!
    }
  }

  Future<List<RecycleSubmission>> getUserSubmissions(String userId) async {
    try {
      final response = await client
          .from('recyclingsubmission')
          .select('*, detecteditems(*)')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      return (response as List).map((json) => RecycleSubmission.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching user submissions: $e");
      return [];
    }
  }

  /// 💻 ADMIN FUNCTION: Get all pending submissions
  Future<List<RecycleSubmission>> getPendingSubmissions() async {
    try {
      final response = await client
          .from('recyclingsubmission')
          .select('*, detecteditems(*)')
          .eq('submission_status', 'pending')
          .order('submitted_at', ascending: true);

      return (response as List).map((json) => RecycleSubmission.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching pending submissions: $e");
      return [];
    }
  }

  /// 💻 ADMIN FUNCTION: Save Admin Review (Approve/Reject)
  Future<bool> updateSubmissionReview(RecycleSubmission updatedSubmission) async {
    if (updatedSubmission.submissionId == null) return false;

    try {
      await client
          .from('recyclingsubmission')
          .update(updatedSubmission.toJson())
          .eq('submission_id', updatedSubmission.submissionId!);
      return true;
    } catch (e) {
      print("Error updating submission: $e");
      return false;
    }
  }

  /// 🔄 HELPER FUNCTION: Get a single submission by ID
  Future<RecycleSubmission?> getSubmissionDetails(String submissionId) async {
    try {
      final response = await client
          .from('recyclingsubmission')
          .select('*, detecteditems(*)')
          .eq('submission_id', submissionId)
          .single();

      return RecycleSubmission.fromJson(response);
    } catch (e) {
      print("Error fetching submission details: $e");
      return null;
    }
  }
}