import 'package:flutter/material.dart';
import 'qr_scan_screen.dart';
import 'package:recycle_go/models/RecycleStations.dart';

class StationDetailScreen extends StatelessWidget {
  final RecycleStation station;

  const StationDetailScreen({super.key, required this.station});

  // Mock data — replace with real station model
  static const List<Map<String, dynamic>> _materials = [
    {'label': 'Plastic', 'icon': Icons.recycling, 'active': true},
    {'label': 'Glass', 'icon': Icons.wine_bar_outlined, 'active': false},
    {'label': 'Paper', 'icon': Icons.description_outlined, 'active': true},
    {'label': 'E-Waste', 'icon': Icons.electrical_services_outlined, 'active': false},
  ];

  static const List<Map<String, dynamic>> _history = [
    {
      'name': 'Alex Rivera',
      'detail': '12.5kg Plastic • 2 mins ago',
      'points': '+450 pts',
      'initials': 'AR',
      'color': Color(0xFF4CAF50),
    },
    {
      'name': 'Sarah Chen',
      'detail': '8.2kg Paper • 1 hour ago',
      'points': '+210 pts',
      'initials': 'SC',
      'color': Color(0xFF2196F3),
    },
    {
      'name': 'Anonymous Hero',
      'detail': '4.0kg Glass • 3 hours ago',
      'points': '+120 pts',
      'initials': '?',
      'color': Color(0xFF9E9E9E),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────
          _TopBar(stationName: station.stationName ?? 'Station'),

          // ── Scrollable content ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Station header card
                  _StationHeaderCard(station: station),

                  // Map thumbnail
                  _MapThumbnail(
                    lat: station.latitude ?? 3.1390,
                    lng: station.longitude ?? 101.6869,
                  ),

                  const SizedBox(height: 16),

                  // Real-time capacity
                  _CapacityCard(capacity: 80, remainingKg: 240),

                  const SizedBox(height: 16),

                  // Supported materials
                  const _SectionLabel(label: 'SUPPORTED MATERIALS'),
                  const SizedBox(height: 8),
                  _MaterialsGrid(materials: _materials),

                  const SizedBox(height: 16),

                  // Historical activity
                  const _SectionLabel(label: 'HISTORICAL ACTIVITY'),
                  const SizedBox(height: 8),
                  _ActivityList(history: _history),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Floating scan CTA ──────────────────────────────────────────
      bottomNavigationBar: _ScanCTA(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrScanScreen()),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String stationName;
  const _TopBar({required this.stationName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1DB954),
                      shape: BoxShape.circle,
                    ),
                    child:
                    const Icon(Icons.eco, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'ECOLEDGER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D3B1F),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFEAF7EE),
                  child: const Icon(Icons.person,
                      color: Color(0xFF0D3B1F), size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationHeaderCard extends StatelessWidget {
  final RecycleStation station;
  const _StationHeaderCard({required this.station});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station ID + Active badge
          Row(
            children: [
              Text(
                'STATION ID: #0824-LX',
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    letterSpacing: 0.5),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ACTIVE NOW',
                  style: TextStyle(
                    color: Color(0xFF1DB954),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Station name
          Text(
            station.stationName ?? 'Station',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1F0D),
            ),
          ),
          const SizedBox(height: 4),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Color(0xFF666), size: 14),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  '124 High Street, Ecosystem District, Metropolis',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Navigate + Share buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.navigation,
                    size: 16, color: Colors.white),
                label: const Text('Navigate',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDDD)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Icon(Icons.share_outlined,
                    color: Color(0xFF555), size: 18),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Distance + CO2 stat tiles
          Row(
            children: [
              _StatTile(
                value: '0.8km',
                label: 'DISTANCE FROM YOU',
                icon: Icons.location_on,
                iconColor: const Color(0xFF1DB954),
                bgColor: const Color(0xFF1DB954),
              ),
              const SizedBox(width: 12),
              _StatTile(
                value: '1.2k',
                label: 'CO2 OFFSET (KG)',
                icon: Icons.bolt,
                iconColor: const Color(0xFF1DB954),
                bgColor: Colors.white,
                isBordered: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isBordered;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.isBordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isBordered ? Colors.white : const Color(0xFFEAF7EE),
          borderRadius: BorderRadius.circular(14),
          border: isBordered
              ? Border.all(color: const Color(0xFFDDEEDD), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D1F0D),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF888),
                  letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapThumbnail extends StatelessWidget {
  final double lat;
  final double lng;
  const _MapThumbnail({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFDDEEDD),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Placeholder for static map image / small GoogleMap widget
          Container(
            color: const Color(0xFFE8F5E9),
            child: const Center(
              child: Icon(Icons.map_outlined,
                  color: Color(0xFF1DB954), size: 48),
            ),
          ),
          // Pin
          const Center(
            child: Icon(Icons.location_on,
                color: Color(0xFF333), size: 48),
          ),
        ],
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  final int capacity; // 0–100
  final int remainingKg;
  const _CapacityCard({required this.capacity, required this.remainingKg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'REAL-TIME CAPACITY',
                  style: TextStyle(
                      color: Color(0xFF888),
                      fontSize: 11,
                      letterSpacing: 0.5),
                ),
                Text(
                  '$capacity%',
                  style: const TextStyle(
                    color: Color(0xFF1DB954),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: capacity / 100,
                minHeight: 10,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1DB954)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Estimated ${remainingKg}kg space remaining',
              style: const TextStyle(
                  color: Color(0xFF999), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF666),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MaterialsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> materials;
  const _MaterialsGrid({required this.materials});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        itemCount: materials.length,
        itemBuilder: (_, i) {
          final m = materials[i];
          final bool active = m['active'] as bool;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: active
                  ? Border.all(
                  color: const Color(0xFF1DB954), width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  m['icon'] as IconData,
                  color: active
                      ? const Color(0xFF1DB954)
                      : const Color(0xFFAAAAAA),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  m['label'] as String,
                  style: TextStyle(
                    color: active
                        ? const Color(0xFF0D1F0D)
                        : const Color(0xFFAAAAAA),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _ActivityList({required this.history});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: history.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                        (item['color'] as Color).withOpacity(0.15),
                        child: Text(
                          item['initials'] as String,
                          style: TextStyle(
                            color: item['color'] as Color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF0D1F0D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['detail'] as String,
                              style: const TextStyle(
                                  color: Color(0xFF999), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item['points'] as String,
                        style: const TextStyle(
                          color: Color(0xFF1DB954),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < history.length - 1)
                  const Divider(
                      height: 1, indent: 16, endIndent: 16,
                      color: Color(0xFFF0F0F0)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ScanCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1F0D),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.qr_code_scanner,
                  color: Color(0xFF1DB954), size: 20),
              SizedBox(width: 10),
              Text(
                'SCAN QR TO START',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}