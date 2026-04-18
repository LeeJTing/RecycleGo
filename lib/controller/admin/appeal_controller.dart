import 'package:recycle_go/models/Appeals.dart';

class AppealController {
  final AppealsModel _model = AppealsModel();

  Future<List<Appeals>> getAllAppeals() async {
    return await _model.getAllAppeals();
  }

  Future<void> updateAppealStatus(Appeals appeal, String status, {int? points, String? comment}) async {
    final updatedAppeal = appeal.copyWith(
      appealStatus: status,
      pointsGiven: points,
      adminComment: comment,
    );
    await _model.updateAppeal(updatedAppeal);
  }

  Future<void> approveAppeal(Appeals appeal, int points, String comment) async {
    await updateAppealStatus(appeal, 'approved', points: points, comment: comment);
  }

  Future<void> rejectAppeal(Appeals appeal, String comment) async {
    await updateAppealStatus(appeal, 'rejected', comment: comment);
  }
}
