import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recycle_go/models/RecycleStations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/services/storage_service.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:recycle_go/services/notification_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

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
  late final TextEditingController _capacityCtrl;

  Future<File> generateQrImage(String data) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    );

    final picData = await painter.toImageData(300);
    final buffer = picData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/qr.png');

    await file.writeAsBytes(buffer);

    return file;
  }

  // QR
  late final _qrCtrl = TextEditingController(
    text: widget.station?.qrCodeValue ?? '',
  );

  // Image
  File? _selectedImage;
  String? _imageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

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
      text: widget.station?.plasticStorage?.toStringAsFixed(0) ?? '');

  late final _paperCtrl    = TextEditingController(
      text: widget.station?.paperStorage?.toStringAsFixed(0) ?? '');

  late final _glassCtrl    = TextEditingController(
      text: widget.station?.glassStorage?.toStringAsFixed(0) ?? '');

  late final _cardboardCtrl= TextEditingController(
      text: widget.station?.cardboardStorage?.toStringAsFixed(0) ?? '');

  late final _metalCtrl    = TextEditingController(
      text: widget.station?.metalStorage?.toStringAsFixed(0) ?? '');

  // ── Status ─────────────────────────────────────────────────────────
  StationStatus _status = StationStatus.active;

  // ── Capacity slider (total kg, 1k–50k) ────────────────────────────
  double _capacitySlider = 1000;

  // ── Selected material toggles ──────────────────────────────────────
  final Set<RecycleMaterialType> _selectedMats = {};

  @override
  void initState() {
    _qrCtrl.addListener(() {
      setState(() {});
    });

    super.initState();
    _latCtrl.addListener(() => setState(() {}));

    _capacityCtrl = TextEditingController(
      text: _capacitySlider.toStringAsFixed(0),
    );

    if (widget.station != null) {
      _status = widget.station!.stationStatus;
      _capacitySlider = widget.station!.stationCapacity
          .clamp(1000, 50000)
          .toDouble();
      _selectedMats.addAll(widget.station!.supportedMaterials);
      _imageUrl = widget.station!.imageUrl;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _addressCtrl,
      _latCtrl,
      _lngCtrl,
      _descCtrl,
      _plasticCtrl,
      _paperCtrl,
      _glassCtrl,
      _cardboardCtrl,
      _metalCtrl,
      _capacityCtrl,
      _qrCtrl,
    ]) {
      c.dispose();
    }

    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────
  void _save() async {
    final storage = StorageService();

    String? finalImageUrl = _imageUrl;

    // ✅ 先决定最终 QR value
    final uuid = Uuid();
    final finalQrValue = _qrCtrl.text.trim().isEmpty
        ? 'ECO-${uuid.v4()}'
        : _qrCtrl.text.trim();

    final hash = md5.convert(utf8.encode(finalQrValue)).toString();

    String? qrImageUrl = widget.station?.qrImageUrl;

    final isQrChanged = widget.station == null ||
        finalQrValue != widget.station!.qrCodeValue ||
        widget.station?.qrImageUrl == null;

    if (isQrChanged) {
      final qrFile = await generateQrImage(finalQrValue);

      // ✅ 固定路径（关键）
      final path = 'qr/$hash.png';

      await storage.uploadImage(
        bucketName: 'station-images',
        path: path,
        file: qrFile,
      );

      // ✅ CDN cache bust
      qrImageUrl = storage
          .getPublicUrl('station-images', path) +
          '?v=${DateTime.now().millisecondsSinceEpoch}';
    }

    if (_selectedImage != null) {
      final client = Supabase.instance.client;
      final storage = StorageService();

      final fileName = 'station_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'stations/$fileName';

      // ✅ 先保存旧图
      final oldImageUrl = _imageUrl;

      try {
        await storage.uploadImage(
          bucketName: 'station-images',
          path: path,
          file: _selectedImage!,
        );

        finalImageUrl = storage.getPublicUrl('station-images', path);

        // ✅ 更新新图
        setState(() => _imageUrl = finalImageUrl);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload Error: ${e.toString()}")),
        );
        return;
      }

      // ✅ 用 oldImageUrl 删除旧图（不是新图！）
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(oldImageUrl);
          final segments = uri.pathSegments;

          final oldPath = uri.path.replaceFirst(
            '/storage/v1/object/public/station-images/',
            '',
          );

          await client.storage
              .from('station-images')
              .remove([oldPath]);
        } catch (e) {
          print('Delete failed: $e');
        }
      }
    }
    print("FINAL IMAGE URL => $finalImageUrl");

    if (_capacitySlider <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capacity must be greater than 0')),
      );
      return;
    }

    if (_selectedMats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one material')),
      );
      return;
    }

    double totalStorage = 0;

    if (_selectedMats.contains(RecycleMaterialType.plastic)) {
      totalStorage += double.tryParse(_plasticCtrl.text) ?? 0;
    }
    if (_selectedMats.contains(RecycleMaterialType.paper)) {
      totalStorage += double.tryParse(_paperCtrl.text) ?? 0;
    }
    if (_selectedMats.contains(RecycleMaterialType.glass)) {
      totalStorage += double.tryParse(_glassCtrl.text) ?? 0;
    }
    if (_selectedMats.contains(RecycleMaterialType.cardboard)) {
      totalStorage += double.tryParse(_cardboardCtrl.text) ?? 0;
    }
    if (_selectedMats.contains(RecycleMaterialType.metal)) {
      totalStorage += double.tryParse(_metalCtrl.text) ?? 0;
    }

    if (totalStorage > _capacitySlider) {
      double overflow = totalStorage - _capacitySlider;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exceeded by ${overflow.toStringAsFixed(0)} kg'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    print('STATUS BEFORE SAVE => ${_status.name}');

    final station = RecycleStation(
      stationCapacity: _capacitySlider,
      stationId: _isEdit ? widget.station!.stationId : null,
      stationName: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      latitude: double.tryParse(_latCtrl.text) ?? 0,
      longitude: double.tryParse(_lngCtrl.text) ?? 0,
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      imageUrl: finalImageUrl,
      stationStatus: _status,
      qrImageUrl: qrImageUrl,

      plasticStorage: _selectedMats.contains(RecycleMaterialType.plastic)
          ? (double.tryParse(_plasticCtrl.text) ?? 0)
          : null,

      paperStorage: _selectedMats.contains(RecycleMaterialType.paper)
          ? (double.tryParse(_paperCtrl.text) ?? 0)
          : null,

      glassStorage: _selectedMats.contains(RecycleMaterialType.glass)
          ? (double.tryParse(_glassCtrl.text) ?? 0)
          : null,

      cardboardStorage: _selectedMats.contains(RecycleMaterialType.cardboard)
          ? (double.tryParse(_cardboardCtrl.text) ?? 0)
          : null,

      metalStorage: _selectedMats.contains(RecycleMaterialType.metal)
          ? (double.tryParse(_metalCtrl.text) ?? 0)
          : null,

      qrCodeValue: finalQrValue,

      createdAt: _isEdit
          ? widget.station!.createdAt
          : DateTime.now(),
    );
    print('DATA => ${station.toMap()}');


    final model = RecycleStationModel();

    try {
      RecycleStation? result;

      if (_isEdit) {
        // ❌ 修改 → 不通知
        result = await model.updateStation(station);
      } else {
        // ✅ 新建 → 才通知
        result = await model.insertStation(station);

        if (result != null) {
          await showStationCreatedNotification(
            station.stationName.isNotEmpty ? station.stationName : "New Station",
            station.address.isNotEmpty ? station.address : "Location not specified",
          );
        }
      }

      if (result != null) {
        Navigator.pop(context, result); // 成功才返回
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save failed')),
        );
      }
    } catch (e) {
      print('SAVE ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      bottomNavigationBar: null,
      body: SafeArea(
        child: Column(children: [
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
                          // 将颜色改为更明显的灰色或品牌绿
                          side: const BorderSide(color: Color(0xFF999999)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 13),
                        ),
                        child: const Text('CANCEL',
                            style: TextStyle(
                                color: Color(0xFF444444), // 加深文字颜色
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
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
                        const SizedBox(height: 12),

                        _PickLocationMap(
                          lat: double.tryParse(_latCtrl.text) ?? 3.1390,
                          lng: double.tryParse(_lngCtrl.text) ?? 101.6869,
                          onLocationSelected: (lat, lng) {
                            setState(() {
                              _latCtrl.text = lat.toStringAsFixed(6);
                              _lngCtrl.text = lng.toStringAsFixed(6);
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _FormField(
                            label: 'DESCRIPTION (optional)',
                            ctrl: _descCtrl,
                            hint: 'Brief note about this station...',
                            maxLines: 2),
                        const SizedBox(height: 20),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'STATION IMAGE',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_selectedImage!, fit: BoxFit.cover),
                            )
                                : _imageUrl != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(_imageUrl!, fit: BoxFit.cover),
                            )
                                : const Center(child: Text("Tap to upload image")),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    _FormField(
                      label: 'QR CODE VALUE',
                      ctrl: _qrCtrl,
                      hint: 'e.g. ECO-123456',
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _qrCtrl.text = 'ECO-${DateTime.now().millisecondsSinceEpoch}';
                            });
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: _green),
                          child: const Text("AUTO GENERATE"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_qrCtrl.text.isNotEmpty)
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              "QR CODE",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF888888),
                              ),
                            ),
                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                              ),
                              child: QrImageView(
                                data: _qrCtrl.text,
                                size: 150,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
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
                                    color: Color(0xFF888888), fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5)),
                          ),
                          const SizedBox(height: 10),
                          ..._selectedMats.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF444444),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                _FormField(
                                  label: '', // ❗ 不用内部 label
                                  ctrl: _ctrlFor(m),
                                  hint: '0',
                                  keyboardType: TextInputType.number,
                                  suffix: 'kg',
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                                  ],
                                ),
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
                                  color: Color(0xFF888888), fontSize: 10,
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
                                    color: Color(0xFF888888)),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 10),

                          TextField(
                            controller: _capacityCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: 'Enter capacity (kg)',
                              suffixText: 'KG',
                              filled: true,
                              fillColor: _inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) {
                              final v = double.tryParse(value);
                              if (v == null) return;

                              final clamped = v.clamp(1000, 50000).toDouble();

                              setState(() {
                                _capacitySlider = clamped;
                              });
                            },
                            // ✅ 用户“输入完成”才修正
                            onEditingComplete: () {
                              final v = double.tryParse(_capacityCtrl.text);
                              if (v == null) return;

                              final clamped = v.clamp(1000, 50000).toDouble();

                              setState(() {
                                _capacitySlider = clamped;

                                _capacityCtrl.value = TextEditingValue(
                                  text: clamped.toStringAsFixed(0),
                                  selection: TextSelection.collapsed(
                                    offset: clamped.toStringAsFixed(0).length,
                                  ),
                                );
                              });

                              FocusScope.of(context).unfocus(); // 收起键盘（可选）
                            },
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
                              onChanged: (v) {
                                setState(() {
                                  _capacitySlider = v;
                                  _capacityCtrl.value = TextEditingValue(
                                    text: v.toStringAsFixed(0),
                                    selection: TextSelection.collapsed(
                                      offset: v.toStringAsFixed(0).length,
                                    ),
                                  );
                                });
                              },
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1K', style: TextStyle(
                                  color: Color(0xFF888888), fontSize: 11)),
                              Text('50K', style: TextStyle(
                                  color: Color(0xFF888888), fontSize: 11)),
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
                                  color: Color(0xFF888888), fontSize: 10,
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
              color: Color(0xFF888888), fontSize: 10,
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
              color: Color(0xFF888888), fontSize: 13),
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
      _MatItem(type: RecycleMaterialType.cardboard, icon: Icons.inventory_2_outlined, label: 'CARDBOARD'),
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
                    color: on ? _green : const Color(0xFF888888), size: 22),
                const SizedBox(height: 6),
                Text(item.label,
                    style: TextStyle(
                        color: on ? _darkGreen : const Color(0xFF666666),
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
      case StationStatus.active:
        return _green;
      case StationStatus.maintenance:
        return const Color(0xFFF5A623); // 橙色
      case StationStatus.offline:
        return const Color(0xFFE53935); // 🔥 红色（error）
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
                color: selected ? _darkGreen : const Color(0xFF555555),)),
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

            // 👇 这个你保留
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

class FullMapScreen extends StatefulWidget {
  final double lat;
  final double lng;

  const FullMapScreen({
    super.key,
    required this.lat,
    required this.lng,
  });

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  LatLng? _selectedLatLng;

  @override
  void initState() {
    super.initState();
    _selectedLatLng = LatLng(widget.lat, widget.lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location"),
        backgroundColor: const Color(0xFF1DB954),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _selectedLatLng!,
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("selected"),
            position: _selectedLatLng!,
          ),
        },
        onTap: (LatLng position) {
          setState(() {
            _selectedLatLng = position;
          });
        },
      ),
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

class _PickLocationMap extends StatefulWidget {
  final double lat;
  final double lng;
  final Function(double, double) onLocationSelected;

  const _PickLocationMap({
    required this.lat,
    required this.lng,
    required this.onLocationSelected,
  });

  @override
  State<_PickLocationMap> createState() => _PickLocationMapState();
}

class _PickLocationMapState extends State<_PickLocationMap> {
  LatLng? _selectedLatLng;

  @override
  void initState() {
    super.initState();
    _selectedLatLng = LatLng(widget.lat, widget.lng);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _selectedLatLng!,
            zoom: 15,
          ),

          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
            ),
          },

          markers: {
            if (_selectedLatLng != null)
              Marker(
                markerId: const MarkerId("selected"),
                position: _selectedLatLng!,
              ),
          },

          onTap: (LatLng position) {
            setState(() {
              _selectedLatLng = position;
            });

            // 🔥 回传给表单
            widget.onLocationSelected(
              position.latitude,
              position.longitude,
            );
          },

          myLocationEnabled: true,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }
}
