import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';
import 'package:recycle_go/controller/redeemed_voucher/redeemed_voucher_ctrl.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/view/voucher/voucher_view_all.dart';
import 'package:recycle_go/view/voucher/voucher_helpers.dart';
import 'package:recycle_go/view/voucher/voucher_card.dart';
import 'package:recycle_go/view/voucher/redeem_dialog.dart';

class VoucherManagement extends StatefulWidget {
  final int currentPoints;
  final int goalPoints;
  final String memberRank;
  final String nextRank;

  const VoucherManagement({
    super.key,
    this.currentPoints = 0,
    this.goalPoints = 2000,
    this.memberRank = 'BRONZE MEMBER',
    this.nextRank = 'SILVER RANK',
  });

  @override
  State<VoucherManagement> createState() => _VoucherManagementState();
}

class _VoucherManagementState extends State<VoucherManagement> {
  final VoucherCtrl _voucherCtrl = VoucherCtrl();
  String _filterStatus = 'active'; // Always active for users
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Vouchers> _filteredVouchers = [];

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _searchController.addListener(_filterVouchers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    try {
      await _voucherCtrl.fetchVouchers();
      _filterVouchers();
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading vouchers'),
            backgroundColor: theme.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _filterVouchers() {
    final query = _searchController.text.toLowerCase();
    final vouchers = _voucherCtrl.vouchers
        .where(
          (v) =>
              (v.voucherStatus == 'active') && // Only show active vouchers
              (widget.currentPoints >=
                  v.pointsRequired) && // User must have enough points
              (v.voucherName.toLowerCase().contains(query) ||
                  (v.description?.toLowerCase().contains(query) ?? false)),
        )
        .toList();

    setState(() {
      _filteredVouchers = vouchers;
    });
  }

  void _redeemVoucher(Vouchers voucher) {
    final canRedeem = widget.currentPoints >= voucher.pointsRequired;

    if (!canRedeem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You need ${VoucherHelpers.formatWithCommas(voucher.pointsRequired - widget.currentPoints)} more points',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final theme = AppThemes.color;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final redeemCtrl = RedeemVoucherCtrl();

    showRedeemDialog(
      context: context,
      voucher: voucher,
      onRedeem: () async {
        try {
          // Generate unique sequential voucher code
          final voucherCode = await redeemCtrl.generateNextVoucherCode(
            voucher.voucherId ?? '',
          );

          // Create redeemed voucher record with generated code
          final redeemedVoucher = RedeemedVouchers(
            voucherCode: voucherCode,
            userId: userProvider.user?.userId ?? '',
            voucherId: voucher.voucherId ?? '',
            voucherStatus: RedeemedVoucherStatus.unused,
            redeemedAt: DateTime.now(),
          );

          // Save to database
          await redeemCtrl.addRedeemedVoucher(redeemedVoucher);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Voucher redeemed! Code: $voucherCode'),
                backgroundColor: theme.primary,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to redeem voucher: $e'),
                backgroundColor: theme.error,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors theme = AppThemes.color;
    Size size = MediaQuery.of(context).size;
    final progress = widget.currentPoints / widget.goalPoints;

    return _isLoading
        ? Center(child: CircularProgressIndicator(color: theme.primary))
        : SingleChildScrollView(
            child: Column(
              children: [
                // Current Balance Section
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06,
                    vertical: size.height * 0.04,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primary,
                          theme.primary.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(
                            Icons.card_giftcard,
                            size: 96,
                            color: theme.onPrimary.withOpacity(0.18),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Balance',
                              style: TextDesign.smallText(
                                color: theme.onPrimary.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: TextDesign.headingOne(
                                  color: theme.onPrimary,
                                  fontSize: 28,
                                ),
                                children: [
                                  TextSpan(
                                    text: VoucherHelpers.formatWithCommas(
                                      widget.currentPoints,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' pts',
                                    style: TextDesign.smallText(
                                      color: theme.onPrimary.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: theme.onPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.nextRank} Goal',
                                  style: TextDesign.smallText(
                                    color: theme.onPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${VoucherHelpers.formatWithCommas(widget.currentPoints)} / ${VoucherHelpers.formatWithCommas(widget.goalPoints)}',
                                  style: TextDesign.smallText(
                                    color: theme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0, 1),
                                minHeight: 8,
                                backgroundColor: theme.onPrimary.withOpacity(
                                  0.25,
                                ),
                                valueColor: AlwaysStoppedAnimation(
                                  theme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  widget.memberRank,
                                  style: TextDesign.smallText(
                                    color: theme.onPrimary.withOpacity(0.95),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'NEXT: ${widget.nextRank}',
                                  style: TextDesign.smallText(
                                    color: theme.onPrimary.withOpacity(0.95),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Search & Filter Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06,
                    vertical: size.height * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search vouchers...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: theme.onPrimary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Featured Rewards Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06,
                    vertical: size.height * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Vouchers',
                                  style: TextDesign.headingTwo(),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Redeem your hard-earned points for eco-benefits.',
                                  style: TextDesign.smallText(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_filteredVouchers.length > 2)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VoucherViewAllScreen(
                                      currentPoints: widget.currentPoints,
                                      goalPoints: widget.goalPoints,
                                      memberRank: widget.memberRank,
                                      nextRank: widget.nextRank,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                'View All',
                                style: TextDesign.smallText(
                                  color: theme.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_filteredVouchers.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No vouchers available',
                              style: TextDesign.normalText(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredVouchers.length > 2
                                  ? 2
                                  : _filteredVouchers.length,
                              itemBuilder: (context, index) {
                                final voucher = _filteredVouchers[index];
                                final category =
                                    voucher.description ?? 'Exchange';

                                return VoucherCard(
                                  voucher: voucher,
                                  category: category,
                                  onRedeemPressed: () =>
                                      _redeemVoucher(voucher),
                                );
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
