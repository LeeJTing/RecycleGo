import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/models/RecyclePurchases.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/models/Connector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class UserPurchaseScreen extends StatefulWidget {
  const UserPurchaseScreen({super.key});

  @override
  State<UserPurchaseScreen> createState() => _UserPurchaseScreenState();
}

class _UserPurchaseScreenState extends State<UserPurchaseScreen> {
  bool _isLoading = true;
  List<RecycleInventory> _items = [];
  List<RecycleInventory> _filteredItems = [];
  TextEditingController _searchController = TextEditingController();
  final _connector = Connector();

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryItems() async {
    setState(() => _isLoading = true);
    try {
      final response = await _connector.client
          .from('recycleinventory')
          .select()
          .order('inventory_name');

      final items = (response as List)
          .map((item) => RecycleInventory.fromJson(item))
          .toList();

      setState(() {
        _items = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading items: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  /// Update inventory stock after successful purchase
  Future<void> _updateInventoryStock(
    String inventoryId,
    double quantityPurchased,
  ) async {
    try {
      // Get current stock
      final currentResponse = await _connector.client
          .from('recycleinventory')
          .select('total_weight_available')
          .eq('inventory_id', inventoryId)
          .single();

      final currentStock =
          double.tryParse(
            currentResponse['total_weight_available']?.toString() ?? '0',
          ) ??
          0.0;

      // Calculate new stock
      final newStock = currentStock - quantityPurchased;

      // Update database
      if (newStock >= 0) {
        await _connector.client
            .from('recycleinventory')
            .update({'total_weight_available': newStock})
            .eq('inventory_id', inventoryId);
      }
    } catch (e) {
      print('Error updating inventory stock: $e');
      // Don't throw - log error but continue
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    final filtered = _items
        .where(
          (item) =>
              (item.inventoryName?.toLowerCase().contains(query) ?? false) ||
              (item.description?.toLowerCase().contains(query) ?? false),
        )
        .toList();

    setState(() {
      _filteredItems = filtered;
    });
  }

  void _handlePurchase(RecycleInventory item) {
    final theme = AppThemes.color;
    double quantity = 1.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final totalPrice = item.pricePerKg * quantity;

          return AlertDialog(
            title: const Text('Purchase Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Item: ${item.inventoryName}'),
                  const SizedBox(height: 8),
                  Text(
                    'Price per kg: RM ${item.pricePerKg.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Available: ${item.totalWeightAvailable.toStringAsFixed(2)} kg',
                  ),
                  const SizedBox(height: 16),
                  // Quantity Input
                  Text('Quantity (kg):', style: TextDesign.label()),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              quantity = double.tryParse(value) ?? 1.0;
                            });
                          },
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: '1.0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          style: TextDesign.smallText(color: Colors.grey[600]),
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
                  const SizedBox(height: 12),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: quantity > 0 && quantity <= item.totalWeightAvailable
                    ? () {
                        Navigator.pop(context);
                        _processPurchase(item, quantity);
                      }
                    : null,
                child: const Text('Pay Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processPurchase(RecycleInventory item, double quantity) async {
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

      // Calculate total amount in cents
      final totalAmountInCents = (item.pricePerKg * quantity * 100).toInt();

      // Call Stripe Edge Function to create checkout session
      final response = await _connector.client.functions.invoke(
        'stripe-create-checkout-session',
        body: {
          'itemId': item.inventoryId,
          'userId': user.userId ?? '',
          'merchantName': 'RecycleGo',
          'itemName':
              '${item.inventoryName ?? 'Item'} (${quantity.toStringAsFixed(2)} kg)',
          'amountInCents': totalAmountInCents,
          'currency': 'myr',
          'paymentMethodType': 'fpx',
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Handle response data
      final responseData = response.data as Map<String, dynamic>?;

      if (responseData != null && responseData.containsKey('error')) {
        throw Exception('Stripe error: ${responseData['error']}');
      }

      if (responseData != null &&
          responseData['success'] == true &&
          responseData['checkoutUrl'] != null) {
        // Launch Stripe checkout URL
        final checkoutUrl = responseData['checkoutUrl'] as String;
        final sessionId = responseData['sessionId'] as String;

        try {
          // Generate UUID for purchase record
          const uuid = Uuid();
          final purchaseId = uuid.v4();
          final totalPrice = item.pricePerKg * quantity;

          // Save purchase record with pending status
          final purchasesModel = RecyclePurchasesModel();
          final purchase = RecyclePurchases(
            purchaseId: purchaseId,
            userId: user.userId ?? '',
            totalPrice: totalPrice,
            paymentStatus: 'pending',
          );
          await purchasesModel.createPurchase(purchase);

          // Update inventory stock
          await _updateInventoryStock(item.inventoryId, quantity);

          // Try to launch with platformDefault mode first
          await launchUrl(
            Uri.parse(checkoutUrl),
            mode: LaunchMode.platformDefault,
          );

          // Navigate to payment verification screen
          if (mounted) {
            Navigator.pushNamed(
              context,
              Routes.paymentVerification,
              arguments: {
                'sessionId': sessionId,
                'purchaseId': purchaseId,
                'itemName': item.inventoryName ?? 'Item',
                'quantity': quantity,
                'totalPrice': totalPrice,
              },
            ).then((_) {
              // Reload items when returning from verification screen
              _loadInventoryItems();
            });
          }
        } catch (launchError) {
          throw Exception('Could not launch checkout URL: $launchError');
        }
      } else {
        throw Exception(
          'Failed to create checkout session - success: ${responseData?['success']}, checkoutUrl: ${responseData?['checkoutUrl']}',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: theme.error,
          ),
        );
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
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Items Info Card
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
                                  '${_filteredItems.length} Items',
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
                          decoration: InputDecoration(
                            hintText: 'Search items...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: theme.onPrimary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      // Items List
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.02,
                        ),
                        child: _filteredItems.isEmpty
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
                                itemCount: _filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredItems[index];
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
    // Check if image URL exists and is not empty
    if (item.imgPath != null && item.imgPath!.isNotEmpty) {
      // Handle network images (URLs starting with http)
      if (item.imgPath!.startsWith('http')) {
        return Image.network(
          item.imgPath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.inventory_2,
                size: 60,
                color: theme.primary.withOpacity(0.5),
              ),
            );
          },
        );
      }
      // Handle local assets
      else {
        return Image.asset(
          item.imgPath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.inventory_2,
                size: 60,
                color: theme.primary.withOpacity(0.5),
              ),
            );
          },
        );
      }
    }
    // Fallback icon
    return Center(
      child: Icon(
        Icons.inventory_2,
        size: 60,
        color: theme.primary.withOpacity(0.5),
      ),
    );
  }
}
