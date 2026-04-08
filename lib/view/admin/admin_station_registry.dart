// lib/view/admin/station_registry_screen.dart
import 'package:flutter/material.dart';
import 'package:recycle_go/models/RecycleStations.dart';
import 'package:recycle_go/view/admin/admin_station_edit.dart';

const _green     = Color(0xFF1DB954);
const _darkGreen = Color(0xFF0D3B1F);
const _bgGrey    = Color(0xFFF4F7F4);

// ── Mock data (swap with Firestore/API) ──────────────────────────────
final _mockStations = <RecycleStation>[
  RecycleStation(
    stationId: 'ST-9902', stationName: 'Greenway Plaza North',
    address: 'Main Entrance, Sector 4', latitude: 3.1390, longitude: 101.6869,
    stationStatus: StationStatus.active,
    plasticStorage: 500, paperStorage: 300, glassStorage: 200,
    cardboardStorage: 0, metalStorage: 0,
    qrCodeValue: 'ECO-ST-9902', createdAt: DateTime(2024, 1, 10),
  ),
  RecycleStation(
    stationId: 'ST-8841', stationName: 'Harbor Terminal C',
    address: 'Docking Bay 12', latitude: 3.1420, longitude: 101.6830,
    stationStatus: StationStatus.active,
    plasticStorage: 0, paperStorage: 800, glassStorage: 0,
    cardboardStorage: 200, metalStorage: 0,
    qrCodeValue: 'ECO-ST-8841', createdAt: DateTime(2024, 2, 5),
  ),
  RecycleStation(
    stationId: 'ST-1102', stationName: 'Tech District Hub',
    address: 'Main Atrium', latitude: 3.1450, longitude: 101.6900,
    stationStatus: StationStatus.maintenance,
    plasticStorage: 600, paperStorage: 0, glassStorage: 0,
    cardboardStorage: 0, metalStorage: 400,
    qrCodeValue: 'ECO-ST-1102', createdAt: DateTime(2024, 3, 1),
  ),
  RecycleStation(
    stationId: 'ST-0034', stationName: 'Central Park Depot',
    address: 'East Gate, Park Ave', latitude: 3.1300, longitude: 101.6750,
    stationStatus: StationStatus.offline,
    plasticStorage: 400, paperStorage: 400, glassStorage: 400,
    cardboardStorage: 400, metalStorage: 400,
    qrCodeValue: 'ECO-ST-0034', createdAt: DateTime(2024, 3, 15),
  ),
];

// ─────────────────────────────────────────────────────────────────────

enum _SortMode { capacity, name, status }

class StationRegistryScreen extends StatefulWidget {
  const StationRegistryScreen({super.key});

  @override
  State<StationRegistryScreen> createState() => _StationRegistryScreenState();
}

class _StationRegistryScreenState extends State<StationRegistryScreen> {
  final List<RecycleStation> _stations = List.from(_mockStations);
  final _searchCtrl = TextEditingController();

  String _query = '';
  RecycleMaterialType? _filterMat;
  _SortMode _sort = _SortMode.capacity;
  int _page = 1;
  static const _pageSize = 12;

  // ── Derived lists ──────────────────────────────────────────────────
  List<RecycleStation> get _filtered {
    var list = _stations.where((s) {
      final q = _query.toLowerCase();
      final matchQ = q.isEmpty ||
          s.stationName.toLowerCase().contains(q) ||
          s.stationId.toLowerCase().contains(q);
      final matchM = _filterMat == null ||
          s.supportedMaterials.contains(_filterMat);
      return matchQ && matchM;
    }).toList();

    switch (_sort) {
      case _SortMode.capacity:
        list.sort((a, b) => b.totalCapacity.compareTo(a.totalCapacity));
      case _SortMode.name:
        list.sort((a, b) => a.stationName.compareTo(b.stationName));
      case _SortMode.status:
        list.sort((a, b) => a.stationStatus.index.compareTo(b.stationStatus.index));
    }
    return list;
  }

  List<RecycleStation> get _page_items {
    final start = (_page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    return _filtered.sublist(start.clamp(0, _filtered.length), end);
  }

  int get _totalPages =>
      (_filtered.length / _pageSize).ceil().clamp(1, 999);

  // ── CRUD ───────────────────────────────────────────────────────────
  Future<void> _onAdd() async {
    final result = await Navigator.push<RecycleStation>(
      context,
      MaterialPageRoute(builder: (_) => const StationEditScreen()),
    );
    if (result != null) {
      setState(() => _stations.add(result));
      _snack('Station ${result.stationId} added');
    }
  }

  Future<void> _onEdit(RecycleStation s) async {
    final result = await Navigator.push<RecycleStation>(
      context,
      MaterialPageRoute(builder: (_) => StationEditScreen(station: s)),
    );
    if (result != null) {
      setState(() {
        final i = _stations.indexWhere((x) => x.stationId == result.stationId);
        if (i != -1) _stations[i] = result;
      });
      _snack('Station ${result.stationId} updated');
    }
  }

  Future<void> _onDelete(RecycleStation s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(name: s.stationName, id: s.stationId),
    );
    if (ok == true) {
      setState(() => _stations.removeWhere((x) => x.stationId == s.stationId));
      _snack('Station ${s.stationId} deleted');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _darkGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _stations.where((s) => s.stationStatus == StationStatus.active).length;
    final full   = _stations.where((s) => s.stationStatus == StationStatus.maintenance).length;
    final offline= _stations.where((s) => s.stationStatus == StationStatus.offline).length;

    return Scaffold(
      backgroundColor: _bgGrey,
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        backgroundColor: _green,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: _BottomNav(selected: 1),
      body: SafeArea(
        child: Column(children: [
          _TopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Network status ─────────────────────────────
                  _NetworkCard(activeCount: active),
                  const SizedBox(height: 12),

                  // ── Alert: Full ────────────────────────────────
                  if (full > 0) ...[
                    _AlertCard(
                      accent: const Color(0xFFF5A623),
                      label: 'ALERTS',
                      count: full,
                      status: 'FULL',
                      sub: 'IMMEDIATE PICKUP REQUIRED',
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ── Alert: Offline ─────────────────────────────
                  if (offline > 0) ...[
                    _AlertCard(
                      accent: const Color(0xFFE53935),
                      label: 'MAINTENANCE',
                      count: offline,
                      status: 'OFFLINE',
                      sub: 'TECHNICIAN DISPATCHED',
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── Search ─────────────────────────────────────
                  _SearchBar(
                    ctrl: _searchCtrl,
                    onChanged: (v) => setState(() { _query = v; _page = 1; }),
                  ),
                  const SizedBox(height: 10),

                  // ── Filter chips + sort ────────────────────────
                  _FilterRow(
                    selected: _filterMat,
                    sort: _sort,
                    onFilter: (m) => setState(() { _filterMat = m; _page = 1; }),
                    onSort: (s) => setState(() => _sort = s),
                  ),
                  const SizedBox(height: 18),

                  // ── Table header ───────────────────────────────
                  const _TableHeader(),
                  const SizedBox(height: 8),

                  // ── Rows ───────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _page_items.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No stations found',
                            style: TextStyle(color: Color(0xFF888))),
                      ),
                    )
                        : Column(
                      children: _page_items.asMap().entries.map((e) {
                        final last = e.key == _page_items.length - 1;
                        return _StationRow(
                          station: e.value,
                          isLast: last,
                          onEdit: () => _onEdit(e.value),
                          onDelete: () => _onDelete(e.value),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Pagination ─────────────────────────────────
                  _Pagination(
                    page: _page,
                    total: _totalPages,
                    count: _filtered.length,
                    pageSize: _pageSize,
                    onTap: (p) => setState(() => _page = p),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
          child: const Icon(Icons.eco, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 8),
        const Text('STATION REGISTRY',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14,
                letterSpacing: 1.2, color: _darkGreen)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('AU',
              style: TextStyle(
                  color: _green, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ]),
    );
  }
}

class _NetworkCard extends StatelessWidget {
  final int activeCount;
  const _NetworkCard({required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _green, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('NETWORK STATUS',
            style: TextStyle(
                color: Colors.white70, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text('${activeCount.toString().padLeft(3, '0')} ACTIVE',
            style: const TextStyle(
                color: Colors.white, fontSize: 36,
                fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 4),
        const Text('Global recycling points verified this hour.',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
      ]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Color accent;
  final String label, status, sub;
  final int count;
  const _AlertCard({
    required this.accent, required this.label,
    required this.count, required this.status, required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: accent, fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(
          '${count.toString().padLeft(2, '0')} $status',
          style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900, color: _darkGreen),
        ),
        Text(sub,
            style: const TextStyle(
                color: Color(0xFF888), fontSize: 11, letterSpacing: 0.5)),
      ]),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'SEARCH BY STATION ID OR NAME...',
          hintStyle: TextStyle(
              color: Color(0xFFBBBBBB), fontSize: 11, letterSpacing: 0.5),
          prefixIcon: Icon(Icons.search, color: Color(0xFFBBBBBB), size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final RecycleMaterialType? selected;
  final _SortMode sort;
  final ValueChanged<RecycleMaterialType?> onFilter;
  final ValueChanged<_SortMode> onSort;
  const _FilterRow({
    required this.selected, required this.sort,
    required this.onFilter, required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <String, RecycleMaterialType?>{
      'ALL MATERIALS': null,
      'PLASTICS': RecycleMaterialType.plastic,
      'PAPER': RecycleMaterialType.paper,
      'GLASS': RecycleMaterialType.glass,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chips.entries.map((e) {
              final sel = selected == e.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onFilter(e.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? _darkGreen : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? _darkGreen : const Color(0xFFDDDDDD)),
                    ),
                    child: Text(e.key,
                        style: TextStyle(
                            color: sel ? Colors.white : const Color(0xFF555),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            final next = _SortMode.values[
            (sort.index + 1) % _SortMode.values.length];
            onSort(next);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDDDDDD)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.sort, size: 14, color: Color(0xFF555)),
              const SizedBox(width: 6),
              Text('SORT: ${sort.name.toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: Color(0xFF555))),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        SizedBox(
          width: 72,
          child: Text('STATION\nID',
              style: TextStyle(
                  color: Color(0xFF888), fontSize: 10,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
        Expanded(
          child: Text('LOCATION\nNAME',
              style: TextStyle(
                  color: Color(0xFF888), fontSize: 10,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
        SizedBox(
          width: 95,
          child: Text('MATERIAL\nTYPE',
              style: TextStyle(
                  color: Color(0xFF888), fontSize: 10,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
        SizedBox(width: 56),
      ]),
    );
  }
}

class _StationRow extends StatelessWidget {
  final RecycleStation station;
  final bool isLast;
  final VoidCallback onEdit, onDelete;
  const _StationRow({
    required this.station, required this.isLast,
    required this.onEdit, required this.onDelete,
  });

  Color get _dot {
    switch (station.stationStatus) {
      case StationStatus.active:      return _green;
      case StationStatus.maintenance: return const Color(0xFFF5A623);
      case StationStatus.offline:     return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mats = station.supportedMaterials;
    final mixed = mats.length > 1;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID badge
            SizedBox(
              width: 72,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('#${station.stationId}',
                    style: const TextStyle(
                        color: _darkGreen, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            // Name + address
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                            color: _dot, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(station.stationName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14,
                              color: _darkGreen)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text(station.address,
                      style: const TextStyle(
                          color: Color(0xFF888), fontSize: 11)),
                ],
              ),
            ),
            // Material dots + label
            SizedBox(
              width: 95,
              child: Row(children: [
                if (mixed) ...[
                  _DotCircle(color: const Color(0xFF90CAF9)),
                  const SizedBox(width: 3),
                  _DotCircle(color: const Color(0xFFA5D6A7)),
                  const SizedBox(width: 6),
                  const Text('MIXED',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: Color(0xFF555))),
                ] else if (mats.isNotEmpty) ...[
                  _DotCircle(color: _matColor(mats.first)),
                  const SizedBox(width: 6),
                  Text(mats.first.label,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: Color(0xFF555))),
                ],
              ]),
            ),
            // Action buttons
            SizedBox(
              width: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Btn(icon: Icons.edit_outlined, color: _green, onTap: onEdit),
                  const SizedBox(width: 6),
                  _Btn(
                      icon: Icons.delete_outline,
                      color: const Color(0xFFE53935),
                      onTap: onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
      if (!isLast)
        const Divider(height: 1, indent: 12, endIndent: 12,
            color: Color(0xFFF0F0F0)),
    ]);
  }

  Color _matColor(RecycleMaterialType m) {
    switch (m) {
      case RecycleMaterialType.plastic:   return const Color(0xFF42A5F5);
      case RecycleMaterialType.paper:     return const Color(0xFFF5A623);
      case RecycleMaterialType.glass:     return const Color(0xFF66BB6A);
      case RecycleMaterialType.cardboard: return const Color(0xFFBCAAA4);
      case RecycleMaterialType.metal:     return const Color(0xFF78909C);
    }
  }
}

class _DotCircle extends StatelessWidget {
  final Color color;
  const _DotCircle({required this.color});

  @override
  Widget build(BuildContext context) => Container(
      width: 9, height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: color, size: 15),
    ),
  );
}

class _Pagination extends StatelessWidget {
  final int page, total, count, pageSize;
  final ValueChanged<int> onTap;
  const _Pagination({
    required this.page, required this.total,
    required this.count, required this.pageSize, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final start = ((page - 1) * pageSize + 1).clamp(1, count);
    final end = (page * pageSize).clamp(1, count);
    final pages = List.generate(
        total.clamp(1, 5), (i) => (page - 2 + i + 1).clamp(1, total));

    return Row(children: [
      Text('SHOWING $start-$end OF $count STATIONS',
          style: const TextStyle(
              color: Color(0xFF888), fontSize: 10,
              fontWeight: FontWeight.w500, letterSpacing: 0.3)),
      const Spacer(),
      // prev
      _PageBtn(
          label: '‹',
          active: false,
          enabled: page > 1,
          onTap: () => onTap(page - 1)),
      ...pages.map((p) => _PageBtn(
        label: '$p',
        active: p == page,
        enabled: true,
        onTap: () => onTap(p),
      )),
      // next
      _PageBtn(
          label: '›',
          active: false,
          enabled: page < total,
          onTap: () => onTap(page + 1)),
    ]);
  }
}

class _PageBtn extends StatelessWidget {
  final String label;
  final bool active, enabled;
  final VoidCallback onTap;
  const _PageBtn({
    required this.label, required this.active,
    required this.enabled, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 32, height: 32,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: active ? _green : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: active ? _green : const Color(0xFFDDDDDD)),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                color: active
                    ? Colors.white
                    : enabled
                    ? const Color(0xFF333)
                    : const Color(0xFFCCC),
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    ),
  );
}

// ── Confirm delete dialog ─────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  final String name, id;
  const _DeleteDialog({required this.name, required this.id});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.warning_amber_rounded,
            color: Color(0xFFE53935), size: 22),
        SizedBox(width: 8),
        Text('Delete Station',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ]),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF555), fontSize: 14),
          children: [
            const TextSpan(text: 'Are you sure you want to delete\n'),
            TextSpan(
                text: name,
                style: const TextStyle(fontWeight: FontWeight.w700,
                    color: _darkGreen)),
            TextSpan(text: '  (#$id)?'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: Color(0xFF555))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Delete',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ── Admin bottom nav ──────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  const _BottomNav({required this.selected});

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem(icon: Icons.home_outlined, label: 'HOME'),
      _NavItem(icon: Icons.list_alt_outlined, label: 'REGISTRY'),
      _NavItem(icon: Icons.map_outlined, label: 'MAP'),
      _NavItem(icon: Icons.history_outlined, label: 'LOGS'),
    ];
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 4, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((e) {
          final active = e.key == selected;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(e.value.icon,
                color: active ? _green : const Color(0xFFAAAAAA), size: 22),
            const SizedBox(height: 2),
            Text(e.value.label,
                style: TextStyle(
                    color: active ? _green : const Color(0xFFAAAAAA),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
          ]);
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}