import 'package:recycle_go/models/RecycleInventory.dart';
import '../../services/supabase_service.dart';

class InventoryController {
  static const String _tableName = 'recycleinventory';
  static final supabase = SupabaseService().client;

  // Cache variables
  static List<RecycleInventory>? _cachedItems;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5); // Cache for 5 minutes

  static Future<List<RecycleInventory>> getInventory({bool forceRefresh = false}) async {
    // Return cached data if it's fresh and not forcing refresh
    if (!forceRefresh && _cachedItems != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedItems!;
      }
    }

    // Otherwise fetch from network
    try {
      final response = await supabase.from(_tableName).select();
      _cachedItems = response.map((json) => RecycleInventory.fromJson(json)).toList();
      _cacheTime = DateTime.now();
      return _cachedItems!;
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  /// Add a new inventory item and invalidate cache.
  static Future<void> addInventory(RecycleInventory item) async {
    await supabase.from(_tableName).insert(item.toJson());
    _invalidateCache();
  }

  /// Update an existing inventory item and invalidate cache.
  static Future<void> updateInventory(RecycleInventory item) async {
    await supabase
        .from(_tableName)
        .update(item.toJson())
        .eq('inventory_id', item.inventoryId);
    _invalidateCache();
  }

  /// Delete an inventory item and invalidate cache.
  static Future<void> deleteInventory(String inventoryId) async {
    await supabase.from(_tableName).delete().eq('inventory_id', inventoryId);
    _invalidateCache();
  }

  /// Helper to clear the cache (called after any write operation).
  static void _invalidateCache() {
    _cachedItems = null;
    _cacheTime = null;
  }
}