import 'package:recycle_go/models/Connector.dart';

// Entity
class RecyclePurchases {
  // --- ALLOWED STATUS VALUES ---
  static const List<String> allowedPaymentStatuses = ['success', 'pending', 'failed'];

  // FIXED: Strictly only these three statuses now. No 'in_transit'.
  static const List<String> allowedPickupStatuses = ['pending', 'completed', 'cancelled'];

  final String? purchaseId; // UUID - Primary Key
  final String userId; // UUID - FK to users table
  final double totalPrice; // Purchase amount
  final String paymentStatus; // e.g., 'success', 'pending', 'failed'
  final DateTime? createdAt; // Auto-generated timestamp
  final String? itemName; // Item purchased
  final double? quantity; // Quantity in kg
  final String? pickupLocationId; // UUID - FK to recycle_station
  final String? pickupLocationName; // Station name
  final String? pickupAddress; // Full address of pickup location
  final String? pickupStatus; // e.g., 'pending', 'completed', 'cancelled'

  RecyclePurchases({
    this.purchaseId,
    required this.userId,
    required this.totalPrice,
    required this.paymentStatus,
    this.createdAt,
    this.itemName,
    this.quantity,
    this.pickupLocationId,
    this.pickupLocationName,
    this.pickupAddress,
    this.pickupStatus,
  }) :
  // This strictly enforces your DB check constraint in Flutter!
        assert(
        allowedPaymentStatuses.contains(paymentStatus.toLowerCase()),
        'paymentStatus must be one of: $allowedPaymentStatuses',
        ),
        assert(
        pickupStatus == null || allowedPickupStatuses.contains(pickupStatus.toLowerCase()),
        'pickupStatus must be null or one of: $allowedPickupStatuses',
        );

  factory RecyclePurchases.fromJson(Map<String, dynamic> json) {
    return RecyclePurchases(
      purchaseId: json['purchase_id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status']?.toString().toLowerCase() ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      itemName: json['item_name']?.toString(),
      quantity: double.tryParse(json['quantity']?.toString() ?? '0'),
      pickupLocationId: json['pickup_location_id']?.toString(),
      pickupLocationName: json['pickup_location_name']?.toString(),
      pickupAddress: json['pickup_address']?.toString(),
      pickupStatus: json['pickup_status']?.toString().toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id': userId,
      'total_price': totalPrice,
      'payment_status': paymentStatus.toLowerCase(),
    };

    if (purchaseId != null && purchaseId!.isNotEmpty) {
      map['purchase_id'] = purchaseId;
    }
    if (createdAt != null) {
      map['created_at'] = createdAt!.toIso8601String();
    }
    if (itemName != null && itemName!.isNotEmpty) {
      map['item_name'] = itemName;
    }
    if (quantity != null) {
      map['quantity'] = quantity;
    }
    if (pickupLocationId != null && pickupLocationId!.isNotEmpty) {
      map['pickup_location_id'] = pickupLocationId;
    }
    if (pickupLocationName != null && pickupLocationName!.isNotEmpty) {
      map['pickup_location_name'] = pickupLocationName;
    }
    if (pickupAddress != null && pickupAddress!.isNotEmpty) {
      map['pickup_address'] = pickupAddress;
    }
    if (pickupStatus != null && pickupStatus!.isNotEmpty) {
      map['pickup_status'] = pickupStatus?.toLowerCase();
    }

    return map;
  }

  RecyclePurchases copyWith({
    String? purchaseId,
    String? userId,
    double? totalPrice,
    String? paymentStatus,
    DateTime? createdAt,
    String? itemName,
    double? quantity,
    String? pickupLocationId,
    String? pickupLocationName,
    String? pickupAddress,
    String? pickupStatus,
  }) {
    return RecyclePurchases(
      purchaseId: purchaseId ?? this.purchaseId,
      userId: userId ?? this.userId,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      pickupLocationId: pickupLocationId ?? this.pickupLocationId,
      pickupLocationName: pickupLocationName ?? this.pickupLocationName,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupStatus: pickupStatus ?? this.pickupStatus,
    );
  }
}

// Supabase connector
class RecyclePurchasesModel extends Connector {
  static final RecyclePurchasesModel _instance = RecyclePurchasesModel._internal();

  RecyclePurchasesModel._internal();

  factory RecyclePurchasesModel() => _instance;

  /// Fetch all purchases for a specific user
  Future<List<RecyclePurchases>> fetchUserPurchases(String userId) async {
    try {
      final response = await client
          .from('recyclepurchases')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((item) => RecyclePurchases.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching user purchases: $e');
      rethrow;
    }
  }

  /// Fetch a single purchase by ID
  Future<RecyclePurchases?> fetchPurchaseById(String purchaseId) async {
    try {
      final response = await client
          .from('recyclepurchases')
          .select()
          .eq('purchase_id', purchaseId)
          .maybeSingle();

      if (response != null) {
        return RecyclePurchases.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching purchase: $e');
      rethrow;
    }
  }

  /// Create a new purchase
  Future<RecyclePurchases?> createPurchase(RecyclePurchases purchase) async {
    try {
      final response = await client
          .from('recyclepurchases')
          .insert(purchase.toJson())
          .select()
          .single();

      return RecyclePurchases.fromJson(response);
    } catch (e) {
      print('Error creating purchase: $e');
      rethrow;
    }
  }

  /// Update purchase payment status securely
  Future<void> updatePaymentStatus(String purchaseId, String newStatus) async {
    final status = newStatus.toLowerCase();
    if (!RecyclePurchases.allowedPaymentStatuses.contains(status)) {
      throw Exception('Invalid payment status. Must be one of ${RecyclePurchases.allowedPaymentStatuses}');
    }

    try {
      await client
          .from('recyclepurchases')
          .update({'payment_status': status})
          .eq('purchase_id', purchaseId);
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }

  /// Update pickup status securely
  Future<void> updatePickupStatus(String purchaseId, String newStatus) async {
    final status = newStatus.toLowerCase();
    if (!RecyclePurchases.allowedPickupStatuses.contains(status)) {
      throw Exception('Invalid pickup status. Must be one of ${RecyclePurchases.allowedPickupStatuses}');
    }

    try {
      await client
          .from('recyclepurchases')
          .update({'pickup_status': status})
          .eq('purchase_id', purchaseId);
    } catch (e) {
      print('Error updating pickup status: $e');
      rethrow;
    }
  }

  /// Update bank account for a purchase
  Future<void> updateBankAccount(String purchaseId, String bankAccount) async {
    try {
      await client
          .from('recyclepurchases')
          .update({'bank_account': bankAccount})
          .eq('purchase_id', purchaseId);
    } catch (e) {
      print('Error updating bank account: $e');
      rethrow;
    }
  }

  /// Fetch all purchases (admin only)
  Future<List<RecyclePurchases>> fetchAllPurchases() async {
    try {
      final response = await client
          .from('recyclepurchases')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((item) => RecyclePurchases.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching all purchases: $e');
      rethrow;
    }
  }

  Future<bool> updatePurchaseStatus({
    required String purchaseId,
    required String paymentStatus,
    required String pickupStatus,
  }) async {
    final payment = paymentStatus.toLowerCase();
    final pickup = pickupStatus.toLowerCase();

    // ✅ Validate payment status
    if (!RecyclePurchases.allowedPaymentStatuses.contains(payment)) {
      throw Exception(
          'Invalid payment status. Must be one of ${RecyclePurchases.allowedPaymentStatuses}');
    }

    if (!RecyclePurchases.allowedPickupStatuses.contains(pickup)) {
      throw Exception(
          'Invalid pickup status. Must be one of ${RecyclePurchases.allowedPickupStatuses}');
    }

    try {
      final response = await client
          .from('recyclepurchases')
          .update({
        'payment_status': payment,
        'pickup_status': pickup,
      })
          .eq('purchase_id', purchaseId)
          .select();

      if (response.isEmpty) {
        throw Exception("Update failed: No record found.");
      }

      return true;
    } catch (e) {
      print('Error updating purchase status: $e');
      rethrow;
    }
  }
}