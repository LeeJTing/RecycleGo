import 'package:recycle_go/models/Connector.dart';

class DashboardController extends Connector {
  static final DashboardController _instance = DashboardController._internal();

  DashboardController._internal();

  factory DashboardController() => _instance;

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      print("📊 --- DASHBOARD FETCH START ---");

      // 1. ACTIVE USERS
      final userResponse = await client
          .from('users')
          .select('user_id')
          .ilike('account_status', 'active'); // ilike ignores upper/lowercase

      final int totalActiveUsers = (userResponse as List).length;
      print("👥 Active Users Found: $totalActiveUsers");

      // 2. WEIGHT RECYCLED
      // ⚠️ Make sure 'recyclingsubmission' matches your actual Supabase table name!
      final weightResponse = await client
          .from('recyclingsubmission')
          .select('weight')
          .ilike('status', 'approved'); // ilike ignores upper/lowercase

      final weightList = weightResponse as List;
      print("⚖️ Approved Submissions Found: ${weightList.length}");

      double totalWeight = weightList.fold(0.0, (sum, item) {
        return sum + ((item['weight'] as num?)?.toDouble() ?? 0.0);
      });

      // 3. TOTAL REVENUE
      final revenueResponse = await client
          .from('recyclepurchases')
          .select('total_price')
          .ilike('payment_status', 'success'); // ilike ignores upper/lowercase

      final revenueList = revenueResponse as List;
      print("💰 Successful Purchases Found: ${revenueList.length}");

      double totalRevenue = revenueList.fold(0.0, (sum, item) {
        return sum + ((item['total_price'] as num?)?.toDouble() ?? 0.0);
      });

      // 4. POINTS LIABILITY
      final pointsResponse = await client
          .from('users')
          .select('total_points');

      final pointsList = pointsResponse as List;
      print("🎁 Total User Wallets Found: ${pointsList.length}");

      int pointsLiability = pointsList.fold(0, (sum, item) {
        return sum + ((item['total_points'] as num?)?.toInt() ?? 0);
      });

      print("📊 --- DASHBOARD FETCH COMPLETE ---");

      return {
        'totalActiveUsers': totalActiveUsers,
        'totalWeightRecycled': totalWeight,
        'totalRevenue': totalRevenue,
        'pointsLiability': pointsLiability,
      };

    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      rethrow;
    }
  }
}