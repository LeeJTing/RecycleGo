import 'package:recycle_go/models/Connector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SubmissionStatus {
  pending,
  approved,
  rejected,
}

extension SubmissionStatusExt on SubmissionStatus {
  String get string => name;
  static SubmissionStatus fromString(String s) =>
      SubmissionStatus.values.firstWhere((e) => e.string == s, orElse: () => SubmissionStatus.pending);
}

class RecycleSubmission {
  final String? submissionId;
  final DateTime? submittedAt;
  final String userId;
  final String stationId;
  final String? photoUrl;            // nullable in SQL
  final String status;               // 'pending', 'approved', 'rejected'
  final String? reviewedBy;
  final DateTime? reviewedAt;        // SQL: date (no time)
  final int? categoryId;
  final String? rejectionReason;     // matches SQL column
  final double? weight;
  final double? pointAward;          // renamed from totalAwardedPoints
  SubmissionStatus get statusEnum => SubmissionStatusExt.fromString(status);

  RecycleSubmission({
    this.submissionId,
    this.submittedAt,
    required this.userId,
    required this.stationId,
    this.photoUrl,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedAt,
    this.categoryId,
    this.rejectionReason,
    this.weight,
    this.pointAward,
  });

  factory RecycleSubmission.fromJson(Map<String, dynamic> json) {
    return RecycleSubmission(
      submissionId: json['submission_id'],
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      userId: json['user_id'],
      stationId: json['station_id'],
      photoUrl: json['photo_url'],
      status: json['status'] ?? 'pending',
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      categoryId: json['category_id'],
      rejectionReason: json['rejection_reason'],
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      pointAward: json['point_award'] != null ? (json['point_award'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'user_id': userId,
      'station_id': stationId,
      if (photoUrl != null) 'photo_url': photoUrl,
      'status': status,
      if (categoryId != null) 'category_id': categoryId,
      if (weight != null) 'weight': weight,
      if (pointAward != null) 'point_award': pointAward,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      if (submissionId != null) 'submission_id': submissionId,
      'user_id': userId,
      'station_id': stationId,
      if (photoUrl != null) 'photo_url': photoUrl,
      'status': status,
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String().split('T').first, // store only date
      if (categoryId != null) 'category_id': categoryId,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (weight != null) 'weight': weight,
      if (pointAward != null) 'point_award': pointAward,
    };
  }
}

class RecycleSubmissionModel extends Connector {
  static final RecycleSubmissionModel _instance =
  RecycleSubmissionModel._internal();

  RecycleSubmissionModel._internal();

  factory RecycleSubmissionModel() => _instance;

  final String _table = 'recycle_submissions';

  Future<List<RecycleSubmission>> fetchAll() async {
    try {
      final response = await client
          .from(_table)
          .select()
          .order('submitted_at', ascending: false);

      return _mapList(response);
    } catch (e) {
      throw Exception('Fetch All Submissions Failed: $e');
    }
  }

  Future<RecycleSubmission?> fetchById(String id) async {
    try {
      final response = await client
          .from(_table)
          .select()
          .eq('submission_id', id)
          .maybeSingle();

      if (response == null) return null;

      return RecycleSubmission.fromJson(response);
    } catch (e) {
      throw Exception('Fetch Submission By ID Failed: $e');
    }
  }

  Future<List<RecycleSubmission>> fetchByUser(String userId) async {
    try {
      final response = await client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      return _mapList(response);
    } catch (e) {
      throw Exception('Fetch User Submissions Failed: $e');
    }
  }

  Future<RecycleSubmission?> create(RecycleSubmission item) async {
    try {
      final response = await client
          .from(_table)
          .insert(item.toJsonForInsert())
          .select()
          .single();

      return RecycleSubmission.fromJson(response);
    } catch (e) {
      throw Exception('Create Submission Failed: $e');
    }
  }

  Future<RecycleSubmission?> update(
      String id,
      Map<String, dynamic> data,
      ) async {
    try {
      final response = await client
          .from(_table)
          .update(data)
          .eq('submission_id', id)
          .select()
          .single();

      return RecycleSubmission.fromJson(response);
    } catch (e) {
      throw Exception('Update Submission Failed: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await client
          .from(_table)
          .delete()
          .eq('submission_id', id);
    } catch (e) {
      throw Exception('Delete Submission Failed: $e');
    }
  }

  Future<List<RecycleSubmission>> fetchByStatus(String status) async {
    try {
      final response = await client
          .from(_table)
          .select()
          .eq('status', status)
          .order('submitted_at', ascending: false);

      return _mapList(response);
    } catch (e) {
      throw Exception('Fetch By Status Failed: $e');
    }
  }

  List<RecycleSubmission> _mapList(dynamic response) {
    return (response as List)
        .map((e) => RecycleSubmission.fromJson(e))
        .toList();
  }

  Future<void> createSubmission(RecycleSubmission submission) async {
    await client.from('recyclingsubmission').insert(submission.toJsonForInsert());
  }

  Future<int> getTotalItemsByUserId(String userId) async {
    final response = await client
        .from('recyclingsubmission')
        .count(CountOption.exact)
        .eq('user_id', userId)
        .eq('status', 'approved');
    return response;
  }

  Future<int> getStreakCount(String userId) async {
    try {
      final response = await client
          .from('recyclingsubmission')
          .select('submitted_at')
          .eq('user_id', userId)
          .eq('status', 'approved')
          .order('submitted_at', ascending: false);

      if (response == null || (response as List).isEmpty) return 0;

      final submissions = response as List;
      final uniqueDates = submissions.map((s) {
        final date = DateTime.parse(s['submitted_at']);
        return DateTime(date.year, date.month, date.day);
      }).toSet().toList();

      if (uniqueDates.isEmpty) return 0;

      // Sort just in case, although DB should have handled it
      uniqueDates.sort((a, b) => b.compareTo(a));

      DateTime today = DateTime.now();
      DateTime todayDate = DateTime(today.year, today.month, today.day);
      DateTime yesterdayDate = todayDate.subtract(const Duration(days: 1));

      // If the latest submission isn't today or yesterday, streak is broken
      if (uniqueDates[0].isBefore(yesterdayDate)) {
        return 0;
      }

      int streak = 1;
      for (int i = 0; i < uniqueDates.length - 1; i++) {
        if (uniqueDates[i].difference(uniqueDates[i + 1]).inDays == 1) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }
}
