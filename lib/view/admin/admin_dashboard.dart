import 'package:flutter/material.dart';
import 'package:recycle_go/view/admin/verify_recycle_item.dart';

import '../../app/app_theme.dart';
import '../../controller/voucher/voucher_ctrl.dart';
import '../../models/Vouchers.dart';

class AdminDashboard extends StatefulWidget {

  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  final VoucherCtrl _voucherCtrl = VoucherCtrl();
  List<Vouchers> _sampleVouchers = [];
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _loadVouchers() async {
    await _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _voucherCtrl.fetchVouchers();
      setState(() {
        _sampleVouchers = _voucherCtrl.vouchers.take(1).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  } // <--- THIS is the closing bracket you were missing!

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    return Scaffold(
        appBar: AppBar(title: const Text("Admin Dashboard")),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search by ID or User...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.onPrimary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VerifyRecycleItem()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Verify Recycle Item"),
                ),
              ],
            ),
          ),
        )
    );
  }
}