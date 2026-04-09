import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:recycle_go/models/RecycleStations.dart';
import 'package:recycle_go/services/station_service.dart';
import 'package:recycle_go/view/recycle/station_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ── Map controller ────────────────────────────────────────────────
  GoogleMapController? _mapController;

  // ── Location state ────────────────────────────────────────────────
  LatLng _currentPosition = const LatLng(3.1390, 101.6869); // KL fallback
  bool _locationReady = false;

  // ── Station state ─────────────────────────────────────────────────
  List<RecycleStation> _stations = [];
  RecycleStation? _selectedStation;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;

  // ── Search ────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<RecycleStation> _filteredStations = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadStations();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── 1. Get user GPS location ──────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      // Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        // Use fallback KL coords silently
        return;
      }

      // Get current position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _locationReady = true;
      });

      // Move camera to user location once map is ready
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 14.5),
        ),
      );

      // Re-sort stations by distance now that we have real location
      if (_stations.isNotEmpty) _sortAndRebuildMarkers();
    } catch (e) {
      // Silently fall back to default coords
      debugPrint('Location error: $e');
    }
  }

  // ── 2. Load stations from Supabase ───────────────────────────────
  Future<void> _loadStations() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final stations = await StationService.fetchActive();
      if (!mounted) return;
      setState(() {
        _stations = stations;
        _filteredStations = stations;
        _isLoading = false;
      });
      _sortAndRebuildMarkers();
      // Auto-select closest station
      if (_stations.isNotEmpty) {
        setState(() => _selectedStation = _stations.first);
      }
    } catch (e) {
      if (!mounted) return;
      print('DEBUG ERROR: $e');
      setState(() {
        _error = 'Failed to load stations: $e';
        _isLoading = false;
      });
    }
  }

  // ── 3. Sort by distance + build map markers ───────────────────────
  void _sortAndRebuildMarkers() {
    final sorted = List<RecycleStation>.from(_stations);
    sorted.sort((a, b) => a
        .distanceFrom(_currentPosition.latitude, _currentPosition.longitude)
        .compareTo(b.distanceFrom(
        _currentPosition.latitude, _currentPosition.longitude)));

    final markers = sorted.map((s) {
      return Marker(
        markerId: MarkerId(s.stationId),
        position: LatLng(s.latitude, s.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          s.isActive
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(title: s.stationName, snippet: s.address),
        onTap: () => setState(() => _selectedStation = s),
      );
    }).toSet();

    setState(() {
      _stations = sorted;
      _filteredStations = sorted;
      _markers = markers;
      if (_selectedStation == null && sorted.isNotEmpty) {
        _selectedStation = sorted.first;
      }
    });
  }

  // ── 4. Search filter ──────────────────────────────────────────────
  void _onSearch(String query) {
    setState(() {
      _filteredStations = query.isEmpty
          ? _stations
          : _stations
          .where((s) =>
      s.stationName.toLowerCase().contains(query.toLowerCase()) ||
          s.address.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // ── 5. Re-centre camera to user ───────────────────────────────────
  void _goToMyLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition, zoom: 15),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  String _formatDistance(RecycleStation s) {
    final km = s.distanceFrom(
        _currentPosition.latitude, _currentPosition.longitude);
    return km < 1
        ? '${(km * 1000).toStringAsFixed(0)} m'
        : '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14.5,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              // If we already have GPS by the time map loads, move there
              if (_locationReady) {
                controller.animateCamera(
                  CameraUpdate.newLatLng(_currentPosition),
                );
              }
            },
            // ✅ Blue dot = built-in Google Maps "My Location" layer
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // we use our own FAB
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (_) => setState(() => _selectedStation = null),
          ),

          // ── Top bar ─────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1DB954),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.eco,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ECOLEDGER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D3B1F),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Stack(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFDDEEDD),
                            child: Icon(Icons.person,
                                color: Color(0xFF0D3B1F), size: 22),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1DB954),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Search recycle stations..',
                        hintStyle: TextStyle(
                            color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey[400], size: 20),
                        suffixIcon: const Icon(Icons.tune,
                            color: Color(0xFF1DB954), size: 20),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Loading indicator ───────────────────────────────────
          if (_isLoading)
            const Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1DB954),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Loading stations...',
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Error message ───────────────────────────────────────
          if (_error != null)
            Positioned(
              top: 140,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade400, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13)),
                    ),
                    GestureDetector(
                      onTap: _loadStations,
                      child: Text('Retry',
                          style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Map FABs (right side) ───────────────────────────────
          Positioned(
            right: 16,
            bottom: _selectedStation != null ? 250 : 120,
            child: Column(
              children: [
                // My location button
                _MapFab(
                  icon: Icons.my_location,
                  onTap: _goToMyLocation,
                ),
                const SizedBox(height: 12),
                _MapFab(
                  icon: Icons.layers_outlined,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ── Station count badge ─────────────────────────────────
          if (!_isLoading && _stations.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: _selectedStation != null ? 242 : 112,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1DB954).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.recycling,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${_filteredStations.length} ACTIVE STATION${_filteredStations.length != 1 ? 'S' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom station card ─────────────────────────────────
          if (_selectedStation != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 70,
              child: _StationCard(
                station: _selectedStation!,
                distance: _formatDistance(_selectedStation!),
                onDirections: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StationDetailScreen(
                        station: _selectedStation!.toMap()
                          ..['distance'] =
                          _formatDistance(_selectedStation!),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Reusable map FAB
// ─────────────────────────────────────────────────────────────────────
class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF0D3B1F), size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Bottom station preview card
// ─────────────────────────────────────────────────────────────────────
class _StationCard extends StatelessWidget {
  final RecycleStation station;
  final String distance;
  final VoidCallback onDirections;

  const _StationCard({
    required this.station,
    required this.distance,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Station image or fallback icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: station.imageUrl != null &&
                        station.imageUrl!.isNotEmpty
                        ? Image.network(
                      station.imageUrl!,
                      width: 90,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _StationIconPlaceholder(),
                    )
                        : _StationIconPlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: station.isActive
                                    ? const Color(0xFFEAF7EE)
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                  station.stationStatus.label,
                                style: TextStyle(
                                  color: station.isActive
                                      ? const Color(0xFF1DB954)
                                      : const Color(0xFFF5A623),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            // Capacity badge
                            _CapacityBadge(
                                totalKg: station.totalCapacity),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Station name
                        Text(
                          station.stationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D1F0D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // Distance + address
                        Row(
                          children: [
                            const Icon(Icons.navigation,
                                color: Color(0xFF888), size: 12),
                            const SizedBox(width: 3),
                            Text(
                              '$distance away',
                              style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 12),
                            ),
                            const Text('  •  ',
                                style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 12)),
                            Expanded(
                              child: Text(
                                station.address,
                                style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Buttons row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.navigation,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'DIRECTIONS',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_border,
                        color: Color(0xFF333), size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationIconPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 90,
    height: 80,
    color: const Color(0xFFDDEEDD),
    child:
    const Icon(Icons.recycling, color: Color(0xFF1DB954), size: 36),
  );
}

class _CapacityBadge extends StatelessWidget {
  final double totalKg;
  const _CapacityBadge({required this.totalKg});

  @override
  Widget build(BuildContext context) {
    final label = totalKg >= 1000
        ? '${(totalKg / 1000).toStringAsFixed(1)}t cap'
        : '${totalKg.toStringAsFixed(0)}kg cap';
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Color(0xFF666), fontSize: 10,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}