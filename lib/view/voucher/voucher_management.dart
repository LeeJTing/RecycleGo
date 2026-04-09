import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Vouchers.dart';

class VoucherManagement extends StatelessWidget {
  final int currentPoints;
  final int goalPoints;
  final String memberRank;
  final String nextRank;
  final List<Vouchers> vouchers;

  const VoucherManagement({
    super.key,
    this.currentPoints = 0,
    this.goalPoints = 2000,
    this.memberRank = 'BRONZE MEMBER',
    this.nextRank = 'SILVER RANK',
    this.vouchers = const [],
  });

  String _formatWithCommas(int value) {

    final pattern = RegExp(r'(\d)(?=(\d{3})+$)');
    return value.toString().replaceAll(pattern, r'$1,');
  }

  @override
  Widget build(BuildContext context) {
    AppColors theme = AppThemes.color;
    Size size = MediaQuery.of(context).size;
    final progress = currentPoints / goalPoints;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8, right: 8),
          child: Image.asset('assets/images/logo.webp', width: 28, height: 28),
        ),
        title: Text('Green Reward', style: TextDesign.normalText()),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Container(color: theme.appbarBackground, height: 1),
        ),
      ),
      body: SingleChildScrollView(
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
                    colors: [theme.primary, theme.primary.withOpacity(0.85)],
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
                              TextSpan(text: _formatWithCommas(currentPoints)),
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
                            Icon(Icons.star, size: 16, color: theme.onPrimary),
                            const SizedBox(width: 4),
                            Text(
                              '$nextRank Goal',
                              style: TextDesign.smallText(
                                color: theme.onPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_formatWithCommas(currentPoints)} / ${_formatWithCommas(goalPoints)}',
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
                            backgroundColor: theme.onPrimary.withOpacity(0.25),
                            valueColor: AlwaysStoppedAnimation(theme.onPrimary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              memberRank,
                              style: TextDesign.smallText(
                                color: theme.onPrimary.withOpacity(0.95),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'NEXT: $nextRank',
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

            // Featured Rewards Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.06,
                vertical: size.height * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Featured Rewards', style: TextDesign.headingTwo()),
                  const SizedBox(height: 4),
                  Text(
                    'Redeem your hard-earned points for eco-benefits.',
                    style: TextDesign.smallText(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  if (vouchers.isEmpty)
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
                      itemCount: vouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = vouchers[index];
                        final canRedeem =
                            currentPoints >= voucher.pointsRequired;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.card_giftcard,
                                  color: theme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      voucher.voucherName,
                                      style: TextDesign.normalText(),
                                    ),
                                    if (voucher.description != null &&
                                        voucher.description!.isNotEmpty)
                                      Text(
                                        voucher.description!,
                                        style: TextDesign.smallText(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_formatWithCommas(voucher.pointsRequired)} POINTS',
                                      style: TextDesign.smallText(
                                        color: theme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: ElevatedButton(
                                  onPressed: canRedeem
                                      ? () {
                                          // TODO: Implement redeem logic
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    backgroundColor: canRedeem
                                        ? theme.primary
                                        : Colors.grey[300],
                                  ),
                                  child: Text(
                                    canRedeem ? 'Redeem' : 'Locked',
                                    style: TextDesign.smallText(
                                      color: canRedeem
                                          ? theme.onPrimary
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
