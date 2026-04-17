import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/controller/puchase_item/purchase_item_ctrl.dart';
import 'package:url_launcher/url_launcher.dart';

class UserPurchaseScreen extends StatefulWidget {
  const UserPurchaseScreen({super.key});

  @override
  State<UserPurchaseScreen> createState() => _UserPurchaseScreenState();
}

class _UserPurchaseScreenState extends State<UserPurchaseScreen> {
  late TextEditingController _searchController;
  final PurchaseItemController _purchaseCtrl = PurchaseItemController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterItems);
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
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text;
    _purchaseCtrl.filterItems(query);
    setState(() {});
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

      // Create purchase record through controller
      final purchaseId = await _purchaseCtrl.createPurchaseRecord(
        user.userId ?? '',
        item,
        quantity,
      );

      // DO NOT decrement inventory yet - wait for payment success
      // await _purchaseCtrl.updateInventoryStock(item.inventoryId, quantity);

      // Navigate to payment verification screen FIRST
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
            'inventoryId': item.inventoryId,
          },
        ).then((_) {
          // Reload items when returning from verification screen
          if (mounted) {
            _loadItems();
          }
        });
      }

      // Launch Stripe checkout URL (don't await - let user navigate back naturally)
      try {
        await launchUrl(
          Uri.parse(checkoutUrl),
          mode: LaunchMode.platformDefault,
        );
      } catch (launchError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open payment gateway: $launchError'),
              backgroundColor: AppThemes.color.error,
            ),
          );
        }
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
