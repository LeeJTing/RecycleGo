import 'package:flutter/material.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/controller/redeemed_voucher/redeemed_voucher_ctrl.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'admin_voucher_info_tab.dart';
import 'admin_voucher_stats_tab.dart';
import 'admin_voucher_history_tab.dart';

class AdminVoucherDetails extends StatefulWidget {
  final Vouchers voucher;

  const AdminVoucherDetails({super.key, required this.voucher});

  @override
  State<AdminVoucherDetails> createState() => _AdminVoucherDetailsState();
}

class _AdminVoucherDetailsState extends State<AdminVoucherDetails> {
  late RedeemVoucherCtrl _redeemedVoucherCtrl;
  late VoucherCtrl _voucherCtrl;
  late Vouchers _currentVoucher;
  List<RedeemedVouchers> _redeemedVouchers = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0 = Info, 1 = Stats, 2 = History

  @override
  void initState() {
    super.initState();
    _currentVoucher = widget.voucher;
    _redeemedVoucherCtrl = RedeemVoucherCtrl();
    _voucherCtrl = VoucherCtrl();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch fresh voucher data from database
      await _voucherCtrl.fetchVouchers();
      final freshVoucher = _voucherCtrl.vouchers.firstWhere(
        (v) => v.voucherId == widget.voucher.voucherId,
        orElse: () => widget.voucher,
      );

      setState(() {
        _currentVoucher = freshVoucher;
      });

      // Load redeemed vouchers
      await _redeemedVoucherCtrl.fetchRedeemedVouchers(
        voucherId: _currentVoucher.voucherId,
      );
      setState(() {
        _redeemedVouchers = _redeemedVoucherCtrl.redeemedVouchers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Get icon and color based on voucher category
  Map<String, dynamic> _getCategoryIconAndColor() {
    switch (_currentVoucher.voucherCategory.toLowerCase()) {
      case 'food':
        return {
          'icon': Icons.restaurant,
          'color': const Color(0xFFFF6B6B), // Red/Orange
        };
      case 'shopping':
        return {
          'icon': Icons.shopping_bag,
          'color': const Color(0xFF4ECDC4), // Teal
        };
      case 'exchange':
        return {
          'icon': Icons.attach_money,
          'color': const Color(0xFF2ECC71), // Green
        };
      default:
        return {
          'icon': Icons.card_giftcard,
          'color': const Color(0xFF6C5CE7), // Purple
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text('Voucher Details', style: TextDesign.appBarTitle()),
        backgroundColor: theme.onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(theme),
            const SizedBox(height: 24),

            // Tab Bar
            _buildTabBar(theme),
            const SizedBox(height: 24),

            // Tab Content
            if (_selectedTab == 0)
              AdminVoucherInfoTab(voucher: _currentVoucher),
            if (_selectedTab == 1)
              AdminVoucherStatsTab(
                redeemedVouchers: _redeemedVouchers,
                totalVouchersAvailable: _currentVoucher.numberOfVouchers,
              ),
            if (_selectedTab == 2)
              AdminVoucherHistoryTab(
                redeemedVouchers: _redeemedVouchers,
                isLoading: _isLoading,
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.onPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryIconAndColor()['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIconAndColor()['icon'],
                  color: _getCategoryIconAndColor()['color'],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentVoucher.voucherName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _currentVoucher.voucherStatus == 'active'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _currentVoucher.voucherStatus.toUpperCase(),
                        style: TextStyle(
                          color: _currentVoucher.voucherStatus == 'active'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentVoucher.description.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  _currentVoucher.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppColors theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.onPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab(theme, 'Info', 0),
          _buildTab(theme, 'Stats', 1),
          _buildTab(theme, 'History', 2),
        ],
      ),
    );
  }

  Widget _buildTab(AppColors theme, String label, int tabIndex) {
    final isFirst = tabIndex == 0;
    final isLast = tabIndex == 2;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: _selectedTab == tabIndex
                ? theme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isFirst ? 12 : 0),
              bottomLeft: Radius.circular(isFirst ? 12 : 0),
              topRight: Radius.circular(isLast ? 12 : 0),
              bottomRight: Radius.circular(isLast ? 12 : 0),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: _selectedTab == tabIndex
                    ? Colors.white
                    : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
