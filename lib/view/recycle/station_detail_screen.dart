import 'package:flutter/material.dart';
import 'qr_scan_screen.dart';
import 'package:recycle_go/models/RecycleStations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class StationDetailScreen extends StatefulWidget {
  final RecycleStation station;
  final double distanceKm;
  final String? duration;
  final String? routeDistance;

  const StationDetailScreen({
    super.key,
    required this.station,
    required this.distanceKm,

    // ✅ constructor 也要加
    this.duration,
    this.routeDistance,
  });

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {

  double co2Kg = 0.0;

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
          .eq('station_id', widget.station.stationId)
          .maybeSingle();

      if (data == null) {
        setState(() => isLoading = false);
        return;
      }

      final plastic   = (data['plastic_storage']   as num? ?? 0).toDouble();
      final glass     = (data['glasses_storage']   as num? ?? 0).toDouble();
      final cardboard = (data['cardboard_storage'] as num? ?? 0).toDouble();
      final metal     = (data['metal_storage']     as num? ?? 0).toDouble();

      final total = plastic + glass + cardboard + metal;

      const double maxCap = 500.0;

      final full = total >= maxCap;

      // ♻️ 每种材料的 CO2 减排系数（kg CO2 / kg）
      const plasticFactor = 6.0;
      const glassFactor = 0.5;
      const cardboardFactor = 3.0;
      const metalFactor = 9.0;

      // ✅ 计算 CO2
      final co2 =
          (plastic * plasticFactor) +
              (glass * glassFactor) +
              (cardboard * cardboardFactor) +
              (metal * metalFactor);

      // ✅ 一次 setState
      setState(() {
        materials = [
          {
            'label': 'Plastic',
            'icon': Icons.recycling,
            'level': plastic,
            'percent': maxCap > 0 ? plastic / maxCap : 0
          },
          {
            'label': 'Glass',
            'icon': Icons.wine_bar_outlined,
            'level': glass,
            'percent': maxCap > 0 ? glass / maxCap : 0
          },
          {
            'label': 'Cardboard',
            'icon': Icons.description_outlined,
            'level': cardboard,
            'percent': maxCap > 0 ? cardboard / maxCap : 0
          },
          {
            'label': 'Metal',
            'icon': Icons.settings,
            'level': metal,
            'percent': maxCap > 0 ? metal / maxCap : 0
          },
        ];

        capacity = ((total / maxCap) * 100).clamp(0, 100).toInt();
        remainingKg = (maxCap - total).clamp(0, maxCap).toInt();
        isFull = full;
        co2Kg = co2;
        isLoading = false;
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
          _TopBar(stationName: widget.station.stationName ?? 'Station'),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _StationHeaderCard(
                    station: widget.station,
                    distanceKm: widget.distanceKm,
                    co2Kg: co2Kg,
                    duration: widget.duration,
                    routeDistance: widget.routeDistance,
                  ),

                  _MapThumbnail(
                    lat: widget.station.latitude ?? 3.1390,
                    lng: widget.station.longitude ?? 101.6869,
                  ),

                  const SizedBox(height: 16),

                  // ✅ 用 DB
                  _CapacityCard(
                    capacity: capacity,
                    remainingKg: remainingKg,
                  ),

                  const SizedBox(height: 16),

                  const _SectionLabel(label: 'SUPPORTED MATERIALS'),
                  const SizedBox(height: 8),

                  // ✅ 用 DB
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _MaterialsGrid(materials: materials),

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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          if (duration != null && routeDistance != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '$duration • $routeDistance',
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
                  Navigator.pop(context, station); // 👈 把站点传回去
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
                value: '${distanceKm.toStringAsFixed(1)} km',
                label: 'DISTANCE FROM YOU',
                icon: Icons.location_on,
                iconColor: const Color(0xFF1DB954),
                bgColor: const Color(0xFF1DB954),
              ),
              const SizedBox(width: 12),
              _StatTile(
                value: co2Kg >= 1000
                    ? '${(co2Kg / 1000).toStringAsFixed(1)}k'
                    : co2Kg.toStringAsFixed(0),
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

  Color getCapacityColor(int capacity) {
    if (capacity >= 100) return Colors.red;
    if (capacity >= 90) return Colors.orange;
    return const Color(0xFF1DB954);
  }

  @override
  Widget build(BuildContext context) {
    final color = getCapacityColor(capacity);
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
                  style: TextStyle(
                    color: color,
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
                valueColor: AlwaysStoppedAnimation<Color>(color),
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
          childAspectRatio: 1.8,
        ),
        itemCount: materials.length,
          itemBuilder: (_, i) {
            final m = materials[i];
            final double percent = (m['percent'] as double? ?? 0);
            final double level = (m['level'] as double? ?? 0);

            const double maxCap = 500.0;

            Color color;

            final bool isFull = percent >= 1;

            if (isFull) {
              color = Colors.red;
            } else if (percent > 0.8) {
              color = Colors.orange;
            } else {
              color = const Color(0xFF1DB954);
            }

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // 🔹 Icon + Label
                  Row(
                    children: [
                      Icon(m['icon'], color: color, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        m['label'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                    ],
                  ),

// 👇👇👇 就加在这里 👇👇👇
                  if (isFull)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FULL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // 🔹 kg 数字
                  Text(
                    isFull
                        ? 'FULL'
                        : '${level.toStringAsFixed(0)} / ${maxCap.toStringAsFixed(0)} kg',
                    style: TextStyle(
                      fontSize: 12,
                      color: isFull ? Colors.red : const Color(0xFF666),
                      fontWeight: isFull ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 🔹 进度条
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(percent),
                      tween: Tween(begin: 0, end: percent.clamp(0, 1)),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEEEEEE),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
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
                  ? Colors.grey   // 👈 灰掉
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
                  disabled ? 'STATION FULL' : 'SCAN QR TO START', // 👈 关键
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