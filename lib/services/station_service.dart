import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/models/RecycleStations.dart';
import 'dart:math';

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
    final map = station.toMap()
      ..remove('station_id'); // let Supabase generate UUID
    final response = await _db.from(_table).insert(map).select().single();

    return RecycleStation.fromMap(response as Map<String, dynamic>);
  }

  // ── UPDATE ────────────────────────────────────────────────────────
  static Future<RecycleStation?> update(RecycleStation station) async {
    final map = station.toMap()
      ..remove('station_id')
      ..remove('created_at');
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

  // ── DISTANCE CALCULATION ──────────────────────────────────────────
  /// Get nearest stations sorted by distance from user location
  static Future<List<StationWithDistance>> getNearestStations(
    double userLatitude,
    double userLongitude,
  ) async {
    final stations = await fetchActive();

    // Calculate distance for each station
    final stationsWithDistance = stations.map((station) {
      final distance = _calculateDistance(
        userLatitude,
        userLongitude,
        station.latitude,
        station.longitude,
      );
      return StationWithDistance(station, distance);
    }).toList();

    // Sort by distance (nearest first)
    stationsWithDistance.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return stationsWithDistance;
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(
    double userLat,
    double userLng,
    double stationLat,
    double stationLng,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRad(stationLat - userLat);
    final dLng = _toRad(stationLng - userLng);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(userLat)) *
            cos(_toRad(stationLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double degree) => degree * pi / 180.0;
}

/// Helper class to pair station with calculated distance
class StationWithDistance {
  final RecycleStation station;
  final double distanceKm;

  StationWithDistance(this.station, this.distanceKm);

  String get distanceText {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }
}
