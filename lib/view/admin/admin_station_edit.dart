// lib/view/admin/station_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recycle_go/models/RecycleStations.dart';

const _green     = Color(0xFF1DB954);
const _darkGreen = Color(0xFF0D3B1F);
const _bgGrey    = Color(0xFFF4F7F4);
const _inputFill = Color(0xFFF0F4F0);

class StationEditScreen extends StatefulWidget {
  final RecycleStation? station; // null = Add mode

  const StationEditScreen({super.key, this.station});

  @override
  State<StationEditScreen> createState() => _StationEditScreenState();
}

class _StationEditScreenState extends State<StationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEdit => widget.station != null;

  // ── Form controllers ───────────────────────────────────────────────
  late final _nameCtrl    = TextEditingController(text: widget.station?.stationName ?? '');
  late final _addressCtrl = TextEditingController(text: widget.station?.address ?? '');
  late final _latCtrl     = TextEditingController(
      text: widget.station != null ? widget.station!.latitude.toString() : '');
  late final _lngCtrl     = TextEditingController(
      text: widget.station != null ? widget.station!.longitude.toString() : '');
  late final _descCtrl    = TextEditingController(text: widget.station?.description ?? '');

  // ── Material storage controllers (kg) ──────────────────────────────
  late final _plasticCtrl  = TextEditingController(
      text: widget.station?.plasticStorage.toStringAsFixed(0) ?? '0');
  late final _paperCtrl    = TextEditingController(
      text: widget.station?.paperStorage.toStringAsFixed(0) ?? '0');
  late final _glassCtrl    = TextEditingController(
      text: widget.station?.glassStorage.toStringAsFixed(0) ?? '0');
  late final _cardboardCtrl= TextEditingController(
      text: widget.station?.cardboardStorage.toStringAsFixed(0) ?? '0');
  late final _metalCtrl    = TextEditingController(
      text: widget.station?.metalStorage.toStringAsFixed(0) ?? '0');

  // ── Status ─────────────────────────────────────────────────────────
  StationStatus _status = StationStatus.active;

  // ── Capacity slider (total kg, 1k–50k) ────────────────────────────
  double _capacitySlider = 12500;

  // ── Selected material toggles ──────────────────────────────────────
  final Set<RecycleMaterialType> _selectedMats = {};

  @override
  void initState() {
    super.initState();
    if (widget.station != null) {
      _status = widget.station!.stationStatus;
      _capacitySlider = widget.station!.totalCapacity.clamp(1000, 50000);
      _selectedMats.addAll(widget.station!.supportedMaterials);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _addressCtrl, _latCtrl, _lngCtrl, _descCtrl,
      _plasticCtrl, _paperCtrl, _glassCtrl, _cardboardCtrl, _metalCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final result = RecycleStation(
      stationId:       _isEdit
          ? widget.station!.stationId
          : 'ST-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}',
      stationName:     _nameCtrl.text.trim(),
      address:         _addressCtrl.text.trim(),
      latitude:        double.tryParse(_latCtrl.text) ?? 0,
      longitude:       double.tryParse(_lngCtrl.text) ?? 0,
      description:     _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      stationStatus:   _status,
      plasticStorage:  _selectedMats.contains(RecycleMaterialType.plastic)
          ? (double.tryParse(_plasticCtrl.text) ?? 0) : 0,
      paperStorage:    _selectedMats.contains(RecycleMaterialType.paper)
          ? (double.tryParse(_paperCtrl.text) ?? 0) : 0,
      glassStorage:    _selectedMats.contains(RecycleMaterialType.glass)
          ? (double.tryParse(_glassCtrl.text) ?? 0) : 0,
      cardboardStorage:_selectedMats.contains(RecycleMaterialType.cardboard)
          ? (double.tryParse(_cardboardCtrl.text) ?? 0) : 0,
      metalStorage:    _selectedMats.contains(RecycleMaterialType.metal)
          ? (double.tryParse(_metalCtrl.text) ?? 0) : 0,
      qrCodeValue:     _isEdit
          ? widget.station!.qrCodeValue
          : 'ECO-ST-${DateTime.now().millisecondsSinceEpoch}',
      createdAt:       _isEdit ? widget.station!.createdAt : DateTime.now(),
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      bottomNavigationBar: _BottomNav(selected: 1),
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ────────────────────────────────────────────────
          _TopBar(isEdit: _isEdit),
          // ── Scrollable form ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb + title
                    _Breadcrumb(isEdit: _isEdit,
                        stationId: widget.station?.stationId),
                    const SizedBox(height: 20),

                    // Save / Cancel buttons (top)
                    Row(children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 13),
                        ),
                        child: const Text('CANCEL',
                            style: TextStyle(
                                color: Color(0xFF555), fontSize: 12,
                                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text('SAVE STATION',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12,
                                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Section: Core Identification ─────────────────
                    _SectionCard(
                      icon: Icons.info_outline,
                      title: 'CORE IDENTIFICATION',
                      child: Column(children: [
                        _FormField(
                            label: 'STATION NAME',
                            ctrl: _nameCtrl,
                            hint: 'e.g. Evergreen Hub - Central',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Station name is required' : null),
                        const SizedBox(height: 14),
                        _FormField(
                            label: 'STREET ADDRESS',
                            ctrl: _addressCtrl,
                            hint: '482 Chlorophyll Way, Tech Dist',
                            prefixIcon: Icons.location_on_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Address is required' : null),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: _FormField(
                              label: 'LATITUDE',
                              ctrl: _latCtrl,
                              hint: '3.1390',
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                              suffix: '° N',
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final d = double.tryParse(v);
                                if (d == null) return 'Invalid';
                                if (d < -90 || d > 90) return 'Range: -90~90';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FormField(
                              label: 'LONGITUDE',
                              ctrl: _lngCtrl,
                              hint: '101.6869',
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                              suffix: '° E',
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final d = double.tryParse(v);
                                if (d == null) return 'Invalid';
                                if (d < -180 || d > 180) return 'Range: -180~180';
                                return null;
                              },
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        _FormField(
                            label: 'DESCRIPTION (optional)',
                            ctrl: _descCtrl,
                            hint: 'Brief note about this station...',
                            maxLines: 2),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── Section: Supported Materials ─────────────────
                    _SectionCard(
                      icon: Icons.category_outlined,
                      title: 'SUPPORTED MATERIALS',
                      child: Column(children: [
                        // 2×2 material toggle grid
                        _MaterialGrid(
                          selected: _selectedMats,
                          onToggle: (m) => setState(() {
                            if (_selectedMats.contains(m)) {
                              _selectedMats.remove(m);
                            } else {
                              _selectedMats.add(m);
                            }
                          }),
                        ),
                        // Per-material storage kg (only shown if selected)
                        if (_selectedMats.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 12),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('STORAGE CAPACITY (KG)',
                                style: TextStyle(
                                    color: Color(0xFF888), fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5)),
                          ),
                          const SizedBox(height: 10),
                          ..._selectedMats.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FormField(
                              label: m.label,
                              ctrl: _ctrlFor(m),
                              hint: '0',
                              keyboardType: TextInputType.number,
                              suffix: 'kg',
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          )),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── Section: Capacity Slider ──────────────────────
                    _SectionCard(
                      icon: null,
                      title: '',
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INITIAL CAPACITY',
                              style: TextStyle(
                                  color: Color(0xFF888), fontSize: 10,
                                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: '${(_capacitySlider / 1000).toStringAsFixed(0)},${(_capacitySlider % 1000).toStringAsFixed(0).padLeft(3, '0')} ',
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.w900,
                                    color: _darkGreen),
                              ),
                              const TextSpan(
                                text: 'KG',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600,
                                    color: Color(0xFF888)),
                              ),
                            ]),
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: _green,
                              inactiveTrackColor: const Color(0xFFDDDDDD),
                              thumbColor: _green,
                              overlayColor: _green.withOpacity(0.1),
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 10),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              min: 1000,
                              max: 50000,
                              divisions: 98,
                              value: _capacitySlider,
                              onChanged: (v) =>
                                  setState(() => _capacitySlider = v),
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1K', style: TextStyle(
                                  color: Color(0xFF888), fontSize: 11)),
                              Text('50K', style: TextStyle(
                                  color: Color(0xFF888), fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Section: Operational Status ───────────────────
                    _SectionCard(
                      icon: null,
                      title: '',
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('OPERATIONAL STATUS',
                              style: TextStyle(
                                  color: Color(0xFF888), fontSize: 10,
                                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          const SizedBox(height: 10),
                          ...StationStatus.values.map((s) => _StatusOption(
                            status: s,
                            selected: _status == s,
                            onTap: () => setState(() => _status = s),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Section: Live Preview Map ──────────────────────
                    _LivePreviewMap(
                      lat: double.tryParse(_latCtrl.text) ?? 3.1390,
                      lng: double.tryParse(_lngCtrl.text) ?? 101.6869,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  TextEditingController _ctrlFor(RecycleMaterialType m) {
    switch (m) {
      case RecycleMaterialType.plastic:   return _plasticCtrl;
      case RecycleMaterialType.paper:     return _paperCtrl;
      case RecycleMaterialType.glass:     return _glassCtrl;
      case RecycleMaterialType.cardboard: return _cardboardCtrl;
      case RecycleMaterialType.metal:     return _metalCtrl;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isEdit;
  const _TopBar({required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: _darkGreen),
        ),
        const SizedBox(width: 8),
        Container(
          width: 24, height: 24,
          decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
          child: const Icon(Icons.eco, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        const Text('STATION REGISTRY',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14,
                letterSpacing: 1.2, color: _darkGreen)),
        const Spacer(),
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFEAF7EE),
          child: const Icon(Icons.person, color: _darkGreen, size: 16),
        ),
      ]),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final bool isEdit;
  final String? stationId;
  const _Breadcrumb({required this.isEdit, this.stationId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('REGISTRY',
              style: TextStyle(color: _green, fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('›',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11))),
          const Text('STATIONS',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('›',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11))),
          Text(
            isEdit ? 'CONFIGURE STATION' : 'ADD STATION',
            style: const TextStyle(color: Color(0xFF555), fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          isEdit ? 'Edit Station Profile' : 'Add New Station',
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800, color: _darkGreen),
        ),
        const SizedBox(height: 4),
        Text(
          isEdit
              ? 'Manage the operational parameters and material lifecycle for node #$stationId. All changes are logged in the global ledger.'
              : 'Fill in the details to register a new recycling station.',
          style: const TextStyle(color: Color(0xFF666), fontSize: 13),
        ),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final Widget child;
  final EdgeInsets padding;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              if (icon != null) ...[
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _green, size: 16),
                ),
                const SizedBox(width: 10),
              ],
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13,
                      color: _darkGreen, letterSpacing: 0.5)),
            ]),
          ),
        if (title.isNotEmpty)
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
        Padding(padding: padding, child: child),
      ]),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffix;
  final IconData? prefixIcon;
  final int maxLines;

  const _FormField({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.suffix,
    this.prefixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: Color(0xFF888), fontSize: 10,
              fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: _darkGreen),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
          filled: true,
          fillColor: _inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: Color(0xFFE53935), width: 1),
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFFAAAAAA), size: 18)
              : null,
          suffixText: suffix,
          suffixStyle: const TextStyle(
              color: Color(0xFF888), fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
        ),
      ),
    ]);
  }
}

class _MaterialGrid extends StatelessWidget {
  final Set<RecycleMaterialType> selected;
  final ValueChanged<RecycleMaterialType> onToggle;

  const _MaterialGrid({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final items = <_MatItem>[
      _MatItem(type: RecycleMaterialType.plastic,   icon: Icons.recycling,           label: 'PLASTIC'),
      _MatItem(type: RecycleMaterialType.glass,     icon: Icons.wine_bar_outlined,   label: 'GLASS'),
      _MatItem(type: RecycleMaterialType.paper,     icon: Icons.description_outlined, label: 'PAPER'),
      _MatItem(type: RecycleMaterialType.cardboard, icon: Icons.inventory_2_outlined, label: 'E-WASTE'),
      _MatItem(type: RecycleMaterialType.metal,     icon: Icons.settings_outlined,   label: 'METAL'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final on = selected.contains(item.type);
        return GestureDetector(
          onTap: () => onToggle(item.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: on ? _green.withOpacity(0.12) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: on ? _green : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon,
                    color: on ? _green : const Color(0xFFAAAAAA), size: 22),
                const SizedBox(height: 6),
                Text(item.label,
                    style: TextStyle(
                        color: on ? _darkGreen : const Color(0xFFAAAAAA),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MatItem {
  final RecycleMaterialType type;
  final IconData icon;
  final String label;
  const _MatItem({required this.type, required this.icon, required this.label});
}

class _StatusOption extends StatelessWidget {
  final StationStatus status;
  final bool selected;
  final VoidCallback onTap;
  const _StatusOption({
    required this.status, required this.selected, required this.onTap,
  });

  Color get _dotColor {
    switch (status) {
      case StationStatus.active:      return _green;
      case StationStatus.maintenance: return const Color(0xFFF5A623);
      case StationStatus.offline:     return const Color(0xFFBBBBBB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? _green.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _green : const Color(0xFFE8E8E8),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: selected ? _dotColor : const Color(0xFFBBBBBB),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(status.label,
              style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: selected ? _darkGreen : const Color(0xFF888))),
          const Spacer(),
          if (selected)
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                  color: _green, shape: BoxShape.circle),
              child: const Icon(Icons.check,
                  color: Colors.white, size: 13),
            ),
        ]),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(children: [
        // Dark grid placeholder — swap with GoogleMap(initialCameraPosition: ...)
        Container(
          height: 180,
          color: const Color(0xFF0D1F0D),
          child: CustomPaint(
            painter: _GridPainter(),
            child: const SizedBox.expand(),
          ),
        ),
        // Pin
        const Center(
          child: Icon(Icons.location_on,
              color: Color(0xFF888888), size: 48),
        ),
        // Live preview badge
        Positioned(
          bottom: 12, left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('LIVE PREVIEW',
                style: TextStyle(color: Colors.white70, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ),
        ),
        // Expand icon
        Positioned(
          bottom: 10, right: 10,
          child: Container(
            width: 30, height: 30,
            decoration: const BoxDecoration(
                color: _green, shape: BoxShape.circle),
            child: const Icon(Icons.open_in_full,
                color: Colors.white, size: 15),
          ),
        ),
      ]),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A3A1A)
      ..strokeWidth = 0.5;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

// ── Admin bottom nav (shared) ─────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  const _BottomNav({required this.selected});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_outlined,    label: 'HOME'),
      _NavItem(icon: Icons.list_alt_outlined, label: 'REGISTRY'),
      _NavItem(icon: Icons.map_outlined,      label: 'MAP'),
      _NavItem(icon: Icons.history_outlined,  label: 'LOGS'),
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