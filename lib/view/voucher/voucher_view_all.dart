import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';
import 'package:recycle_go/controller/redeemed_voucher/redeemed_voucher_ctrl.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/view/voucher/voucher_helpers.dart';
import 'package:recycle_go/view/voucher/voucher_card.dart';
import 'package:recycle_go/view/voucher/redeem_dialog.dart';

class VoucherViewAllScreen extends StatefulWidget {
  final int currentPoints;
  final int goalPoints;
  final String memberRank;
  final String nextRank;

  const VoucherViewAllScreen({
    super.key,
    required this.currentPoints,
    required this.goalPoints,
    required this.memberRank,
    required this.nextRank,
  });

  @override
  State<VoucherViewAllScreen> createState() => _VoucherViewAllScreenState();
}

class _VoucherViewAllScreenState extends State<VoucherViewAllScreen> {
  final VoucherCtrl _voucherCtrl = VoucherCtrl();
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
              (v.voucherStatus == 'active') &&
              (widget.currentPoints >= v.pointsRequired) &&
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

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('All Vouchers', style: TextDesign.normalText()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: theme.appbarBackground, height: 1),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : SingleChildScrollView(
              child: Padding(
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
                    const SizedBox(height: 20),
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
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredVouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = _filteredVouchers[index];
                          final category = voucher.description ?? 'Exchange';

                          return VoucherCard(
                            voucher: voucher,
                            category: category,
                            onRedeemPressed: () => _redeemVoucher(voucher),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
