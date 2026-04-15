import 'package:recycle_go/models/Connector.dart';

// Entity
class RecyclePurchases {
  final String? purchaseId; // UUID - Primary Key
  final String userId; // UUID - FK to users table
  final double totalPrice; // Purchase amount
  final String paymentStatus; // e.g., 'success', 'pending', 'failed'
  final DateTime? createdAt; // Auto-generated timestamp

  RecyclePurchases({
    this.purchaseId,
    required this.userId,
    required this.totalPrice,
    required this.paymentStatus,
    this.createdAt,
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

    return map;
  }

  RecyclePurchases copyWith({
    String? purchaseId,
    String? userId,
    double? totalPrice,
    String? paymentStatus,
    DateTime? createdAt,
  }) {
    return RecyclePurchases(
      purchaseId: purchaseId ?? this.purchaseId,
      userId: userId ?? this.userId,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
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
