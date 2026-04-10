import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseURL = 'https://ngcrvuzbxzwinnzmcwxj.supabase.co';
const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nY3J2dXpieHp3aW5uem1jd3hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4Njc3NzgsImV4cCI6MjA4ODQ0Mzc3OH0.uyJm3x5VgRVQ0YFjMExEw8r9cB-r7rIp2MHZcUkw4ZI';

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
