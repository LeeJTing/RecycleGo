import 'package:recycle_go/models/Connector.dart';
import 'package:flutter/foundation.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/models/RecyclingSubmission.dart';
import 'package:recycle_go/models/RecycleStations.dart';

class Appeals {
  final String? appealId;
  final String submissionId;
  final String appealReason;
  final double? pointsGiven;
  final String appealStatus;
  final String? adminComment;
  final String? adminId;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  
  // Nested Objects
  final Users? user;
  final RecycleSubmission? submission;
  final RecycleStation? station;
  final String? categoryName;
  final Admins? reviewer;

  Appeals({
    this.appealId,
    required this.submissionId,
    required this.appealReason,
    this.pointsGiven,
    required this.appealStatus,
    this.adminComment,
    this.adminId,
    this.createdAt,
    this.reviewedAt,
    this.user,
    this.submission,
    this.station,
    this.categoryName,
    this.reviewer,
  });

  factory Appeals.fromJson(Map<String, dynamic> json) {
    // Supabase nested selects often return objects or lists of objects
    // depending on the relationship.
    
    // 1. Get the submission data
    var subData = json['recyclingsubmission'];
    if (subData is List && subData.isNotEmpty) {
      subData = subData[0];
    }
    
    // 2. Extract nested objects from submission data
    final userJson = subData?['users'];
    final stationJson = subData?['recyclestation'];
    
    // Handle category name from different possible structures
    var categoryData = subData?['recycle_category'];
    if (categoryData is List && categoryData.isNotEmpty) {
      categoryData = categoryData[0];
    }
    final String? categoryName = categoryData?['category_name'];

    // Handle admin (reviewer)
    var adminJson = json['admins'];
    if (adminJson is List && adminJson.isNotEmpty) {
      adminJson = adminJson[0];
    }

    return Appeals(
      appealId: json['appeal_id'],
      submissionId: json['submission_id'],
      appealReason: json['appeal_reason'] ?? '',
      pointsGiven: (json['points_given'] as num?)?.toDouble(),
      appealStatus: json['appeal_status'],
      adminComment: json['admin_comment'],
      adminId: json['admin_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      
      user: userJson != null ? Users.fromJson(userJson) : null,
      submission: subData != null ? RecycleSubmission.fromJson(subData) : null,
      station: stationJson != null ? RecycleStation.fromJson(stationJson) : null,
      categoryName: categoryName,
      reviewer: adminJson != null ? Admins.fromJson(adminJson) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submission_id': submissionId,
      'appeal_reason': appealReason,
      'points_given': pointsGiven,
      'appeal_status': appealStatus,
      'admin_comment': adminComment,
      'admin_id': adminId,
      'reviewed_at': reviewedAt?.toIso8601String().split('T').first,
    };
  }

  Appeals copyWith({
    String? appealId,
    String? submissionId,
    String? appealReason,
    double? pointsGiven,
    String? appealStatus,
    String? adminComment,
    String? adminId,
    DateTime? createdAt,
    DateTime? reviewedAt,
    Users? user,
    RecycleSubmission? submission,
    RecycleStation? station,
    String? categoryName,
    Admins? reviewer,
  }) {
    return Appeals(
      appealId: appealId ?? this.appealId,
      submissionId: submissionId ?? this.submissionId,
      appealReason: appealReason ?? this.appealReason,
      pointsGiven: pointsGiven ?? this.pointsGiven,
      appealStatus: appealStatus ?? this.appealStatus,
      adminComment: adminComment ?? this.adminComment,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      user: user ?? this.user,
      submission: submission ?? this.submission,
      station: station ?? this.station,
      categoryName: categoryName ?? this.categoryName,
      reviewer: reviewer ?? this.reviewer,
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
          .select('*, recyclingsubmission!inner(*, users(*), recyclestation(*), recycle_category(category_name)), admins(*)')
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
      // Ensure we are selecting all necessary fields for nested parsing
      final response = await client
          .from('appeals')
          .select('''
            *,
            admins(*),
            recyclingsubmission!inner(
              *,
              users(*),
              recyclestation(*),
              recycle_category(category_name)
            )
          ''')
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
          'admin_id': appeal.adminId,
          'reviewed_at': DateTime.now().toIso8601String().split('T')[0], // date only
        })
        .eq('appeal_id', appeal.appealId!);
  }
}
