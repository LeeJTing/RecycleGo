// lib/view/admin/station_registry_screen.dart
import 'package:flutter/material.dart';
import 'package:recycle_go/models/RecycleStations.dart';
import 'package:recycle_go/view/admin/admin_station_edit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

const _green     = Color(0xFF1DB954);
const _darkGreen = Color(0xFF0D3B1F);
const _bgGrey    = Color(0xFFF4F7F4);

enum _SortMode { capacity, name, status }

class StationRegistryScreen extends StatefulWidget {
  const StationRegistryScreen({super.key});

  @override
  State<StationRegistryScreen> createState() => _StationRegistryScreenState();
}

class _StationRegistryScreenState extends State<StationRegistryScreen> {
  List<RecycleStation> _stations = [];
  final _searchCtrl = TextEditingController();
  final _model = RecycleStationModel();
  Timer? _debounce;

  String _query = '';
  RecycleMaterialType? _filterMat;
  _SortMode _sort = _SortMode.capacity;
  int _page = 1;
  static const _pageSize = 12;

  // ── Derived lists ──────────────────────────────────────────────────
  List<RecycleStation> get _filtered {
    var list = _stations.where((s) {
      final q = _query.toLowerCase();
      final name = (s.stationName ?? '').toLowerCase();
      final id   = (s.stationId ?? '').toLowerCase();

      final matchQ = q.isEmpty ||
          name.contains(q) ||
          id.contains(q) ||
          name.replaceAll(' ', '').contains(q.replaceAll(' ', ''));
      final matchM = _filterMat == null ||
          s.supportedMaterials.contains(_filterMat);
      return matchQ && matchM;
    }).toList();

    switch (_sort) {
      case _SortMode.capacity:
        list.sort((a, b) => b.stationCapacity.compareTo(a.stationCapacity));
        break;
      case _SortMode.name:
        list.sort((a, b) => a.stationName.compareTo(b.stationName));
        break;
      case _SortMode.status:
        list.sort((a, b) => a.stationStatus.index.compareTo(b.stationStatus.index));
        break;
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
      await _model.insertStation(result);   // ✅ 存进 DB
      await _loadStations();
      _snack('Station ${result.stationId} added');
    }
  }

  Future<void> _onEdit(RecycleStation s) async {
    final result = await Navigator.push<RecycleStation>(
      context,
      MaterialPageRoute(builder: (_) => StationEditScreen(station: s)),
    );

    if (result != null) {
      await _model.updateStation(result);  // ✅ update DB
      await _loadStations();               // ✅ refresh
      _snack('Station ${result.stationId} updated');
    }
  }

  Future<void> _onDelete(RecycleStation s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(
        name: s.stationName ?? 'Unknown',
        id: s.stationId ?? 'N/A',
      ),
    );

    if (ok == true) {
      await _model.deleteStation(s.stationId ?? ''); // ✅ DB delete
      await _loadStations();                   // ✅ refresh
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

  Future<void> _loadStations() async {
    final data = await _model.getAllStations();

    setState(() {
      _stations = data;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadStations();

    _searchCtrl.addListener(() {
      setState(() {}); // 🔥 让 suffixIcon 动态出现
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = _stations.where((s) => s.stationStatus == StationStatus.active).length;
    final full = _stations.where((s) => s.stationStatus == StationStatus.maintenance).length;
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
                    onChanged: (v) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();

                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        setState(() {
                          _query = v;
                          _page = 1;
                        });
                      });
                    },
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
        Text('${activeCount.toString()} ACTIVE',
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

        decoration: InputDecoration( // ❌ remove const
          hintText: 'SEARCH BY STATION ID OR NAME...',
          hintStyle: const TextStyle(
              color: Color(0xFFBBBBBB), fontSize: 11, letterSpacing: 0.5),

          prefixIcon: const Icon(Icons.search,
              color: Color(0xFFBBBBBB), size: 18),

          // ✅ 加这个（关键）
          suffixIcon: ctrl.text.isNotEmpty
              ? GestureDetector(
            onTap: () {
              ctrl.clear();
              onChanged('');
            },
            child: const Icon(Icons.close, size: 16),
          )
              : null,

          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 13),
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
      'CARDBOARD': RecycleMaterialType.cardboard,
      'METAL': RecycleMaterialType.metal,
    };

    return Column(
      // 关键点 1：强制让 Column 的子组件全部靠左对齐，消除中间的大空位感
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // 移除 ScrollView 可能自带的 padding 干扰
          clipBehavior: Clip.none,
          child: Row(
            children: chips.entries.map((e) {
              final sel = selected == e.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onFilter(e.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? _darkGreen : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? _darkGreen : const Color(0xFFDDDDDD)),
                    ),
                    child: Text(e.key,
                        style: TextStyle(
                            color: sel ? Colors.white : Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // 关键点 2：控制两行之间的间距
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () {
            final next = _SortMode.values[(sort.index + 1) % _SortMode.values.length];
            onSort(next);
          },
          child: Container(
            // 关键点 3：这里可以稍微增加一点内边距，让它看起来更像一个功能按钮
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8), // 改成小圆角，区别于上方的筛选圆角
              border: Border.all(color: const Color(0xFFEEEEEE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_vert_rounded, size: 14, color: _green), // 换一个更有指向性的图标
                const SizedBox(width: 4),
                const Text(
                  'SORT BY:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  sort.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800, // 加粗排序后的文字
                    color: _darkGreen,
                    letterSpacing: 0.5,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 16, color: _darkGreen),
              ],
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: const [
          // 名称列标题 (占满剩余空间)
          Expanded(
            child: Text(
              'LOCATION NAME',
              style: TextStyle(
                color: Color(0xFF888),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // 材质列标题 (对应内容的 85px)
          SizedBox(
            width: 85,
            child: Text(
              'MATERIAL',
              style: TextStyle(
                color: Color(0xFF888),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // 按钮预留空间 (对应内容的 62px)
          SizedBox(width: 62),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final mats = station.supportedMaterials;
    final mixed = mats.length > 1;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            // 1. 状态圆点 + 地点名称 (占用绝大部分空间)
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: _dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      station.stationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _darkGreen,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 2. 材质标签 (固定宽度，确保对齐)
            SizedBox(
              width: 85,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _DotCircle(color: mixed ? const Color(0xFF90CAF9) : _matColor(mats.isNotEmpty ? mats.first : RecycleMaterialType.plastic)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      mixed ? 'MIXED' : (mats.isNotEmpty ? mats.first.label.toUpperCase() : 'N/A'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. 操作按钮 (固定宽度)
            SizedBox(
              width: 62,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Btn(icon: Icons.edit_outlined, color: _green, onTap: onEdit),
                  const SizedBox(width: 6),
                  _Btn(icon: Icons.delete_outline, color: const Color(0xFFE53935), onTap: onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
      if (!isLast)
        const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFF0F0F0)),
    ]);
  }

  Color get _dot {
    switch (station.stationStatus) {
      case StationStatus.active:      return _green;
      case StationStatus.maintenance: return const Color(0xFFF5A623);
      case StationStatus.offline:     return const Color(0xFFE53935);
    }
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
    // 基础范围计算
    final startItem = ((page - 1) * pageSize + 1).clamp(0, count);
    final endItem = (page * pageSize).clamp(0, count);

    // 动态生成页码列表 (例如展示当前页前后的页码)
    // 这里使用 Set 自动去重，并确保页码在 1 到 total 之间
    final pageSet = <int>{};

    // 始终显示第一页
    pageSet.add(1);

    // 显示当前页及其前后各一页
    for (var i = page - 1; i <= page + 1; i++) {
      if (i >= 1 && i <= total) pageSet.add(i);
    }

    // 始终显示最后一页
    pageSet.add(total);

    final sortedPages = pageSet.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Text(
          'SHOWING $startItem-$endItem OF $count',
          style: const TextStyle(
              color: Color(0xFF888),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3
          ),
        ),
        const Spacer(),
        // 上一页
        _PageBtn(
          label: '‹',
          active: false,
          enabled: page > 1,
          onTap: () => onTap(page - 1),
        ),

        // 循环渲染不重复的页码
        ...sortedPages.map((p) => _PageBtn(
          label: '$p',
          active: p == page,
          enabled: true,
          onTap: () => onTap(p),
        )),

        // 下一页
        _PageBtn(
          label: '›',
          active: false,
          enabled: page < total,
          onTap: () => onTap(page + 1),
        ),
      ]),
    );
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
      margin: const EdgeInsets.only(left: 6), // 稍微增加间距
      decoration: BoxDecoration(
        color: active ? _green : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          // 如果不可用，边框调淡一点点，但依然可见
            color: active ? _green : (enabled ? const Color(0xFFDDDDDD) : const Color(0xFFEEEEEE))),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
              color: active
                  ? Colors.white
                  : (enabled ? const Color(0xFF222222) : const Color(0xFFBBBBBB)), // 调深了颜色
              fontWeight: FontWeight.w800, // 强制加粗，让 ‹ › 更明显
              fontSize: label == '‹' || label == '›' ? 18 : 13), // 让箭头符号大一点
        ),
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
