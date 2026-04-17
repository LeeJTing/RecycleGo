import 'package:recycle_go/models/Connector.dart';

class RecycleStation {
  final String? stationId;
  final String stationName;
  final String address;
  final double latitude;
  final double longitude;
  final String? description;
  final String stationStatus;
  final double plasticStorage;
  final double glassesStorage;
  final double cardboardStorage;
  final double metalStorage;
  final String qrCodeValue;
  final String? imageUrl;
  final DateTime? createdAt;

  RecycleStation({
    this.stationId,
    required this.stationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.stationStatus,
    this.plasticStorage = 0,
    this.glassesStorage = 0,
    this.cardboardStorage = 0,
    this.metalStorage = 0,
    required this.qrCodeValue,
    this.imageUrl,
    this.createdAt,
  });

  factory RecycleStation.fromJson(Map<String, dynamic> json) {
    return RecycleStation(
      stationId: json['station_id'],
      stationName: json['station_name'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'],
      stationStatus: json['station_status'],
      plasticStorage: (json['plastic_storage'] as num).toDouble(),
      glassesStorage: (json['glasses_storage'] as num).toDouble(),
      cardboardStorage: (json['cardboard_storage'] as num).toDouble(),
      metalStorage: (json['metal_storage'] as num).toDouble(),
      qrCodeValue: json['qr_code_value'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'station_name': stationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'station_status': stationStatus,
      'plastic_storage': plasticStorage,
      'glasses_storage': glassesStorage,
      'cardboard_storage': cardboardStorage,
      'metal_storage': metalStorage,
      'qr_code_value': qrCodeValue,
      'image_url': imageUrl,
    };
    if (stationId != null) data['station_id'] = stationId;
    return data;
  }
}

class RecycleStationModel extends Connector {
  static final RecycleStationModel _instance = RecycleStationModel._internal();
  factory RecycleStationModel() => _instance;
  RecycleStationModel._internal();

  Future<List<RecycleStation>> getAllStations() async {
    final response = await client.from('recyclestation').select();
    return (response as List).map((json) => RecycleStation.fromJson(json)).toList();
  }
}
