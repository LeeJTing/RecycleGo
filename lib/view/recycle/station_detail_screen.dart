import 'package:flutter/material.dart';
import 'qr_scan_screen.dart';
import 'package:recycle_go/models/RecycleStations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StationDetailScreen extends StatefulWidget {
  final RecycleStation station;
  final double distanceKm;
  final String? duration;
  final String? routeDistance;

  const StationDetailScreen({
    super.key,
    required this.station,
    required this.distanceKm,
    this.duration,
    this.routeDistance,
  });

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  double maxCap = 1000.0;

  double co2Kg = 0.0;

  double totalKg = 0;

  bool isLoading = true;

  bool isFull = false;

  List<Map<String, dynamic>> materials = [];
  int capacity = 0;
  int remainingKg = 0;

  @override
  void initState() {
    super.initState();
    fetchStationData();
  }

  Future<void> fetchStationData() async {
    setState(() => isLoading = true);

    try {
      final data = await Supabase.instance.client
          .from('recyclestation')
          .select()
          .eq('station_id', widget.station.stationId!)
          .maybeSingle();

      if (data == null) {
        setState(() => isLoading = false);
        return;
      }

      final plasticRaw   = data['plastic_storage'];
      final paperRaw = data['paper_storage'];
      final glassRaw     = data['glasses_storage'];
      final cardboardRaw = data['cardboard_storage'];
      final metalRaw     = data['metal_storage'];

      final plastic   = (plasticRaw as num?)?.toDouble();
      final paper = (paperRaw as num?)?.toDouble();
      final glass     = (glassRaw as num?)?.toDouble();
      final cardboard = (cardboardRaw as num?)?.toDouble();
      final metal     = (metalRaw as num?)?.toDouble();

      final total =
          (plastic ?? 0) +
              (glass ?? 0) +
              (cardboard ?? 0) +
              (paper ?? 0) +
              (metal ?? 0);

      maxCap = (data['station_capacity'] as num?)?.toDouble() ?? 1000.0;

      final full = total >= maxCap;

      // The CO2 reduction coefficient of each material (kg CO2 / kg)
      const plasticFactor = 6.0;
      const glassFactor = 0.5;
      const cardboardFactor = 3.0;
      const metalFactor = 9.0;
      const paperFactor = 2.5;

      // Calculate CO2
      final co2 =
          ((plastic ?? 0) * plasticFactor) +
              ((glass ?? 0) * glassFactor) +
              ((cardboard ?? 0) * cardboardFactor) +
              ((metal ?? 0) * metalFactor) +
              ((paper ?? 0) * paperFactor);

      setState(() {
        materials = [
          {
            'label': 'Plastic',
            'icon': Icons.recycling,
            'level': plastic ?? 0,
            'hasMaterial': plasticRaw != null,
          },
          {
            'label': 'Paper',
            'icon': Icons.article_outlined, // 或 Icons.description
            'level': paper ?? 0,
            'hasMaterial': paperRaw != null,
          },
          {
            'label': 'Glass',
            'icon': Icons.wine_bar_outlined,
            'level': glass ?? 0,
            'hasMaterial': glassRaw != null,
          },
          {
            'label': 'Cardboard',
            'icon': Icons.description_outlined,
            'level': cardboard ?? 0,
            'hasMaterial': cardboardRaw != null,
          },
          {
            'label': 'Metal',
            'icon': Icons.settings,
            'level': metal ?? 0,
            'hasMaterial': metalRaw != null,
          },
        ];

        capacity = ((total / maxCap) * 100).clamp(0, 100).round();
        remainingKg = (maxCap - total).clamp(0, maxCap).toInt();
        isFull = full;
        co2Kg = co2;
        isLoading = false;
        totalKg = total;
      });

    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 30,
                            color: Color(0xFF0D1F0D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _StationHeaderCard(
                    station: widget.station,
                    distanceKm: widget.distanceKm,
                    co2Kg: co2Kg,
                    duration: widget.duration,
                    routeDistance: widget.routeDistance,
                  ),

                  _LivePreviewMap(
                    lat: widget.station.latitude ?? 3.1390,
                    lng: widget.station.longitude ?? 101.6869,
                  ),

                  const SizedBox(height: 16),

                  _CapacityCard(
                    capacity: capacity,
                    remainingKg: remainingKg,
                    usedKg: totalKg,
                    maxCapKg: maxCap,
                  ),

                  const SizedBox(height: 16),

                  const _SectionLabel(label: 'SUPPORTED MATERIALS'),
                  const SizedBox(height: 8),

                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _MaterialsGrid(
                    materials: materials,
                    totalKg: totalKg,
                    maxCap: maxCap,
                  ),

                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _ScanCTA(
        disabled: isFull,
        onTap: isFull
            ? null
            : () => Navigator.push(
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

class _StationHeaderCard extends StatelessWidget {
  final RecycleStation station;
  final double distanceKm;
  final double co2Kg;

  final String? duration;
  final String? routeDistance;

  const _StationHeaderCard({
    required this.station,
    required this.distanceKm,
    required this.co2Kg,
    this.duration,
    this.routeDistance,
  });

  @override
  Widget build(BuildContext context) {
    String displayDistance;

    if (routeDistance != null && routeDistance!.isNotEmpty) {
      displayDistance = routeDistance!;
    } else {
      displayDistance = '${distanceKm.toStringAsFixed(1)} km';
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          // Station ID + Active badge
          Row(
            children: [
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
              Expanded(
                child: Text(
                  station.address ?? 'No address',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (duration != null && displayDistance.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '$duration • $displayDistance',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Navigate + Share buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, station);
                },
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
                value: displayDistance,
                label: 'Distance',
                icon: Icons.location_on,
                iconColor: Colors.black,
                bgColor: const Color(0xFFF5F5F5),
                isBordered: true,
              ),
              const SizedBox(width: 12),
              _StatTile(
                value: co2Kg >= 1000
                    ? '${(co2Kg / 1000).toStringAsFixed(1)}k'
                    : co2Kg.toStringAsFixed(0),
                label: 'CO₂ Saved',
                icon: Icons.bolt,
                iconColor: Colors.black,
                bgColor: const Color(0xFFF5F5F5),
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
    final bool isDarkBg = !isBordered;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: isBordered
              ? Border.all(color: const Color(0xFFDDEEDD), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 icon + label
            Row(
              children: [
                Icon(
                  icon,
                  color: isDarkBg ? Colors.white : iconColor,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkBg
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 🔹 value
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDarkBg
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Live preview map placeholder ──────────────────────────────────────
// Replace inner Container with a real GoogleMap widget once wired up
class _LivePreviewMap extends StatelessWidget {
  final double lat, lng;
  const _LivePreviewMap({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullMapScreen(lat: lat, lng: lng),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox(
              height: 180,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId("preview"),
                    position: LatLng(lat, lng),
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                liteModeEnabled: true,
              ),
            ),

            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIVE PREVIEW',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullMapScreen extends StatelessWidget {
  final double lat;
  final double lng;

  const FullMapScreen({
    super.key,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location"),
        backgroundColor: const Color(0xFF1DB954),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, lng),
          zoom: 17,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("full_map"),
            position: LatLng(lat, lng),
          ),
        },
        myLocationEnabled: true,
        zoomControlsEnabled: true,
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  final int capacity; // 0–100
  final int remainingKg;
  final double maxCapKg;
  final double usedKg;

  const _CapacityCard({
    required this.capacity,
    required this.remainingKg,
    required this.usedKg,
    this.maxCapKg = 1000,
  });

  Color _color(int pct) {
    if (pct >= 100) return Colors.red;
    if (pct >= 80)  return Colors.orange;
    return const Color(0xFF1DB954);
  }

  @override
  Widget build(BuildContext context) {
    final color   = _color(capacity);

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
            // ── row 1: label + percent ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'REAL-TIME CAPACITY',
                  style: TextStyle(
                    color: Color(0xFF888),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '$capacity%',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            // ── row 2: total capacity tag ─────────────────────────
            const SizedBox(height: 4),
            Text(
              'Total capacity: ${maxCapKg.toStringAsFixed(0)} kg',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            // ── progress bar ──────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: capacity / 100,
                minHeight: 10,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),

            const SizedBox(height: 8),

            // ── row 3: used / remaining ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Used: ${usedKg.toStringAsFixed(0)} kg',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Remaining: ${remainingKg} kg',
                  style: const TextStyle(
                    color: Color(0xFF888),
                    fontSize: 12,
                  ),
                ),
              ],
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
          color: Color(0xFF0D1F0D),
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MaterialsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> materials;
  final double totalKg;
  final double maxCap;

  const _MaterialsGrid({
    required this.materials,
    required this.totalKg,
    required this.maxCap,
  });

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
          childAspectRatio: 1.45,
        ),
        itemCount: materials.length,
        itemBuilder: (_, i) {
          final m = materials[i];

          final bool hasMaterial = m['hasMaterial'] == true;
          final dynamic rawLevel = m['level'];
          final double level = (rawLevel as num? ?? 0).toDouble();

          // ✅ 重点：算 percent
          final percent = (level / maxCap).clamp(0.0, 1.0);
          final bool isFull = level >= maxCap;
          final int pctInt = (percent * 100).round();

          Color color;

          if (!hasMaterial) {
            color = Colors.grey;
          } else if (isFull) {
            color = Colors.red;
          } else if (percent >= 0.9) {
            color = Colors.orange;
          } else if (percent >= 0.6) {
            color = Colors.yellow.shade700;
          } else {
            color = const Color(0xFF1DB954);
          }

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.35), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // ── Row: icon + label  |  percent badge ──────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(m['icon'] as IconData, color: color, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          m['label'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: hasMaterial ? color : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    // ── percent badge (右上角) ──────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hasMaterial ? '$pctInt%' : '--',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // ── kg text ──────────────────────────────────────
                Text(
                  !hasMaterial
                      ? 'Not Available'
                      : isFull
                      ? 'FULL'
                      : level == 0
                      ? 'Empty'
                      : '${level.toStringAsFixed(0)} kg (${pctInt}%)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isFull ? Colors.red : const Color(0xFF888),
                    fontWeight:
                    isFull ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),

                const SizedBox(height: 6),

                // ── animated progress bar ─────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(percent),
                    tween: Tween(begin: 0, end: percent),
                    duration: const Duration(milliseconds: 800),
                    builder: (_, value, __) => LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),

                // ── FULL badge (only when full) ───────────────────
                if (isFull) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FULL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
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
  final VoidCallback? onTap;
  final bool disabled;

  const _ScanCTA({
    this.onTap,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: disabled
                  ? Colors.grey
                  : const Color(0xFF0D1F0D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner,
                    color: Color(0xFF1DB954), size: 20),
                const SizedBox(width: 10),
                Text(
                  disabled ? 'STATION FULL' : 'SCAN QR TO START',
                  style: const TextStyle(
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
      )
    );
  }
}
