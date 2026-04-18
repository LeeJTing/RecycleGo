import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/services/supabase_service.dart';

import '../services/storage_service.dart';

class Connector {
  // Use the singleton client from your SupabaseService
  final client = SupabaseService().client;

  final storage = StorageService();
}
