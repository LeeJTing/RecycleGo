import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';
import 'package:recycle_go/controller/redeemed_voucher/redeemed_voucher_ctrl.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/view/voucher/voucher_view_all.dart';
import 'package:recycle_go/view/voucher/redeemed_voucher_view_all.dart';
import 'package:recycle_go/view/voucher/voucher_helpers.dart';
import 'package:recycle_go/view/voucher/voucher_card.dart';
import 'package:recycle_go/view/voucher/redeem_dialog.dart';
import 'package:recycle_go/view/voucher/redeemed_voucher_card.dart';
import 'package:recycle_go/view/voucher/redeemed_voucher_dialogs.dart';
import 'package:recycle_go/view/voucher/voucher_use_confirmation_screen.dart';
import 'package:recycle_go/view/voucher/qr_code_helpers.dart';

class _RankTier {
  final String rankName;
  final int minPoints;
  final String? nextRankName;
  final int? nextRankGoal;

  const _RankTier({
    required this.rankName,
    required this.minPoints,
    this.nextRankName,
    this.nextRankGoal,
  });
}

class _RankProgress {
  final String currentRank;
  final String? nextRank;
  final int? nextGoal;
  final double progress;

  const _RankProgress({
    required this.currentRank,
    required this.nextRank,
    required this.nextGoal,
    required this.progress,
  });
}

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
  static const List<_RankTier> _rankTiers = [
    _RankTier(
      rankName: 'BRONZE MEMBER',
      minPoints: 0,
      nextRankName: 'SILVER RANK',
      nextRankGoal: 2000,
    ),
    _RankTier(
      rankName: 'SILVER MEMBER',
      minPoints: 2000,
      nextRankName: 'GOLD RANK',
      nextRankGoal: 5000,
    ),
    _RankTier(
      rankName: 'GOLD MEMBER',
      minPoints: 5000,
      nextRankName: 'PLATINUM RANK',
      nextRankGoal: 10000,
    ),
    _RankTier(rankName: 'PLATINUM MEMBER', minPoints: 10000),
  ];

  final VoucherCtrl _voucherCtrl = VoucherCtrl();
  final RedeemVoucherCtrl _redeemCtrl = RedeemVoucherCtrl();
  final UsersModel _usersModel = UsersModel();
  String _filterStatus = 'active'; // Always active for users
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Vouchers> _filteredVouchers = [];
  List<RedeemedVouchers> _userRedeemedVouchers = [];

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _loadRedeemedVouchers();
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
      await _refreshCurrentUserPoints();
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

  Future<void> _refreshCurrentUserPoints() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    if (currentUser?.userId == null) {
      return;
    }

    try {
      final latestUser = await _usersModel.client
          .from('users')
          .select()
          .eq('user_id', currentUser!.userId!)
          .maybeSingle();

      if (latestUser != null && mounted) {
        userProvider.setUser(Users.fromJson(latestUser));
      }
    } catch (_) {
      // Keep existing local value if refresh fails.
    }
  }

  void _filterVouchers() {
    final query = _searchController.text.toLowerCase();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentPoints =
        userProvider.user?.totalPoints ?? widget.currentPoints;

    final vouchers = _voucherCtrl.vouchers
        .where(
          (v) =>
              (v.voucherStatus == 'active') && // Only show active vouchers
              (currentPoints >=
                  v.pointsRequired) && // User must have enough points
              (v.voucherName.toLowerCase().contains(query) ||
                  (v.description.toLowerCase().contains(query))),
        )
        .toList();

    setState(() {
      _filteredVouchers = vouchers;
    });
  }

  void _redeemVoucher(Vouchers voucher) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentPoints =
        userProvider.user?.totalPoints ?? widget.currentPoints;
    final canRedeem = currentPoints >= voucher.pointsRequired;

    if (!canRedeem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You need ${VoucherHelpers.formatWithCommas(voucher.pointsRequired - currentPoints)} more points',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final theme = AppThemes.color;

    showRedeemDialog(
      context: context,
      voucher: voucher,
      onRedeem: () async {
        try {
          // Use transaction to redeem voucher with points deduction
          final voucherCode = await _redeemCtrl.redeemVoucherWithTransaction(
            user: userProvider.user!,
            voucher: voucher,
            userId: userProvider.user?.userId ?? '',
            voucherId: voucher.voucherId ?? '',
          );

          // Update UserProvider with new points
          final updatedUser = userProvider.user!.copyWith(
            totalPoints:
                userProvider.user!.totalPoints - voucher.pointsRequired,
          );
          userProvider.setUser(updatedUser);

          // Reload vouchers to filter ineligible ones with new points
          await _loadVouchers();

          // Reload redeemed vouchers
          await _loadRedeemedVouchers();

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

  Future<void> _loadRedeemedVouchers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.userId;

    if (userId == null) {
      return;
    }

    try {
      await _redeemCtrl.fetchRedeemedVouchersByUser(userId);
      setState(() {
        _userRedeemedVouchers = _redeemCtrl.redeemedVouchers;
      });
    } catch (e) {
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading redeemed vouchers'),
            backgroundColor: theme.error,
          ),
        );
      }
    }
  }

  void _updateStatusAndShare(RedeemedVouchers redeemedVoucher) async {
    try {
      // Share voucher with QR code image
      await QRCodeHelpers.shareVoucherWithQRImage(
        voucherCode: redeemedVoucher.voucherCode,
        voucherName: redeemedVoucher.voucherCode,
      );

      // Update status to shared
      await _redeemCtrl.updateRedeemedVoucherStatus(
        redeemedVoucher.voucherCode,
        RedeemedVoucherStatus.shared,
      );
      await _loadRedeemedVouchers();

      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Voucher shared successfully!'),
            backgroundColor: theme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share voucher: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
    }
  }

  void _handleUseVoucher(RedeemedVouchers redeemedVoucher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoucherUseConfirmationScreen(
          voucherCode: redeemedVoucher.voucherCode,
          onSuccess: _loadRedeemedVouchers,
        ),
      ),
    );
  }

  _RankProgress _resolveRankProgress(int points) {
    var activeTier = _rankTiers.first;
    for (final tier in _rankTiers) {
      if (points >= tier.minPoints) {
        activeTier = tier;
      }
    }

    if (activeTier.nextRankGoal == null) {
      return _RankProgress(
        currentRank: activeTier.rankName,
        nextRank: null,
        nextGoal: null,
        progress: 1.0,
      );
    }

    final currentRangeStart = activeTier.minPoints;
    final nextGoal = activeTier.nextRankGoal!;
    final range = nextGoal - currentRangeStart;
    final double normalizedProgress = range <= 0
        ? 1.0
        : ((points - currentRangeStart) / range).clamp(0, 1).toDouble();

    return _RankProgress(
      currentRank: activeTier.rankName,
      nextRank: activeTier.nextRankName,
      nextGoal: nextGoal,
      progress: normalizedProgress,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        AppColors theme = AppThemes.color;
        Size size = MediaQuery.of(context).size;

        // Get current points from provider, fall back to widget parameter
        final currentPoints =
            userProvider.user?.totalPoints ?? widget.currentPoints;
        final rankProgress = _resolveRankProgress(currentPoints);

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
                                  'Point Balance',
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
                                          currentPoints,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' pts',
                                        style: TextDesign.smallText(
                                          color: theme.onPrimary.withOpacity(
                                            0.9,
                                          ),
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
                                      rankProgress.nextRank == null
                                          ? 'Top Rank Reached'
                                          : '${rankProgress.nextRank} Goal',
                                      style: TextDesign.smallText(
                                        color: theme.onPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      rankProgress.nextGoal == null
                                          ? 'MAX'
                                          : '${VoucherHelpers.formatWithCommas(currentPoints)} / ${VoucherHelpers.formatWithCommas(rankProgress.nextGoal!)}',
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
                                    value: rankProgress.progress,
                                    minHeight: 8,
                                    backgroundColor: theme.onPrimary
                                        .withOpacity(0.25),
                                    valueColor: AlwaysStoppedAnimation(
                                      theme.onPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      rankProgress.currentRank,
                                      style: TextDesign.smallText(
                                        color: theme.onPrimary.withOpacity(
                                          0.95,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      rankProgress.nextRank == null
                                          ? 'NEXT: MAX'
                                          : 'NEXT: ${rankProgress.nextRank}',
                                      style: TextDesign.smallText(
                                        color: theme.onPrimary.withOpacity(
                                          0.95,
                                        ),
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
                                          currentPoints: currentPoints,
                                          goalPoints:
                                              rankProgress.nextGoal ??
                                              currentPoints,
                                          memberRank: rankProgress.currentRank,
                                          nextRank:
                                              rankProgress.nextRank ?? 'MAX',
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
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

                    // My Redeemed Vouchers Section
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
                                      'My Redeemed Vouchers',
                                      style: TextDesign.headingTwo(),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Vouchers you have redeemed',
                                      style: TextDesign.smallText(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_userRedeemedVouchers.length > 2)
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RedeemedVoucherViewAllScreen(),
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
                          if (_userRedeemedVouchers.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Text(
                                  'No redeemed vouchers yet',
                                  style: TextDesign.normalText(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _userRedeemedVouchers.length > 2
                                  ? 2
                                  : _userRedeemedVouchers.length,
                              itemBuilder: (context, index) {
                                final redeemedVoucher =
                                    _userRedeemedVouchers[index];
                                final isUnused =
                                    redeemedVoucher.voucherStatus ==
                                    RedeemedVoucherStatus.unused;

                                return RedeemedVoucherCard(
                                  redeemedVoucher: redeemedVoucher,
                                  onSharePressed: () {
                                    RedeemedVoucherDialogs.showShareConfirmation(
                                      context: context,
                                      onConfirm: () => _updateStatusAndShare(
                                        redeemedVoucher,
                                      ),
                                    );
                                  },
                                  onUsePressed: () {
                                    _handleUseVoucher(redeemedVoucher);
                                  },
                                  showShareButton: isUnused,
                                  showUseButton: isUnused,
                                );
                              },
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              );
      },
    );
  }
}
