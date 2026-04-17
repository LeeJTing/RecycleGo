import 'package:flutter/material.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/services/supabase_service.dart';
import 'package:recycle_go/view/admin/widgets/pending_voucher_card.dart';

class AdminPendingVouchers extends StatefulWidget {
  const AdminPendingVouchers({super.key});

  @override
  State<AdminPendingVouchers> createState() => _AdminPendingVouchersState();
}

class _AdminPendingVouchersState extends State<AdminPendingVouchers> {
  List<RedeemedVouchers> _pendingVouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingVouchers();
  }

  Future<void> _loadPendingVouchers() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final supabase = SupabaseService().client;
      final response = await supabase
          .from('redeemedvouchers')
          .select()
          .eq('voucher_status', 'pending')
          .order('redeemed_at', ascending: false);

      if (mounted) {
        setState(() {
          _pendingVouchers = (response as List)
              .map((v) => RedeemedVouchers.fromJson(v))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pending vouchers: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: const Text('All Pending Vouchers'),
        backgroundColor: theme.onPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingVouchers.isEmpty
          ? Center(
              child: Text(
                'No pending vouchers',
                style: TextStyle(color: theme.hint),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingVouchers.length,
              itemBuilder: (context, index) {
                return PendingVoucherCard(
                  pendingVoucher: _pendingVouchers[index],
                  theme: theme,
                  onProcessed: _loadPendingVouchers,
                );
              },
            ),
    );
  }
}
