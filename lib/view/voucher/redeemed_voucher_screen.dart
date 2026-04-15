import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/redeemed_voucher/redeemed_voucher_ctrl.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/view/voucher/redeemed_voucher_view_all.dart';
import 'package:recycle_go/view/voucher/redeemed_voucher_card.dart';
import 'package:recycle_go/view/voucher/redeemed_voucher_dialogs.dart';
import 'package:recycle_go/view/voucher/voucher_use_confirmation_screen.dart';
import 'package:recycle_go/view/voucher/qr_code_helpers.dart';

class RedeemedVoucherScreen extends StatefulWidget {
  const RedeemedVoucherScreen({super.key});

  @override
  State<RedeemedVoucherScreen> createState() => _RedeemedVoucherScreenState();
}

class _RedeemedVoucherScreenState extends State<RedeemedVoucherScreen> {
  final RedeemVoucherCtrl _redeemCtrl = RedeemVoucherCtrl();
  bool _isLoading = true;
  List<RedeemedVouchers> _userRedeemedVouchers = [];

  @override
  void initState() {
    super.initState();
    _loadRedeemedVouchers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRedeemedVouchers();
  }

  @override
  void dispose() {
    super.dispose();
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

    return _isLoading
        ? Center(child: CircularProgressIndicator(color: theme.primary))
        : SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06,
                    vertical: size.height * 0.02,
                  ),
                  child: Row(
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
                              'Vouchers you have redeemed (${_userRedeemedVouchers.length} total)',
                              style: TextDesign.smallText(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_userRedeemedVouchers.length > 1)
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
                            style: TextDesign.smallText(color: theme.onPrimary),
                          ),
                        ),
                    ],
                  ),
                ),

                // Content Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06,
                    vertical: size.height * 0.02,
                  ),
                  child: Column(
                    children: [
                      if (_userRedeemedVouchers.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No redeemed vouchers yet',
                              style: TextDesign.normalText(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      else
                        RedeemedVoucherCard(
                          redeemedVoucher: _userRedeemedVouchers[0],
                          onSharePressed: () {
                            RedeemedVoucherDialogs.showShareConfirmation(
                              context: context,
                              onConfirm: () => _updateStatusAndShare(
                                _userRedeemedVouchers[0],
                              ),
                            );
                          },
                          onUsePressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VoucherUseConfirmationScreen(
                                  voucherCode:
                                      _userRedeemedVouchers[0].voucherCode,
                                  onSuccess: _loadRedeemedVouchers,
                                ),
                              ),
                            ).then((_) {
                              // Refresh data after returning from confirmation screen
                              _loadRedeemedVouchers();
                            });
                          },
                          showShareButton:
                              _userRedeemedVouchers[0].voucherStatus ==
                              RedeemedVoucherStatus.unused,
                          showUseButton:
                              _userRedeemedVouchers[0].voucherStatus ==
                              RedeemedVoucherStatus.unused,
                        ),
                      // Show info message for pending vouchers
                      if (_userRedeemedVouchers[0].voucherStatus ==
                          RedeemedVoucherStatus.pending)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Awaiting admin approval for bank transfer',
                                    style: TextDesign.smallText(
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
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
