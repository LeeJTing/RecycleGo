import 'package:recycle_go/models/Appeals.dart';
import 'package:recycle_go/services/notification_service.dart';

class AppealController {
  final AppealsModel _model = AppealsModel();
  final NotificationService _notificationService = NotificationService();

  Future<List<Appeals>> getAllAppeals() async {
    return await _model.getAllAppeals();
  }

  Future<void> updateAppealStatus(Appeals appeal, String status, String adminId, {double? points, String? comment}) async {
    final updatedAppeal = appeal.copyWith(
      appealStatus: status,
      pointsGiven: points,
      adminComment: comment,
      adminId: adminId,
    );
    
    // Update the appeal record
    await _model.updateAppeal(updatedAppeal);

    // Send notification to user
    if (appeal.submission?.userId != null) {
      await _notificationService.notifyAppealUpdate(
        userId: appeal.submission!.userId,
        adminId: adminId,
        status: status,
        points: points,
      );
    }
  }

  Future<void> approveAppeal(Appeals appeal, String adminId, double points, String comment) async {
    await updateAppealStatus(appeal, 'approved', adminId, points: points, comment: comment);
  }

  Future<void> rejectAppeal(Appeals appeal, String adminId, String comment) async {
    await updateAppealStatus(appeal, 'rejected', adminId, comment: comment);
  }
}
