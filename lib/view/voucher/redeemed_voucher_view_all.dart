import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/redeemed_voucher/redeemed_voucher_ctrl.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/view/voucher/redeemed_voucher_card.dart';
import 'package:recycle_go/view/voucher/redeemed_voucher_dialogs.dart';
import 'package:recycle_go/view/voucher/voucher_use_confirmation_screen.dart';
import 'package:recycle_go/view/voucher/qr_code_helpers.dart';

class RedeemedVoucherViewAllScreen extends StatefulWidget {
  const RedeemedVoucherViewAllScreen({super.key});

  @override
  State<RedeemedVoucherViewAllScreen> createState() =>
      _RedeemedVoucherViewAllScreenState();
}

class _RedeemedVoucherViewAllScreenState
    extends State<RedeemedVoucherViewAllScreen> {
  final RedeemVoucherCtrl _redeemCtrl = RedeemVoucherCtrl();
  bool _isLoading = true;
  List<RedeemedVouchers> _userRedeemedVouchers = [];
  RedeemedVoucherStatus? _selectedFilter;
  bool _hasInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _loadRedeemedVouchers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data whenever the widget comes into focus
    if (_hasInitialLoad) {
      _loadRedeemedVouchers();
    }
    _hasInitialLoad = true;
  }

  Future<void> _loadRedeemedVouchers() async {
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.user?.userId;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _redeemCtrl.fetchRedeemedVouchersByUser(userId);
      setState(() {
        _userRedeemedVouchers = _redeemCtrl.redeemedVouchers;
        _isLoading = false;
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    // Filter vouchers if a filter is selected
    final filteredVouchers = _selectedFilter == null
        ? _userRedeemedVouchers
        : _userRedeemedVouchers
              .where((v) => v.voucherStatus == _selectedFilter)
              .toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('All Redeemed Vouchers', style: TextDesign.normalText()),
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
                    // Filter Chips
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedFilter == null,
                          onSelected: (_) {
                            setState(() => _selectedFilter = null);
                          },
                        ),
                        FilterChip(
                          label: const Text('Unused'),
                          selected:
                              _selectedFilter == RedeemedVoucherStatus.unused,
                          onSelected: (_) {
                            setState(
                              () => _selectedFilter =
                                  RedeemedVoucherStatus.unused,
                            );
                          },
                        ),
                        FilterChip(
                          label: const Text('Used'),
                          selected:
                              _selectedFilter == RedeemedVoucherStatus.used,
                          onSelected: (_) {
                            setState(
                              () =>
                                  _selectedFilter = RedeemedVoucherStatus.used,
                            );
                          },
                        ),
                        FilterChip(
                          label: const Text('Shared'),
                          selected:
                              _selectedFilter == RedeemedVoucherStatus.shared,
                          onSelected: (_) {
                            setState(
                              () => _selectedFilter =
                                  RedeemedVoucherStatus.shared,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (filteredVouchers.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No vouchers found',
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
                        itemCount: filteredVouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = filteredVouchers[index];
                          return RedeemedVoucherCard(
                            redeemedVoucher: voucher,
                            onSharePressed: () {
                              RedeemedVoucherDialogs.showShareConfirmation(
                                context: context,
                                onConfirm: () => _updateStatusAndShare(voucher),
                              );
                            },
                            onUsePressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VoucherUseConfirmationScreen(
                                    voucherCode: voucher.voucherCode,
                                    onSuccess: _loadRedeemedVouchers,
                                  ),
                                ),
                              );
                            },
                            showShareButton:
                                voucher.voucherStatus ==
                                RedeemedVoucherStatus.unused,
                            showUseButton:
                                voucher.voucherStatus ==
                                RedeemedVoucherStatus.unused,
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

  void _updateVoucherStatus(
    RedeemedVouchers redeemedVoucher,
    RedeemedVoucherStatus newStatus,
  ) async {
    try {
      await _redeemCtrl.updateRedeemedVoucherStatus(
        redeemedVoucher.voucherCode,
        newStatus,
      );
      await _loadRedeemedVouchers();

      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher marked as ${newStatus.dbValue}'),
            backgroundColor: theme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update voucher: $e'),
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
}
