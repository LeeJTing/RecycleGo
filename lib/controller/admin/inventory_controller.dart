import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import '../../services/supabase_service.dart';

class InventoryController {
  static const String _tableName = 'recycleinventory';
  static final supabase = SupabaseService().client;

  // Cache variables
  static List<RecycleInventory>? _cachedItems;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5); // Cache for 5 minutes

  /// Uploads an image to Supabase Storage and returns the public URL
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'inventory_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('inventory-images').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      return supabase.storage.from('inventory-images').getPublicUrl(fileName);
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  /// Generates a unique 6-character inventory code based on the item name
  static String generateCode(String name) {
    final prefix = name.length >= 3
        ? name.substring(0, 3).toUpperCase()
        : name.toUpperCase();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final short = timestamp.toString().substring(0, 3);

    return "$prefix-$short";
  }

  // ==========================================
  // DATABASE OPERATIONS
  // ==========================================

  static Future<List<RecycleInventory>> getInventory({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedItems != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedItems!;
      }
    }

    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .order('updated_at', ascending: false);

      _cachedItems = response.map((json) => RecycleInventory.fromJson(json)).toList();
      _cacheTime = DateTime.now();
      return _cachedItems!;
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  static void _invalidateCache() {
    _cachedItems = null;
    _cacheTime = null;
  }

  /// Add a brand new inventory item
  static Future<void> addInventory(RecycleInventory item) async {
    final data = item.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();

    await supabase.from(_tableName).insert(data);
    _invalidateCache();
  }

  /// Bypass cache and forcefully get a fresh list from the database
  static Future<List<RecycleInventory>> getInventories() async {
    final res = await supabase
        .from(_tableName)
        .select()
        .order('updated_at', ascending: false);

    return (res as List).map((e) => RecycleInventory.fromJson(e)).toList();
  }

  /// Fetch a single specific item by its ID
  static Future<RecycleInventory?> getInventoryById(String id) async {
    final res = await supabase
        .from(_tableName)
        .select()
        .eq('inventory_id', id)
        .maybeSingle();

    if (res == null) return null;
    return RecycleInventory.fromJson(res);
  }

  /// Update an existing item
  static Future<void> updateInventory(RecycleInventory item) async {
    if (item.inventoryId == null) throw Exception("Inventory ID is null");

    final data = item.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();

    await supabase
        .from(_tableName)
        .update(data)
        .eq('inventory_id', item.inventoryId!);

    _invalidateCache();
  }

  /// Delete an item entirely
  static Future<void> deleteInventory(String id) async {
    await supabase.from(_tableName).delete().eq('inventory_id', id);
    _invalidateCache();
  }
}