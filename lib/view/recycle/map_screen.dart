import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'station_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  // Default center — KL coordinates, replace with user location via geolocator
  final LatLng _center = const LatLng(3.1390, 101.6869);

  // Mock station data — replace with API/Firestore
  final List<Map<String, dynamic>> _stations = [
    {
      'id': '1',
      'name': 'EcoHub Central',
      'type': 'PREMIUM STATION',
      'lat': 3.1390,
      'lng': 101.6869,
      'distance': '0.4 miles',
      'isOpen': true,
      'rating': 4.9,
      'imageUrl': '',
    },
    {
      'id': '2',
      'name': 'GreenPoint Central',
      'type': 'STANDARD STATION',
      'lat': 3.1420,
      'lng': 101.6830,
      'distance': '0.8 km',
      'isOpen': true,
      'rating': 4.5,
      'imageUrl': '',
    },
  ];

  Map<String, dynamic>? _selectedStation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
    _selectedStation = _stations[0];
  }

  void _buildMarkers() {
    setState(() {
      _markers = _stations.map((station) {
        return Marker(
          markerId: MarkerId(station['id']),
          position: LatLng(station['lat'], station['lng']),
          onTap: () => setState(() => _selectedStation = station),
        );
      }).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 14.5,
            ),
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ── Top bar ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1DB954),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.eco,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ECOLEDGER',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D3B1F),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      // Avatar with green tick
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFDDEEDD),
                            child: const Icon(Icons.person,
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
                      decoration: InputDecoration(
                        hintText: 'Search recycle stations..',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey[400], size: 20),
                        suffixIcon: Icon(Icons.tune,
                            color: const Color(0xFF1DB954), size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Map controls (right side) ───────────────────────────────
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              children: [
                _MapFab(
                  icon: Icons.my_location,
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(_center),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _MapFab(
                  icon: Icons.layers_outlined,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ── Active QR scan badge on map ────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 230,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom station card ─────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 70,
            child: _selectedStation == null
                ? const SizedBox()
                : _StationCard(
              station: _selectedStation!,
              onDirections: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StationDetailScreen(
                      station: _selectedStation!,
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

// ── Reusable map FAB ──────────────────────────────────────────────────
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

// ── Bottom station preview card ───────────────────────────────────────
class _StationCard extends StatelessWidget {
  final Map<String, dynamic> station;
  final VoidCallback onDirections;

  const _StationCard({
    required this.station,
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
            // Top row: image + info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Station thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 90,
                      height: 80,
                      color: const Color(0xFFDDEEDD),
                      child: const Icon(Icons.recycling,
                          color: Color(0xFF1DB954), size: 36),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              station['type'] ?? '',
                              style: const TextStyle(
                                color: Color(0xFF1DB954),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF7EE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Color(0xFF1DB954), size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${station['rating']}',
                                    style: const TextStyle(
                                      color: Color(0xFF1DB954),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          station['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D1F0D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.navigation,
                                color: Color(0xFF666), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${station['distance']} away  •  ',
                              style: const TextStyle(
                                  color: Color(0xFF666666), fontSize: 13),
                            ),
                            Text(
                              station['isOpen'] == true
                                  ? 'Open now'
                                  : 'Closed',
                              style: TextStyle(
                                color: station['isOpen'] == true
                                    ? const Color(0xFF1DB954)
                                    : Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.diamond_outlined,
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
                        foregroundColor: Colors.white,
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