import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/redeemed_voucher/redeemed_voucher_ctrl.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/view/voucher/qr_code_helpers.dart';

class VoucherUseConfirmationScreen extends StatefulWidget {
  final String voucherCode;
  final VoidCallback? onSuccess;

  const VoucherUseConfirmationScreen({
    super.key,
    required this.voucherCode,
    this.onSuccess,
  });

  @override
  State<VoucherUseConfirmationScreen> createState() =>
      _VoucherUseConfirmationScreenState();
}

class _VoucherUseConfirmationScreenState
    extends State<VoucherUseConfirmationScreen> {
  final RedeemVoucherCtrl _redeemCtrl = RedeemVoucherCtrl();
  bool _isLoading = false;
  RedeemedVouchers? _redeemedVoucher;
  bool _found = false;

  @override
  void initState() {
    super.initState();
    _loadVoucherDetails();
  }

  Future<void> _loadVoucherDetails() async {
    setState(() => _isLoading = true);
    try {
      await _redeemCtrl.fetchRedeemedVouchers(voucherCode: widget.voucherCode);

      if (_redeemCtrl.redeemedVouchers.isNotEmpty) {
        setState(() {
          _redeemedVoucher = _redeemCtrl.redeemedVouchers[0];
          _found = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _found = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading voucher: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmUseVoucher() async {
    if (_redeemedVoucher == null) return;

    setState(() => _isLoading = true);
    try {
      // Update the voucher status to used (regardless of who owns it)
      await _redeemCtrl.updateRedeemedVoucherStatus(
        _redeemedVoucher!.voucherCode,
        RedeemedVoucherStatus.used,
      );

      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Voucher successfully used!'),
            backgroundColor: theme.primary,
          ),
        );
        widget.onSuccess?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to use voucher: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Use Voucher', style: TextDesign.normalText()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: theme.appbarBackground, height: 1),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : !_found
          ? _buildNotFoundScreen(theme, size)
          : _buildVoucherConfirmationScreen(theme, size),
    );
  }

  Widget _buildNotFoundScreen(AppColors theme, Size size) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: theme.error),
            const SizedBox(height: 16),
            Text('Voucher Not Found', style: TextDesign.headingTwo()),
            const SizedBox(height: 8),
            Text(
              'The voucher code could not be found.\nPlease check and try again.',
              textAlign: TextAlign.center,
              style: TextDesign.smallText(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherConfirmationScreen(AppColors theme, Size size) {
    if (_redeemedVoucher == null) return const SizedBox.shrink();

    final isAlreadyUsed =
        _redeemedVoucher!.voucherStatus == RedeemedVoucherStatus.used;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Code
            Center(
              child: QRCodeHelpers.buildQRCode(_redeemedVoucher!.voucherCode),
            ),
            const SizedBox(height: 24),

            // Voucher Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusBackgroundColor(
                  _redeemedVoucher!.voucherStatus,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voucher Status',
                    style: TextDesign.smallText(
                      color: _getStatusColor(_redeemedVoucher!.voucherStatus),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _redeemedVoucher!.voucherStatus.dbValue.toUpperCase(),
                    style: TextDesign.headingTwo(
                      color: _getStatusColor(_redeemedVoucher!.voucherStatus),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Code',
                    _redeemedVoucher!.voucherCode,
                    monospace: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Redeemed Date',
                    _redeemedVoucher!.redeemedAt?.toString().split('.')[0] ??
                        'N/A',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (!isAlreadyUsed)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Do you want to use this voucher?',
                    textAlign: TextAlign.center,
                    style: TextDesign.normalText(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _confirmUseVoucher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Yes, Use It',
                      style: TextDesign.normalText(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextDesign.normalText(fontSize: 16),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Voucher Already Used',
                      style: TextDesign.normalText(
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This voucher has already been redeemed.',
                      style: TextDesign.smallText(color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool monospace = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextDesign.smallText(color: Colors.grey[600])),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextDesign.smallText(color: Colors.grey[800], fontSize: 12),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(RedeemedVoucherStatus status) {
    switch (status) {
      case RedeemedVoucherStatus.unused:
        return Colors.blue;
      case RedeemedVoucherStatus.used:
        return Colors.green;
      case RedeemedVoucherStatus.shared:
        return Colors.purple;
    }
  }

  Color _getStatusBackgroundColor(RedeemedVoucherStatus status) {
    return _getStatusColor(status).withOpacity(0.1);
  }
}
