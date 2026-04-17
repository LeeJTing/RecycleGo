import 'package:recycle_go/models/Connector.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

// lib/models/recycle_station_model.dart

enum StationStatus { active, maintenance, offline }

enum RecycleMaterialType { plastic, paper, glass, cardboard, metal }

extension StationStatusExt on StationStatus {
  String get label {
    switch (this) {
      case StationStatus.active:      return 'ACTIVE';
      case StationStatus.maintenance: return 'MAINTENANCE';
      case StationStatus.offline:     return 'OFFLINE';
    }
  }
}

extension MaterialTypeExt on RecycleMaterialType {
  String get label {
    switch (this) {
      case RecycleMaterialType.plastic:   return 'PLASTIC';
      case RecycleMaterialType.paper:     return 'PAPER';
      case RecycleMaterialType.glass:     return 'GLASS';
      case RecycleMaterialType.cardboard: return 'CARDBOARD';
      case RecycleMaterialType.metal:     return 'METAL';
    }
  }
}

class RecycleStation {
  final String? stationId;
  final String stationName;
  final String address;
  final double latitude;
  final double longitude;
  final String? description;
  final StationStatus stationStatus;
  final double? plasticStorage;
  final double? paperStorage;
  final double? glassStorage;
  final double? cardboardStorage;
  final double? metalStorage;
  final String qrCodeValue;
  final DateTime createdAt;
  final String? imageUrl;

  const RecycleStation({
    this.stationId,
    required this.stationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.stationStatus,
    this.plasticStorage,
    this.paperStorage,
    this.glassStorage,
    this.cardboardStorage,
    this.metalStorage,
    required this.qrCodeValue,
    required this.createdAt,
    this.imageUrl,
  });

  double get totalCapacity =>
      (plasticStorage ?? 0) +
          (paperStorage ?? 0) +
          (glassStorage ?? 0) +
          (cardboardStorage ?? 0) +
          (metalStorage ?? 0);

  List<RecycleMaterialType> get supportedMaterials {
    final list = <RecycleMaterialType>[];

    if (plasticStorage != null) {
      list.add(RecycleMaterialType.plastic);
    }
    if (paperStorage != null) {
      list.add(RecycleMaterialType.paper);
    }
    if (glassStorage != null) {
      list.add(RecycleMaterialType.glass);
    }
    if (cardboardStorage != null) {
      list.add(RecycleMaterialType.cardboard);
    }
    if (metalStorage != null) {
      list.add(RecycleMaterialType.metal);
    }

    return list;
  }

  RecycleStation copyWith({
    String? stationId,
    String? stationName,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    StationStatus? stationStatus,
    double? plasticStorage,
    double? paperStorage,
    double? glassStorage,
    double? cardboardStorage,
    double? metalStorage,
    String? qrCodeValue,
    DateTime? createdAt,
    String? imageUrl,
    bool setPlasticNull = false,
    bool setPaperNull = false,
    bool setGlassNull = false,
    bool setCardboardNull = false,
    bool setMetalNull = false,
  }) {
    return RecycleStation(
      stationId: stationId ?? this.stationId,
      stationName: stationName ?? this.stationName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      stationStatus: stationStatus ?? this.stationStatus,

      plasticStorage: setPlasticNull
          ? null
          : (plasticStorage ?? this.plasticStorage),

      paperStorage: setPaperNull
          ? null
          : (paperStorage ?? this.paperStorage),

      glassStorage: setGlassNull
          ? null
          : (glassStorage ?? this.glassStorage),

      cardboardStorage: setCardboardNull
          ? null
          : (cardboardStorage ?? this.cardboardStorage),

      metalStorage: setMetalNull
          ? null
          : (metalStorage ?? this.metalStorage),

      qrCodeValue: qrCodeValue ?? this.qrCodeValue,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  bool get isActive => stationStatus == StationStatus.active;

  // Distance in km from a given point (Haversine formula)
  double distanceFrom(double lat, double lng) {
    const R = 6371.0;

    final dLat = _toRad(latitude - lat);
    final dLng = _toRad(longitude - lng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat)) * cos(_toRad(latitude)) *
            sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a.clamp(0, 1)));

    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  Map<String, dynamic> toMap() {
    final data = {
      'station_name': stationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'station_status': stationStatus.name,
      'plastic_storage': plasticStorage,
      'paper_storage': paperStorage,
      'glasses_storage': glassStorage,
      'cardboard_storage': cardboardStorage,
      'metal_storage': metalStorage,
      'qr_code_value': qrCodeValue,
      'created_at': createdAt.toIso8601String(),
      'image_url': imageUrl,
    };

    // ✅ 只有 update 才传 id
    if (stationId != null) {
      data['station_id'] = stationId;
    }

    return data;
  }

  factory RecycleStation.fromMap(Map<String, dynamic> map) => RecycleStation(
    stationId: map['station_id'],
    stationName: map['station_name'] ?? '',
    address: map['address'] ?? '',
    latitude: (map['latitude'] ?? 0).toDouble(),
    longitude: (map['longitude'] ?? 0).toDouble(),
    description: map['description'],
    stationStatus: StationStatus.values.firstWhere(
          (s) =>
      s.name.toLowerCase() ==
          (map['station_status'] ?? '').toString().toLowerCase(),
      orElse: () => StationStatus.active,
    ),
    plasticStorage: map['plastic_storage'] != null
        ? (map['plastic_storage'] as num).toDouble()
        : null,
    paperStorage: map['paper_storage'] != null
        ? (map['paper_storage'] as num).toDouble()
        : null,

    glassStorage: map['glasses_storage'] != null
        ? (map['glasses_storage'] as num).toDouble()
        : null,

    cardboardStorage: map['cardboard_storage'] != null
        ? (map['cardboard_storage'] as num).toDouble()
        : null,

    metalStorage: map['metal_storage'] != null
        ? (map['metal_storage'] as num).toDouble()
        : null,
    qrCodeValue: map['qr_code_value'] ?? '',
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    imageUrl: map['image_url']?.toString(),
  );

  factory RecycleStation.fromJson(Map<String, dynamic> json) {
    return RecycleStation.fromMap(json);
  }
}

class RecycleStationModel extends Connector {
  static final RecycleStationModel _instance = RecycleStationModel._internal();
  factory RecycleStationModel() => _instance;
  RecycleStationModel._internal();

  Future<RecycleStation?> getNearestStation() async {
    try {
      final response = await client
          .from('recyclestation')
          .select()
          .eq('station_status', 'active')
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return RecycleStation.fromJson(response);
      }
    } catch (e) {
      print('DEBUG: Error fetching nearest station: $e');
    }
    return null;
  }

  // ✅ CREATE
  Future<RecycleStation?> insertStation(RecycleStation s) async {
    try {
      print('📦 DATA => ${s.toMap()}'); // 👈 一定要加

      final res = await client
          .from('recyclestation')
          .insert(s.toMap())
          .select()
          .single();

      return RecycleStation.fromJson(res);

    } catch (e) {
      print('❌ ERROR TYPE: ${e.runtimeType}');
      print('❌ ERROR: $e');

      if (e is PostgrestException) {
        print('❌ MESSAGE: ${e.message}');
        print('❌ DETAILS: ${e.details}');
        print('❌ HINT: ${e.hint}');
        print('❌ CODE: ${e.code}');
      }

      return null;
    }
  }

  // ✅ UPDATE
  Future<RecycleStation?> updateStation(RecycleStation s) async {
    try {
      if (s.stationId == null) {
        throw Exception('stationId is null, cannot update');
      }

      final res = await client
          .from('recyclestation')
          .update(s.toMap())
          .eq('station_id', s.stationId!) // 👈 加 !
          .select()
          .single();

      return RecycleStation.fromJson(res);
    } catch (e) {
      print('DEBUG: Update error: $e');
      return null;
    }
  }

  // ✅ DELETE
  Future<bool> deleteStation(String id) async {
    print('DELETE ID: $id');

    try {
      final submissions = await client
          .from('recyclingsubmission')
          .select('submission_id')
          .eq('station_id', id);

      final submissionIds = (submissions as List)
          .map((e) => e['submission_id'])
          .toList();

      if (submissionIds.isNotEmpty) {
        await client
            .from('appeals')
            .delete()
            .inFilter('submission_id', submissionIds);
      }

      await client
          .from('recyclingsubmission')
          .delete()
          .eq('station_id', id);

      final res = await client
          .from('recyclestation')
          .delete()
          .eq('station_id', id)
          .select();

      return res.isNotEmpty;

    } catch (e) {
      print('DELETE ERROR: $e');
      return false;
    }
  }

  Future<List<RecycleStation>> getAllStations() async {
    try {
      final response = await client
          .from('recyclestation')
          .select();

      return (response as List)
          .map((e) => RecycleStation.fromJson(e))
          .toList();
    } catch (e) {
      print('DEBUG: Error fetching stations: $e');
      return [];
    }
  }
}
