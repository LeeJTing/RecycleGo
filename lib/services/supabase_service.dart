import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseURL = 'https://ngcrvuzbxzwinnzmcwxj.supabase.co';
const String _supabaseKey = 'sb_publishable_1yK9-NCtNnVTIEiJWU8zUg_zEE9AdFa';

class SupabaseService {
  // generate Singleton
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  // naming the constructor as _internal
  SupabaseService._internal();

  static Future<void> initialize() async{
    await Supabase.initialize(
      url: _supabaseURL,
      anonKey: _supabaseKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;
}