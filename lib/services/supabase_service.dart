import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseURL = 'https://ngcrvuzbxzwinnzmcwxj.supabase.co';
const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nY3J2dXpieHp3aW5uem1jd3hqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjg2Nzc3OCwiZXhwIjoyMDg4NDQzNzc4fQ.Kdok2tS8-QeMUPWqWuk9LfHKi82S3bT-egJ5k8_1ZoE';

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
