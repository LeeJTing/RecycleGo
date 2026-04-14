import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/view/voucher/voucher_management.dart';
import 'package:recycle_go/view/voucher/redeemed_voucher_screen.dart';
import 'package:recycle_go/view/voucher/qr_scanner_screen.dart';

class VoucherMainPage extends StatefulWidget {
  final int currentPoints;
  final int goalPoints;
  final String memberRank;
  final String nextRank;

  const VoucherMainPage({
    super.key,
    required this.currentPoints,
    required this.goalPoints,
    required this.memberRank,
    required this.nextRank,
  });

  @override
  State<VoucherMainPage> createState() => _VoucherMainPageState();
}

class _VoucherMainPageState extends State<VoucherMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final theme = AppThemes.color;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
        ),
        label: const Text('Scan QR'),
        icon: const Icon(Icons.qr_code_scanner),
        backgroundColor: theme.primary,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.primary,
              labelColor: theme.primary,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: TextDesign.normalText(fontSize: 14),
              tabs: const [
                Tab(text: 'Available'),
                Tab(text: 'Redeemed'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Available Vouchers Tab
                VoucherManagement(
                  currentPoints: widget.currentPoints,
                  goalPoints: widget.goalPoints,
                  memberRank: widget.memberRank,
                  nextRank: widget.nextRank,
                ),
                // Redeemed Vouchers Tab
                const RedeemedVoucherScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
