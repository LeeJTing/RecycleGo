import 'package:recycle_go/models/Connector.dart';

// Entity
class RecyclePurchases {
  final String? purchaseId; // UUID - Primary Key
  final String userId; // UUID - FK to users table
  final double totalPrice; // Purchase amount
  final String paymentStatus; // e.g., 'success', 'pending', 'failed'
  final DateTime? createdAt; // Auto-generated timestamp
  final String? bankAccount; // Bank account for payment
  final String? itemName; // Item purchased
  final double? quantity; // Quantity in kg
  final String? pickupLocationId; // UUID - FK to recycle_station
  final String? pickupLocationName; // Station name
  final String? pickupAddress; // Full address of pickup location

  RecyclePurchases({
    this.purchaseId,
    required this.userId,
    required this.totalPrice,
    required this.paymentStatus,
    this.createdAt,
    this.bankAccount,
    this.itemName,
    this.quantity,
    this.pickupLocationId,
    this.pickupLocationName,
    this.pickupAddress,
  });

  factory RecyclePurchases.fromJson(Map<String, dynamic> json) {
    return RecyclePurchases(
      purchaseId: json['purchase_id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      totalPrice:
          double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      bankAccount: json['bank_account']?.toString(),
      itemName: json['item_name']?.toString(),
      quantity: double.tryParse(json['quantity']?.toString() ?? '0'),
      pickupLocationId: json['pickup_location_id']?.toString(),
      pickupLocationName: json['pickup_location_name']?.toString(),
      pickupAddress: json['pickup_address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id': userId,
      'total_price': totalPrice,
      'payment_status': paymentStatus,
    };

    if (purchaseId != null && purchaseId!.isNotEmpty) {
      map['purchase_id'] = purchaseId;
    }

    if (createdAt != null) {
      map['created_at'] = createdAt!.toIso8601String();
    }

    if (bankAccount != null && bankAccount!.isNotEmpty) {
      map['bank_account'] = bankAccount;
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

    return map;
  }

  RecyclePurchases copyWith({
    String? purchaseId,
    String? userId,
    double? totalPrice,
    String? paymentStatus,
    DateTime? createdAt,
    String? bankAccount,
    String? itemName,
    double? quantity,
    String? pickupLocationId,
    String? pickupLocationName,
    String? pickupAddress,
  }) {
    return RecyclePurchases(
      purchaseId: purchaseId ?? this.purchaseId,
      userId: userId ?? this.userId,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      bankAccount: bankAccount ?? this.bankAccount,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      pickupLocationId: pickupLocationId ?? this.pickupLocationId,
      pickupLocationName: pickupLocationName ?? this.pickupLocationName,
      pickupAddress: pickupAddress ?? this.pickupAddress,
    );
  }
}

// Supabase connector
class RecyclePurchasesModel extends Connector {
  static final RecyclePurchasesModel _instance =
      RecyclePurchasesModel._internal();

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

      return (response as List)
          .map((item) => RecyclePurchases.fromJson(item))
          .toList();
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

  /// Update purchase payment status
  Future<void> updatePaymentStatus(String purchaseId, String newStatus) async {
    try {
      await client
          .from('recyclepurchases')
          .update({'payment_status': newStatus})
          .eq('purchase_id', purchaseId);
    } catch (e) {
      print('Error updating payment status: $e');
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

      return (response as List)
          .map((item) => RecyclePurchases.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching all purchases: $e');
      rethrow;
    }
  }
}
