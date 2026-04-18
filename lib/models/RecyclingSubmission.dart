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
      rejectionReason: json['rejection_reason'],        // ✅ fixed
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      pointAward: json['point_award'] != null ? (json['point_award'] as num).toDouble() : null, // ✅ fixed
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
      'status': status,                                 // ✅ fixed
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String().split('T').first, // store only date
      if (categoryId != null) 'category_id': categoryId,
      if (rejectionReason != null) 'rejection_reason': rejectionReason, // ✅ fixed
      if (weight != null) 'weight': weight,
      if (pointAward != null) 'point_award': pointAward, // ✅ fixed
    };
  }
}