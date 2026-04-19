import 'package:recycle_go/models/Connector.dart';

class DashboardController extends Connector {
  static final DashboardController _instance = DashboardController._internal();

  DashboardController._internal();

  factory DashboardController() => _instance;

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      // 1. Get Total Active Users
      // Matches your 'users' table and 'account_status' column
      final userResponse = await client
          .from('users')
          .select('user_id')
          .eq('account_status', 'active');

      final int totalActiveUsers = userResponse.length;

      // 2. Get Total Weight Recycled
      // Matches your 'recycle_submissions' table and 'weight' column
      final weightResponse = await client
          .from('recycle_submissions')
          .select('weight')
          .eq('status', 'approved');

      double totalWeight = weightResponse.fold(0.0, (sum, item) {
        return sum + ((item['weight'] as num?)?.toDouble() ?? 0.0);
      });

      // 3. Get Total Revenue
      // Matches your 'recyclepurchases' table and 'total_price' column
      final revenueResponse = await client
          .from('recyclepurchases')
          .select('total_price')
          .eq('payment_status', 'success');

      double totalRevenue = revenueResponse.fold(0.0, (sum, item) {
        return sum + ((item['total_price'] as num?)?.toDouble() ?? 0.0);
      });

      // 4. Get Points Liability
      // Matches your 'users' table and 'total_points' column
      final pointsResponse = await client
          .from('users')
          .select('total_points');

      int pointsLiability = pointsResponse.fold(0, (sum, item) {
        return sum + ((item['total_points'] as num?)?.toInt() ?? 0);
      });

      // Return the map exactly as the UI expects it
      return {
        'totalActiveUsers': totalActiveUsers,
        'totalWeightRecycled': totalWeight,
        'totalRevenue': totalRevenue,
        'pointsLiability': pointsLiability,
      };

    } catch (e) {
      print('Error fetching dashboard stats: $e');
      rethrow;
    }
  }
}