import 'package:recycle_go/models/Connector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecyclingSubmission {
  final String? submissionId;
  final DateTime submittedAt;
  final String userId;
  final String stationId;

  RecyclingSubmission({
    this.submissionId,
    required this.submittedAt,
    required this.userId,
    required this.stationId,
  });

  factory RecyclingSubmission.fromJson(Map<String, dynamic> json) {
    return RecyclingSubmission(
      submissionId: json['submission_id'],
      submittedAt: DateTime.parse(json['submitted_at']),
      userId: json['user_id'],
      stationId: json['station_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'submitted_at': submittedAt.toIso8601String(),
      'user_id': userId,
      'station_id': stationId,
    };
    if (submissionId != null) data['submission_id'] = submissionId;
    return data;
  }
}

class RecyclingSubmissionModel extends Connector {
  static final RecyclingSubmissionModel _instance = RecyclingSubmissionModel._internal();
  factory RecyclingSubmissionModel() => _instance;
  RecyclingSubmissionModel._internal();

  Future<int> getTotalSubmissionsByUserId(String userId) async {
    try {
      final response = await client
          .from('recyclingsubmission')
          .count(CountOption.exact)
          .eq('user_id', userId);
      
      return response;
    } catch (e) {
      print('DEBUG: Error fetching total submissions: $e');
      return 0;
    }
  }

  Future<List<RecyclingSubmission>> getSubmissionsByUserId(String userId) async {
    final response = await client
        .from('recyclingsubmission')
        .select()
        .eq('user_id', userId)
        .order('submitted_at', ascending: false);
    
    return (response as List).map((json) => RecyclingSubmission.fromJson(json)).toList();
  }
}
