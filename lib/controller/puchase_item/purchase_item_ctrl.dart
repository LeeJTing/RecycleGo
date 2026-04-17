import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/models/RecyclePurchases.dart';
import 'package:recycle_go/models/Connector.dart';

class PurchaseItemController {
  final _connector = Connector();

  List<RecycleInventory> _items = [];
  List<RecycleInventory> _filteredItems = [];

  List<RecycleInventory> get items => _items;
  List<RecycleInventory> get filteredItems => _filteredItems;

  /// Load all inventory items from database
  Future<void> loadInventoryItems() async {
    try {
      final response = await _connector.client
          .from('recycleinventory')
          .select()
          .order('inventory_name');

      _items = (response as List)
          .map((item) => RecycleInventory.fromJson(item))
          .toList();

      _filteredItems = _items;
    } catch (e) {
      rethrow;
    }
  }

  /// Filter items based on search query
  void filterItems(String query) {
    final lowerQuery = query.toLowerCase();
    _filteredItems = _items
        .where(
          (item) =>
              (item.inventoryName?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              (item.description?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .toList();
  }

  /// Update inventory stock after successful purchase
  Future<void> updateInventoryStock(
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
      // Update database with .select() to confirm
      if (newStock >= 0) {
        final updateResponse = await _connector.client
            .from('recycleinventory')
            .update({'total_weight_available': newStock})
            .eq('inventory_id', inventoryId)
            .select(); // Add .select() to get response confirmation

        if (updateResponse != null && updateResponse.isNotEmpty) {
          print('=== INVENTORY UPDATED SUCCESSFULLY ===');
          print(
            'New stock in DB: ${updateResponse[0]['total_weight_available']}',
          );
        } else {
          print('WARNING: Update response was empty!');
        }
      } else {
        print('ERROR: Not enough stock to deduct!');
      }
    } catch (e) {
      print('Error updating inventory stock: $e');
      rethrow;
    }
  }

  /// Restore inventory when payment fails
  Future<void> restoreInventoryStock(
    String inventoryId,
    double quantityToRestore,
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

      // Restore stock by adding back the quantity
      final restoredStock = currentStock + quantityToRestore;

      // Update database
      await _connector.client
          .from('recycleinventory')
          .update({'total_weight_available': restoredStock})
          .eq('inventory_id', inventoryId);
    } catch (e) {
      print('Error restoring inventory stock: $e');
      // Don't throw - log error but continue
    }
  }

  /// Process purchase and create Stripe checkout session
  Future<Map<String, dynamic>> processPurchase(
    RecycleInventory item,
    double quantity,
    String userId,
    String? userEmail,
  ) async {
    try {
      // Calculate total amount in cents
      final totalAmountInCents = (item.pricePerKg * quantity * 100).toInt();
      // Call Stripe Edge Function to create checkout session
      final response = await _connector.client.functions.invoke(
        'stripe-create-checkout-session',
        body: {
          'itemId': item.inventoryId,
          'userId': userId,
          'merchantName': 'RecycleGo',
          'itemName':
              '${item.inventoryName ?? 'Item'} (${quantity.toStringAsFixed(2)} kg)',
          'amountInCents': totalAmountInCents,
          'currency': 'myr',
          'paymentMethodType': 'fpx',
          'customerEmail': userEmail,
          'successUrl': 'https://example.com/payment/success',
          'cancelUrl': 'https://example.com/payment/cancelled',
        },
      );

      // Handle response data
      final responseData = response.data as Map<String, dynamic>?;

      if (responseData != null && responseData.containsKey('error')) {
        throw Exception('Stripe error: ${responseData['error']}');
      }

      if (responseData != null &&
          responseData['success'] == true &&
          responseData['checkoutUrl'] != null) {
        return {
          'success': true,
          'checkoutUrl': responseData['checkoutUrl'] as String,
          'sessionId': responseData['sessionId'] as String,
        };
      } else {
        throw Exception(
          'Failed to create checkout session - success: ${responseData?['success']}, checkoutUrl: ${responseData?['checkoutUrl']}',
        );
      }
    } catch (e) {
      throw Exception('Payment processing error: $e');
    }
  }

  /// Generate next purchase ID based on existing purchases
  Future<String> generateNextPurchaseId() async {
    try {
      const basePrefix = '88888888-8888-8888-8888-';
      int maxSequence = 0;

      // Fetch all purchases to find highest sequence
      final response = await _connector.client
          .from('recyclepurchases')
          .select('purchase_id');

      for (var purchase in response as List) {
        final id = purchase['purchase_id'] ?? '';
        if (id.startsWith(basePrefix)) {
          final sequencePart = id.substring(basePrefix.length);
          final sequence = int.tryParse(sequencePart) ?? 0;
          if (sequence > maxSequence) {
            maxSequence = sequence;
          }
        }
      }

      // Generate next purchase ID with incremented sequence
      final nextSequence = maxSequence + 1;
      final sequenceStr = nextSequence.toString().padLeft(12, '0');
      final generatedId = '$basePrefix$sequenceStr';
      return generatedId;
    } catch (e) {
      throw Exception('Failed to generate purchase ID: $e');
    }
  }

  /// Create and save purchase record
  Future<String> createPurchaseRecord(
    String userId,
    RecycleInventory item,
    double quantity, {
    String? pickupLocationId,
    String? pickupLocationName,
    String? pickupAddress,
  }) async {
    try {
      // Generate sequential purchase ID
      final purchaseId = await generateNextPurchaseId();
      final totalPrice = item.pricePerKg * quantity;

      // Save purchase record with pending status
      final purchasesModel = RecyclePurchasesModel();
      final purchase = RecyclePurchases(
        purchaseId: purchaseId,
        userId: userId,
        totalPrice: totalPrice,
        paymentStatus: 'pending',
        itemName: item.inventoryName,
        quantity: quantity,
        pickupLocationId: pickupLocationId,
        pickupLocationName: pickupLocationName,
        pickupAddress: pickupAddress,
      );
      await purchasesModel.createPurchase(purchase);

      return purchaseId;
    } catch (e) {
      throw Exception('Failed to create purchase record: $e');
    }
  }

  /// Generate next voucher code based on existing vouchers
  Future<String> generateNextVoucherCode(String purchaseId) async {
    try {
      // Fetch ALL purchase ids (to find globally highest sequence)
      // You may need to adapt this based on your actual data structure
      const basePrefix = '88888888-8888-8888-8888-';

      // Find the highest existing sequence number globally
      int maxSequence = 0;

      // Fetch all redeemed vouchers (adapt this query to your schema)
      final response = await _connector.client
          .from('recycleinventory') // Adjust table name as needed
          .select();

      for (var voucher in response as List) {
        final code = voucher['voucher_code'] ?? '';
        if (code.startsWith(basePrefix)) {
          final sequencePart = code.substring(basePrefix.length);
          final sequence = int.tryParse(sequencePart) ?? 0;
          if (sequence > maxSequence) {
            maxSequence = sequence;
          }
        }
      }

      // Generate next code with incremented sequence
      final nextSequence = maxSequence + 1;
      final sequenceStr = nextSequence.toString().padLeft(12, '0');
      final generatedCode = '$basePrefix$sequenceStr';
      return generatedCode;
    } catch (e) {
      throw Exception('Failed to generate voucher code: $e');
    }
  }
}
