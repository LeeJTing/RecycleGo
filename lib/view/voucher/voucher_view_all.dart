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
import 'package:shared_preferences/shared_preferences.dart';

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
  FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = true;
  List<Vouchers> _filteredVouchers = [];
  List<String> _searchHistory = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {
        _showHistory =
            _searchFocusNode.hasFocus &&
            _searchController.text.isEmpty &&
            _searchHistory.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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

  void _onSearchChanged() {
    setState(() {
      _showHistory =
          _searchFocusNode.hasFocus &&
          _searchController.text.isEmpty &&
          _searchHistory.isNotEmpty;
    });
    _filterVouchers();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('voucher_view_search_history') ?? [];
    });
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    List<String> history = List.from(_searchHistory);
    history.remove(query);
    history.insert(0, query);

    if (history.length > 5) {
      history = history.sublist(0, 5);
    }

    await prefs.setStringList('voucher_view_search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = List.from(_searchHistory);
    history.remove(query);
    await prefs.setStringList('voucher_view_search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Widget _buildHistoryList(AppColors theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      width: double.infinity,
      color: theme.onPrimary,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchHistory.length,
        itemBuilder: (context, index) {
          final query = _searchHistory[index];
          return ListTile(
            leading: Icon(Icons.history, color: theme.hint, size: 20),
            title: Text(query),
            trailing: IconButton(
              icon: Icon(Icons.close, size: 16, color: theme.hint),
              onPressed: () => _removeFromHistory(query),
            ),
            onTap: () {
              _searchController.text = query;
              _searchFocusNode.unfocus();
              _onSearchChanged();
            },
          );
        },
      ),
    );
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
                      focusNode: _searchFocusNode,
                      onSubmitted: (value) => _addToHistory(value),
                      decoration: InputDecoration(
                        hintText: 'Search vouchers...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.onPrimary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_showHistory) _buildHistoryList(theme),
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
                          final category =
                              voucher.voucherCategory.trim().isNotEmpty
                              ? voucher.voucherCategory
                              : 'General';
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
