import 'package:recycle_go/models/Connector.dart';
import 'dart:math';

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
  final String stationId;
  final String stationName;
  final String address;
  final double latitude;
  final double longitude;
  final String? description;
  final StationStatus stationStatus;
  final double plasticStorage;
  final double paperStorage;
  final double glassStorage;
  final double cardboardStorage;
  final double metalStorage;
  final String qrCodeValue;
  final DateTime createdAt;
  final String? imageUrl;

  const RecycleStation({
    required this.stationId,
    required this.stationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.stationStatus,
    this.plasticStorage = 0,
    this.paperStorage = 0,
    this.glassStorage = 0,
    this.cardboardStorage = 0,
    this.metalStorage = 0,
    required this.qrCodeValue,
    required this.createdAt,
    this.imageUrl,
  });

  double get totalCapacity =>
      plasticStorage + paperStorage + glassStorage +
          cardboardStorage + metalStorage;

  List<RecycleMaterialType> get supportedMaterials => [
    if (plasticStorage > 0) RecycleMaterialType.plastic,
    if (paperStorage > 0) RecycleMaterialType.paper,
    if (glassStorage > 0) RecycleMaterialType.glass,
    if (cardboardStorage > 0) RecycleMaterialType.cardboard,
    if (metalStorage > 0) RecycleMaterialType.metal,
  ];

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
  }) =>
      RecycleStation(
        stationId: stationId ?? this.stationId,
        stationName: stationName ?? this.stationName,
        address: address ?? this.address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        description: description ?? this.description,
        stationStatus: stationStatus ?? this.stationStatus,
        plasticStorage: plasticStorage ?? this.plasticStorage,
        paperStorage: paperStorage ?? this.paperStorage,
        glassStorage: glassStorage ?? this.glassStorage,
        cardboardStorage: cardboardStorage ?? this.cardboardStorage,
        metalStorage: metalStorage ?? this.metalStorage,
        qrCodeValue: qrCodeValue ?? this.qrCodeValue,
        createdAt: createdAt ?? this.createdAt,
        imageUrl: imageUrl ?? this.imageUrl,
      );

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

  Map<String, dynamic> toMap() => {
    'station_id': stationId,
    'station_name': stationName,
    'address': address,
    'latitude': latitude,
    'longitude': longitude, // DB column typo preserved
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

  factory RecycleStation.fromMap(Map<String, dynamic> map) => RecycleStation(
    stationId: map['station_id'] ?? '',
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
    plasticStorage: (map['plastic_storage'] ?? 0).toDouble(),
    paperStorage: (map['paper_storage'] ?? 0).toDouble(),
    glassStorage: (map['glasses_storage'] ?? 0).toDouble(),
    cardboardStorage: (map['cardboard_storage'] ?? 0).toDouble(),
    metalStorage: (map['metal_storage'] ?? 0).toDouble(),
    qrCodeValue: map['qr_code_value'] ?? '',
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    imageUrl: map['image_url']?.toString(),
  );

  factory RecycleStation.fromJson(Map<String, dynamic> json) {
    return RecycleStation.fromMap(json);
  }
}

class RecycleStationModel extends Connector {}
