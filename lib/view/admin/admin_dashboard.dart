import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/services/supabase_service.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/view/admin/purchase/admin_view_purchase.dart';
import 'package:recycle_go/view/admin/admin_voucher_management.dart';
import 'package:recycle_go/view/admin/admin_pending_vouchers.dart';

import 'category/admin_recycle_category.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final VoucherCtrl _voucherCtrl = VoucherCtrl();
  List<Vouchers> _sampleVouchers = [];
  List<RedeemedVouchers> _pendingVouchers = [];
  bool _isLoading = false;

  // Mock Data
  final int _totalActiveUsers = 1245;
  final double _totalWeightRecycled = 8450.5;
  final double _totalRevenue = 15230.00;
  final int _pointsLiability = 450000;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadData();
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  Future<void> _loadData() async {
    try {
      await _voucherCtrl.fetchVouchers();
      await _loadPendingVouchers();

      if (mounted) {
        setState(() {
          if (_voucherCtrl.vouchers.isNotEmpty) {
            _sampleVouchers = _voucherCtrl.vouchers.take(1).toList();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _loadPendingVouchers() async {
    try {
      final supabase = SupabaseService().client;
      final response = await supabase
          .from('redeemedvouchers')
          .select()
          .eq('voucher_status', 'pending')
          .order('redeemed_at', ascending: false);

      if (mounted) {
        setState(() {
          _pendingVouchers = (response as List).map((v) => RedeemedVouchers.fromJson(v)).toList();
        });
      }
    } catch (e) {
      debugPrint("Pending Vouchers Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    // Notice there is NO Scaffold here! The AdminHome provides the Scaffold.
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // --- 1. KPI GRID ---
            _buildKPIGrid(theme),
            const SizedBox(height: 32),

            // --- 3. MANAGEMENT TILES ---
            Text("System Management", style: TextDesign.headingThree()),
            const SizedBox(height: 16),

            _buildManagementTile(
              context,
              icon: Icons.people_outline,
              title: "User Management",
              subtitle: "Manage and block users",
              route: Routes.adminUserManagement,
              theme: theme,
            ),
            const SizedBox(height: 8),

            Consumer<AdminProvider>(
              builder: (context, provider, _) {
                if (provider.admin?.role.toLowerCase() == 'super admin') {
                  return Column(
                    children: [
                      _buildManagementTile(
                        context,
                        icon: Icons.admin_panel_settings_outlined,
                        title: "Admin Management",
                        subtitle: "Add or inactive admins",
                        route: Routes.adminManagement,
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            _buildManagementTile(
              context,
              icon: Icons.gavel_outlined,
              title: "Appeal Review",
              subtitle: "Review user appeal submissions",
              route: Routes.adminAppealReview,
              theme: theme,
            ),

            const SizedBox(height: 32),
            Text("Voucher Management", style: TextDesign.headingThree()),
            const SizedBox(height: 16),

            _buildManagementTile(
              context,
              icon: Icons.card_giftcard_outlined,
              title: "Available Vouchers",
              subtitle: "${_voucherCtrl.vouchers.where((v) => v.voucherStatus?.toLowerCase() == 'active').length} active vouchers",
              route: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVoucherManagement()));
                await _loadData(); // Reload when returning
              },
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildManagementTile(
              context,
              icon: Icons.pending_actions_outlined,
              title: "Pending Vouchers",
              subtitle: "${_pendingVouchers.length} pending requests",
              route: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPendingVouchers()));
                await _loadPendingVouchers(); // Reload when returning
              },
              theme: theme,
            ),

            const SizedBox(height: 32),
            Text("Category Management", style: TextDesign.headingThree()),
            const SizedBox(height: 16),

            _buildManagementTile(
              context,
              icon: Icons.category_outlined,
              title: "Category Management",
              subtitle: "Define materials, labels, and AI points",
              route: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminRecycleCategory()),
                );
              },

              theme: theme,
            ),

            const SizedBox(height: 32),
            Text("Purchase Management", style: TextDesign.headingThree()),
            const SizedBox(height: 16),

            _buildManagementTile(
              context,
              icon: Icons.category_outlined,
              title: "Purchase Management",
              subtitle: "Review and update user sales requests",
              route: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminViewPurchase()),
                );
              },
              theme: theme,
            ),
            const SizedBox(height: 32),

            // --- 2. CHART SECTION ---
            Text("30-Day Growth Trends", style: TextDesign.headingThree()),
            const SizedBox(height: 16),
            _buildGrowthChart(theme),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid(AppColors theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKPICard(theme: theme, title: "Active Users", value: _totalActiveUsers.toString(), icon: Icons.people_outline, iconColor: Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard(theme: theme, title: "Weight Recycled", value: "${_totalWeightRecycled.toStringAsFixed(1)} kg", icon: Icons.eco_outlined, iconColor: theme.success)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildKPICard(theme: theme, title: "Total Revenue", value: "RM ${_totalRevenue.toStringAsFixed(2)}", icon: Icons.attach_money, iconColor: theme.primary)),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard(theme: theme, title: "Points Liability", value: _pointsLiability.toString(), icon: Icons.account_balance_wallet_outlined, iconColor: Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard({required AppColors theme, required String title, required String value, required IconData icon, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: theme.hint, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(AppColors theme) {
    return Container(
      height: 300,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 16, bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 20.0),
            child: Row(
              children: [
                _buildLegendItem("Users", Colors.blue),
                const SizedBox(width: 16),
                _buildLegendItem("Submissions", theme.success),
              ],
            ),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (value) => FlLine(color: theme.border.withOpacity(0.3), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (value, meta) {
                    const style = TextStyle(color: Colors.grey, fontSize: 10);
                    switch (value.toInt()) {
                      case 0: return const Text('Week 1', style: style);
                      case 2: return const Text('Week 2', style: style);
                      case 4: return const Text('Week 3', style: style);
                      case 6: return const Text('Week 4', style: style);
                      default: return const Text('');
                    }
                  })),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 40, getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                  })),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 6, minY: 0, maxY: 6,
                lineBarsData: [
                  LineChartBarData(spots: const [FlSpot(0, 1), FlSpot(1, 1.5), FlSpot(2, 1.4), FlSpot(3, 3.4), FlSpot(4, 2), FlSpot(5, 2.2), FlSpot(6, 4.8)], isCurved: true, color: Colors.blue, barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1))),
                  LineChartBarData(spots: const [FlSpot(0, 0.5), FlSpot(1, 1), FlSpot(2, 1.8), FlSpot(3, 2.5), FlSpot(4, 4), FlSpot(5, 3.5), FlSpot(6, 5.5)], isCurved: true, color: theme.success, barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: theme.success.withOpacity(0.1))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildManagementTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required dynamic route, required AppColors theme}) {
    return Card(
      elevation: 0,
      color: theme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.border)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: theme.primary),
        ),
        title: Text(title, style: TextDesign.largeText()),
        subtitle: Text(subtitle, style: TextDesign.smallText()),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.hint),
        onTap: () {
          if (route is String) {
            Navigator.pushNamed(context, route);
          } else if (route is Function) {
            route();
          }
        },
      ),
    );
  }
}