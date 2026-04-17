import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseURL = 'https://ngcrvuzbxzwinnzmcwxj.supabase.co';
const String _supabaseKey = 'sb_secret_BI12ya7Iu0j_6nBiveE4gw_rw-Btqfe';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  static Future<void> initialize() async{
    try {
      await Supabase.initialize(url: _supabaseURL, anonKey: _supabaseKey);
      print('DEBUG: Supabase initialized successfully');
    } catch (e) {
      print('DEBUG: Supabase initialization failed: $e');
    }
  }

  SupabaseClient get client => Supabase.instance.client;
}
