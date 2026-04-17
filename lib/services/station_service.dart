
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/models/RecycleStations.dart';

class StationService {
  static final _db = Supabase.instance.client;
  static const _table = 'recyclestation';

  // ── READ: fetch all stations ─────────────────────────────────────
  static Future<List<RecycleStation>> fetchAll() async {
    final response = await _db
        .from(_table)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => RecycleStation.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // ── READ: fetch active stations only ─────────────────────────────
  static Future<List<RecycleStation>> fetchActive() async {
    final response = await _db
        .from(_table)
        .select()
        .eq('station_status', 'active')
        .order('station_name', ascending: true);

    return (response as List)
        .map((row) => RecycleStation.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // ── READ: fetch single station by id ─────────────────────────────
  static Future<RecycleStation?> fetchById(String stationId) async {
    final response = await _db
        .from(_table)
        .select()
        .eq('station_id', stationId)
        .maybeSingle();

    if (response == null) return null;
    return RecycleStation.fromMap(response as Map<String, dynamic>);
  }

  // ── CREATE ────────────────────────────────────────────────────────
  static Future<RecycleStation?> create(RecycleStation station) async {
    final map = station.toMap()..remove('station_id'); // let Supabase generate UUID
    final response = await _db
        .from(_table)
        .insert(map)
        .select()
        .single();

    return RecycleStation.fromMap(response as Map<String, dynamic>);
  }

  // ── UPDATE ────────────────────────────────────────────────────────
  static Future<RecycleStation?> update(RecycleStation station) async {
    final map = station.toMap()..remove('station_id')..remove('created_at');
    final response = await _db
        .from(_table)
        .update(map)
        .eq('station_id', station.stationId)
        .select()
        .single();

    return RecycleStation.fromMap(response as Map<String, dynamic>);
  }

  // ── DELETE ────────────────────────────────────────────────────────
  static Future<void> delete(String stationId) async {
    await _db.from(_table).delete().eq('station_id', stationId);
  }
}