import 'package:recycle_go/models/Connector.dart';
import 'package:flutter/foundation.dart';

class Appeals {
  final String? appealId;
  final String submissionId;
  final String appealReason;
  final int? pointsGiven;
  final String appealStatus;
  final String? adminComment;
  final DateTime? createdAt;
  
  // Join fields from recyclingsubmission and related tables
  final String? userName; 
  final String? userEmail;
  final String? photoUrl;
  final String? stationId;
  final String? stationName;
  final String? category;
  final double? weight;
  final double? submissionPoints;
  final int photoCount;

  Appeals({
    this.appealId,
    required this.submissionId,
    required this.appealReason,
    this.pointsGiven,
    required this.appealStatus,
    this.adminComment,
    this.createdAt,
    this.userName,
    this.userEmail,
    this.photoUrl,
    this.stationId,
    this.stationName,
    this.category,
    this.weight,
    this.submissionPoints,
    this.photoCount = 0,
  });

  factory Appeals.fromJson(Map<String, dynamic> json) {
    final sub = json['recyclingsubmission'];
    final user = sub?['users'];
    final station = sub?['recyclestation'];
    final categoryData = sub?['recycle_category'];

    // In the provided schema, recyclingsubmission has weight and point_award directly
    final weight = (sub?['weight'] as num?)?.toDouble() ?? 0.0;
    final points = (sub?['point_award'] as num?)?.toDouble() ?? 0.0;
    final categoryName = categoryData?['category_name'] ?? 'General';

    return Appeals(
      appealId: json['appeal_id'],
      submissionId: json['submission_id'],
      appealReason: json['appeal_reason'] ?? '',
      pointsGiven: (json['points_given'] as num?)?.toInt(),
      appealStatus: json['appeal_status'],
      adminComment: json['admin_comment'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      userName: user?['user_name'],
      userEmail: user?['email'],
      // photoUrl now comes directly from recyclingsubmission as submissionphotos table was dropped
      photoUrl: sub?['photo_url'],
      stationId: sub?['station_id'],
      stationName: station?['station_name'],
      category: categoryName,
      weight: weight,
      submissionPoints: points,
      photoCount: sub?['photo_url'] != null ? 1 : 0, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submission_id': submissionId,
      'appeal_reason': appealReason,
      'points_given': pointsGiven,
      'appeal_status': appealStatus,
      'admin_comment': adminComment,
    };
  }

  Appeals copyWith({
    String? appealId,
    String? submissionId,
    String? appealReason,
    int? pointsGiven,
    String? appealStatus,
    String? adminComment,
    DateTime? createdAt,
    String? userName,
    String? userEmail,
    String? photoUrl,
    String? stationId,
    String? stationName,
    String? category,
    double? weight,
    double? submissionPoints,
    int? photoCount,
  }) {
    return Appeals(
      appealId: appealId ?? this.appealId,
      submissionId: submissionId ?? this.submissionId,
      appealReason: appealReason ?? this.appealReason,
      pointsGiven: pointsGiven ?? this.pointsGiven,
      appealStatus: appealStatus ?? this.appealStatus,
      adminComment: adminComment ?? this.adminComment,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      photoUrl: photoUrl ?? this.photoUrl,
      stationId: stationId ?? this.stationId,
      stationName: stationName ?? this.stationName,
      category: category ?? this.category,
      weight: weight ?? this.weight,
      submissionPoints: submissionPoints ?? this.submissionPoints,
      photoCount: photoCount ?? this.photoCount,
    );
  }
}

class AppealsModel extends Connector {
  static final AppealsModel _instance = AppealsModel._internal();
  AppealsModel._internal();
  factory AppealsModel() => _instance;

  Future<List<Appeals>> getUserAppeals(String userId) async {
    try {
      final response = await client
          .from('appeals')
          .select('*, recyclingsubmission!inner(user_id, station_id, weight, point_award, photo_url, users!inner(user_name, email), recyclestation!inner(station_name), recycle_category(category_name))')
          .eq('recyclingsubmission.user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Appeals.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error in getUserAppeals: $e");
      return [];
    }
  }

  Future<List<Appeals>> getAllAppeals() async {
    try {
      final response = await client
          .from('appeals')
          .select('*, recyclingsubmission!inner(station_id, weight, point_award, photo_url, users!inner(user_name, email), recyclestation!inner(station_name), recycle_category(category_name))')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Appeals.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error in getAllAppeals: $e");
      return [];
    }
  }

  Future<void> updateAppeal(Appeals appeal) async {
    await client
        .from('appeals')
        .update({
          'appeal_status': appeal.appealStatus,
          'points_given': appeal.pointsGiven,
          'admin_comment': appeal.adminComment,
          'reviewed_at': DateTime.now().toIso8601String().split('T')[0], // date only
        })
        .eq('appeal_id', appeal.appealId!);
  }
}
