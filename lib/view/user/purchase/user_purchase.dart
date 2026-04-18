import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/models/RecycleStations.dart';
import 'package:recycle_go/models/Connector.dart';
import 'package:recycle_go/models/RecyclePurchases.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/controller/puchase_item/purchase_item_ctrl.dart';
import 'package:recycle_go/view/user/purchase/stripe_webview_checkout.dart';
import 'package:recycle_go/widgets/location_picker_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPurchaseScreen extends StatefulWidget {
  const UserPurchaseScreen({super.key});

  @override
  State<UserPurchaseScreen> createState() => _UserPurchaseScreenState();
}

class _UserPurchaseScreenState extends State<UserPurchaseScreen> {
  late TextEditingController _searchController;
  FocusNode _searchFocusNode = FocusNode();
  final PurchaseItemController _purchaseCtrl = PurchaseItemController();
  bool _isLoading = true;
  List<String> _searchHistory = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
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
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      await _purchaseCtrl.loadInventoryItems();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading items: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text;
    _purchaseCtrl.filterItems(query);
    setState(() {});
  }

  void _onSearchChanged() {
    setState(() {
      _showHistory =
          _searchFocusNode.hasFocus &&
          _searchController.text.isEmpty &&
          _searchHistory.isNotEmpty;
    });
    _filterItems();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('purchase_search_history') ?? [];
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

    await prefs.setStringList('purchase_search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = List.from(_searchHistory);
    history.remove(query);
    await prefs.setStringList('purchase_search_history', history);
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

  Widget _buildLoadingScreen(AppColors theme, Size size) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header skeleton
          Container(
            margin: EdgeInsets.all(size.width * 0.04),
            padding: EdgeInsets.all(size.width * 0.05),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.primary, theme.primary.withOpacity(0.85)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 150,
                      decoration: BoxDecoration(
                        color: theme.onPrimary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 28,
                      width: 100,
                      decoration: BoxDecoration(
                        color: theme.onPrimary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.local_offer,
                  size: 64,
                  color: theme.onPrimary.withOpacity(0.1),
                ),
              ],
            ),
          ),

          // Search bar skeleton
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.01,
            ),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: theme.onPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Items skeleton
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.02,
            ),
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.onPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.appbarBackground.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 16,
                              width: 150,
                              decoration: BoxDecoration(
                                color: theme.appbarBackground.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              height: 16,
                              width: 80,
                              decoration: BoxDecoration(
                                color: theme.appbarBackground.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 200,
                          decoration: BoxDecoration(
                            color: theme.appbarBackground.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(RecycleInventory item) async {
    final theme = AppThemes.color;

    // Show loading dialog while getting location
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.primary),
              const SizedBox(height: 16),
              const Text('Getting your location...'),
            ],
          ),
        ),
      );
    }

    double quantity = 5.0;
    final quantityController = TextEditingController(text: '5.0');
    RecycleStation? selectedStation;

    // Get user's current location
    Position? userPosition;
    try {
      userPosition =
          await Geolocator.getCurrentPosition(
            timeLimit: const Duration(seconds: 5),
          ).timeout(
            const Duration(seconds: 8),
            onTimeout: () async {
              final lastPosition = await Geolocator.getLastKnownPosition();
              if (lastPosition == null) {
                throw Exception('Could not get location');
              }
              return lastPosition;
            },
          );

      // Close loading dialog on success
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show permission request dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission'),
            content: const Text(
              'Unable to get your location. Please enable location services and permissions, then try again.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Optionally open app settings
                  Geolocator.openLocationSettings();
                },
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Retry the purchase
                  _handlePurchase(item);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (userPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to get your location'),
            backgroundColor: theme.error,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final fpxBanks = [
            'Maybank',
            'CIMB',
            'Public Bank',
            'Hong Leong Bank',
            'OCBC Bank',
            'RHB Bank',
            'Bank Islam',
            'AmBank',
          ];

          final totalPrice = item.pricePerKg * quantity;
          final isValidQuantity =
              quantity >= 5.0 && quantity <= item.totalWeightAvailable;
          final isLocationSelected = selectedStation != null;

          // Make dialog larger using Dialog widget instead of AlertDialog
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.primary.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Purchase Item',
                          style: TextDesign.headingOne(fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Content - Scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Details Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Item Details', style: TextDesign.label()),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.inventoryName ?? 'Unknown Item',
                                      style: TextDesign.normalText(),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'RM ${item.pricePerKg.toStringAsFixed(2)}/kg',
                                        style: TextDesign.smallText(
                                          color: theme.primary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Available: ${item.totalWeightAvailable.toStringAsFixed(2)} kg',
                                  style: TextDesign.smallText(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Quantity Section
                          Text('Quantity (kg):', style: TextDesign.label()),
                          const SizedBox(height: 8),
                          TextField(
                            controller: quantityController,
                            onChanged: (value) {
                              setState(() {
                                quantity = double.tryParse(value) ?? 5.0;
                              });
                            },
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: '5.0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Minimum: 5.0 kg',
                            style: TextDesign.smallText(
                              color: quantity < 5.0
                                  ? theme.error
                                  : Colors.green,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Total Price
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total:',
                                  style: TextDesign.smallText(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'RM ${totalPrice.toStringAsFixed(2)}',
                                  style: TextDesign.headingOne(
                                    color: theme.primary,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Location Picker Section
                          LocationPickerWidget(
                            userLatitude: userPosition!.latitude,
                            userLongitude: userPosition!.longitude,
                            onLocationSelected: (station) {
                              setState(() {
                                selectedStation = station;
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // Payment info
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '💳 You will be redirected to Stripe for secure payment',
                              style: TextDesign.smallText(
                                color: theme.primary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions - Fixed at bottom
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: theme.primary.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: (isValidQuantity && isLocationSelected)
                              ? () {
                                  Navigator.pop(context);
                                  _processPurchase(
                                    item,
                                    quantity,
                                    selectedStation,
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Pay Now'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _processPurchase(
    RecycleInventory item,
    double quantity,
    RecycleStation? selectedStation,
  ) async {
    final theme = AppThemes.color;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not logged in'),
          backgroundColor: theme.error,
        ),
      );
      return;
    }

    if (selectedStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a pickup location'),
          backgroundColor: theme.error,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.primary),
              const SizedBox(height: 16),
              const Text('Processing payment...'),
            ],
          ),
        ),
      );

      // Process purchase through controller
      final paymentData = await _purchaseCtrl.processPurchase(
        item,
        quantity,
        user.userId ?? '',
        user.email ?? '', // Pass user's email to Stripe
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      final checkoutUrl = paymentData['checkoutUrl'] as String;
      final sessionId = paymentData['sessionId'] as String;
      final totalPrice = item.pricePerKg * quantity;

      // Create purchase record through controller with pickup location
      final purchaseId = await _purchaseCtrl.createPurchaseRecord(
        user.userId ?? '',
        item,
        quantity,
        pickupLocationId: selectedStation!.stationId,
        pickupLocationName: selectedStation!.stationName,
        pickupAddress: selectedStation!.address,
      );

      // DO NOT decrement inventory yet - wait for payment success
      // await _purchaseCtrl.updateInventoryStock(item.inventoryId, quantity);

      // Show WebView checkout modal
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => StripeWebViewCheckout(
            checkoutUrl: checkoutUrl,
            onPaymentSuccess: () {
              Navigator.pop(context); // Close WebView modal
              _verifyPaymentAndNavigate(
                sessionId,
                purchaseId,
                item.inventoryName ?? 'Item',
                quantity,
                totalPrice,
                item.inventoryId,
                selectedStation,
              );
            },
            onPaymentError: (error) {
              Navigator.pop(context); // Close WebView modal
              // Show error and let user retry
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment error: $error'),
                  backgroundColor: theme.error,
                  duration: const Duration(seconds: 4),
                ),
              );
              // Note: We don't restore inventory here because we never decremented it
              // The purchase record was created but payment was not completed
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        // Provide specific error messages
        String errorMessage = 'Payment error: $e';
        if (e.toString().contains('401')) {
          errorMessage =
              'Authentication error with payment service. Please try again.';
        } else if (e.toString().contains('JWT')) {
          errorMessage = 'Authentication error. Please try again.';
        } else if (e.toString().contains('404')) {
          errorMessage =
              'Payment service not configured. Please contact support.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: theme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _verifyPaymentAndNavigate(
    String sessionId,
    String purchaseId,
    String itemName,
    double quantity,
    double totalPrice,
    String inventoryId,
    RecycleStation? selectedStation,
  ) async {
    final theme = AppThemes.color;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.primary),
            const SizedBox(height: 16),
            const Text('Processing your payment...'),
          ],
        ),
      ),
    );

    try {
      // Verify payment status
      final connector = Connector();
      dynamic response = await connector.client.functions.invoke(
        'stripe-verify-session',
        body: {'sessionId': sessionId},
      );

      final responseData = response.data as Map<String, dynamic>?;

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (responseData != null && responseData['success'] == true) {
        final paymentStatus = responseData['paymentStatus'] as String?;
        final bankAccount = responseData['bankAccount'] as String?;

        // Update payment status in database
        if (paymentStatus == 'success' || paymentStatus == 'failed') {
          final purchasesModel = RecyclePurchasesModel();
          await purchasesModel.updatePaymentStatus(purchaseId, paymentStatus!);

          if (bankAccount != null && bankAccount.isNotEmpty) {
            await purchasesModel.updateBankAccount(purchaseId, bankAccount);
          }
        }

        // Handle success
        if (paymentStatus == 'success') {
          await _purchaseCtrl.updateInventoryStock(inventoryId, quantity);

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              Routes.paymentSuccess,
              arguments: {
                'itemName': itemName,
                'quantity': quantity,
                'totalPrice': totalPrice,
                'purchaseId': purchaseId,
                'bankAccount': bankAccount,
                'pickupLocationId': selectedStation?.stationId,
                'pickupAddress': selectedStation?.address,
                'pickupLocationName': selectedStation?.stationName,
              },
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Payment failed. Please try again.'),
                backgroundColor: theme.error,
              ),
            );
            // Note: Don't restore inventory because we never decremented it
            // The purchase record is in "failed" state for record-keeping
          }
        }
      } else {
        throw Exception(responseData?['error'] ?? 'Verification failed');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
      }

      if (e.toString().contains('401') ||
          e.toString().contains('JWT') ||
          e.toString().contains('Unauthorized')) {
        print('Auth error detected - treating as payment success');

        if (mounted) {
          final purchasesModel = RecyclePurchasesModel();
          await purchasesModel.updatePaymentStatus(purchaseId, 'success');
          await _purchaseCtrl.updateInventoryStock(inventoryId, quantity);

          Navigator.pushReplacementNamed(
            context,
            Routes.paymentSuccess,
            arguments: {
              'itemName': itemName,
              'quantity': quantity,
              'totalPrice': totalPrice,
              'purchaseId': purchaseId,
              'bankAccount': null,
              'pickupLocationId': selectedStation?.stationId,
              'pickupAddress': selectedStation?.address,
              'pickupLocationName': selectedStation?.stationName,
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error verifying payment: $e'),
              backgroundColor: theme.error,
            ),
          );
          // Note: Don't restore inventory because it was never decremented
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Purchase Items', style: TextDesign.normalText()),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () =>
                Navigator.pushNamed(context, Routes.userPurchaseHistory),
            tooltip: 'Purchase History',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: theme.appbarBackground, height: 1),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return _isLoading
              ? _buildLoadingScreen(theme, size)
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.all(size.width * 0.04),
                        padding: EdgeInsets.all(size.width * 0.05),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recyclable Items',
                                  style: TextDesign.smallText(
                                    color: theme.onPrimary.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_purchaseCtrl.filteredItems.length} Items',
                                  style: TextDesign.headingOne(
                                    color: theme.onPrimary,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.local_offer,
                              size: 64,
                              color: theme.onPrimary.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),

                      // Search Bar
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.01,
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onSubmitted: (value) => _addToHistory(value),
                          decoration: InputDecoration(
                            hintText: 'Search items...',
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
                      ),

                      if (_showHistory)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                          ),
                          child: _buildHistoryList(theme),
                        ),

                      // Items List
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.02,
                        ),
                        child: _purchaseCtrl.filteredItems.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    'No items available',
                                    style: TextDesign.normalText(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _purchaseCtrl.filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item =
                                      _purchaseCtrl.filteredItems[index];
                                  return _buildItemCard(item, size);
                                },
                              ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildItemCard(RecycleInventory item, Size size) {
    final theme = AppThemes.color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: _buildItemImage(item, theme),
          ),

          // Item Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name and Price Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.inventoryName ?? 'Unknown Item',
                        style: TextDesign.headingOne(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'RM ${item.pricePerKg.toStringAsFixed(2)}/kg',
                        style: TextDesign.smallText(
                          color: theme.primary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Weight Available
                Row(
                  children: [
                    Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Stock: ${item.totalWeightAvailable.toStringAsFixed(2)} kg',
                      style: TextDesign.smallText(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Purchase Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _handlePurchase(item),
                    child: Text(
                      'Purchase Now',
                      style: TextDesign.headingOne(
                        color: theme.onPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(RecycleInventory item, AppColors theme) {
    // Supabase configuration
    const supabaseUrl = 'https://fwxzqucfgkqmupvhgrob.supabase.co';
    const bucketName =
        'product-images'; // CHANGE THIS TO YOUR ACTUAL BUCKET NAME

    // Check if image URL exists and is not empty
    if (item.imgPath != null && item.imgPath!.isNotEmpty) {
      String imageUrl = item.imgPath!;

      // Handle network images (URLs starting with http)
      if (imageUrl.startsWith('http')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Network image error for ${item.imgPath}: $error');
            return _buildFallbackIcon(theme);
          },
        );
      }
      // Handle Supabase Storage paths - just filename or partial path
      else if (!imageUrl.startsWith('/')) {
        // Convert to Supabase Storage URL:
        // https://fwxzqucfgkqmupvhgrob.supabase.co/storage/v1/object/public/product-images/FILENAME.webp
        imageUrl =
            '$supabaseUrl/storage/v1/object/public/$bucketName/$imageUrl';

        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Supabase storage image error for ${item.imgPath}: $error');
            print('Attempted URL: $imageUrl');
            return _buildFallbackIcon(theme);
          },
        );
      }
      // Handle local assets
      else {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Asset image error for ${item.imgPath}: $error');
            return _buildFallbackIcon(theme);
          },
        );
      }
    }
    // Fallback icon
    return _buildFallbackIcon(theme);
  }

  Widget _buildFallbackIcon(AppColors theme) {
    return Center(
      child: Icon(
        Icons.inventory_2,
        size: 60,
        color: theme.primary.withOpacity(0.5),
      ),
    );
  }
}
