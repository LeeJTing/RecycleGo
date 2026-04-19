import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:recycle_go/models/RecycleStations.dart';
import 'package:recycle_go/services/station_service.dart';
import 'package:recycle_go/view/recycle/station_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Set<String> _favorites = {};

  void _onMapIdle() {
    if (_isManualMove) return;
    if (_filteredStations.isEmpty) return;

    if (_mapController == null) return;

    if (_lastCameraPosition == null) return;

    final centerLatLng = _lastCameraPosition!.target;

    // 找最近的 station
    RecycleStation? nearest;
    double minDistance = double.infinity;

    for (var s in _filteredStations) {
      final d = Geolocator.distanceBetween(
        centerLatLng.latitude,
        centerLatLng.longitude,
        s.latitude,
        s.longitude,
      );

      if (d < minDistance) {
        minDistance = d;
        nearest = s;
      }
    }

    if (nearest == null) return;

    final index = _filteredStations.indexWhere(
          (e) => e.stationId == nearest!.stationId,
    );

    if (index != -1 && index != _currentIndex) {
      setState(() {
        _selectedStation = nearest;
        _currentIndex = index;
      });

      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      _getRouteInfo(nearest);
    }
  }

  Future<void> _fetchRoute(RecycleStation s, {bool draw = false}) async {
    if (s.stationId == null) return;

    final stationId = s.stationId!;
    final mode = _travelMode;

    // ✅ 1. 先查 cache（只针对 duration / distance）
    if (!draw && _durationCache[stationId]?[mode] != null) {
      setState(() {
        _durations[stationId] = _durationCache[stationId]![mode]!;
        _distances[stationId] = _distanceCache[stationId]![mode]!;
      });
      return;
    }

    // ✅ 2. call API（只 call 一次）
    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_currentPosition.latitude},${_currentPosition.longitude}'
        '&destination=${s.latitude},${s.longitude}'
        '&mode=$mode'
        '&departure_time=now'
        '&key=YOUR_API_KEY'; // ❗记得换掉

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    // ❗加这个（很关键）
    if (data['status'] != 'OK' || data['routes'].isEmpty) {
      setState(() {
        _durations[stationId] = "No route";
        _distances[stationId] = "-";
      });
      return;
    }

    final route = data['routes'][0];
    final leg = route['legs'][0];

    final duration = leg['duration']['text'];
    final distance = leg['distance']['text'];

    // ✅ 3. 存 cache
    _durationCache.putIfAbsent(stationId, () => {});
    _distanceCache.putIfAbsent(stationId, () => {});
    _durationCache[stationId]![mode] = duration;
    _distanceCache[stationId]![mode] = distance;

    // ✅ 4. 更新 UI（基础数据）
    setState(() {
      _durations[stationId] = duration;
      _distances[stationId] = distance;
    });

    // ✅ 5. 如果需要画路线
    if (draw) {
      final points = route['overview_polyline']['points'];
      final decoded = _decodePolyline(points);

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: PolylineId("route"),
            points: decoded,
            color: Colors.blue,
            width: 5,
          ),
        );
      });

      // ✅ 自动 zoom 到路线
      if (decoded.isNotEmpty) {
        double minLat = decoded.first.latitude;
        double maxLat = decoded.first.latitude;
        double minLng = decoded.first.longitude;
        double maxLng = decoded.first.longitude;

        for (var p in decoded) {
          if (p.latitude < minLat) minLat = p.latitude;
          if (p.latitude > maxLat) maxLat = p.latitude;
          if (p.longitude < minLng) minLng = p.longitude;
          if (p.longitude > maxLng) maxLng = p.longitude;
        }

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            100,
          ),
        );
      }
    }
  }

  void _selectStation(RecycleStation s) {
    setState(() {
      _selectedStation = s;
    });

    // 👉 移动地图
    _isManualMove = true;

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(s.latitude - 0.002, s.longitude),
      ),
    ).then((_) {
      _isManualMove = false;
    });

    // 👉 拿 route info
    _fetchRoute(s);
  }

  List<RecycleStation> _filterStations(String query) {
    if (query.isEmpty) return _stations;

    return _stations.where((s) =>
    s.stationName.toLowerCase().contains(query.toLowerCase()) ||
        s.address.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<String> _searchHistory = [];

  final DraggableScrollableController _sheetController = DraggableScrollableController();

  final PageController _pageController =
  PageController(viewportFraction: 0.95);

  String _travelMode = "driving";

  // cache: stationId -> mode -> value
  Map<String, Map<String, String>> _durationCache = {};
  Map<String, Map<String, String>> _distanceCache = {};

  Map<String, String> _durations = {};
  Map<String, String> _distances = {};

  int _currentIndex = 0;
  Timer? _scrollDebounce;

  Set<Polyline> _polylines = {};

  double _formatDistanceValue(RecycleStation s) {
    return s.distanceFrom(
      _currentPosition.latitude,
      _currentPosition.longitude,
    );
  }

  Widget _modeItem(String mode, IconData icon) {
    final isSelected = _travelMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedStation == null) return;

          setState(() {
            _travelMode = mode;
            _polylines.clear(); // 清路线（等用户点 View 才画）
          });

          _getRouteInfo(_selectedStation!);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1DB954) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.black54,
            size: 20,
          ),
        ),
      ),
    );
  }

  Future<void> _drawRoute(RecycleStation s) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_currentPosition.latitude},${_currentPosition.longitude}'
        '&destination=${s.latitude},${s.longitude}'
        '&mode=$_travelMode'
        '&departure_time=now'
        '&key=AIzaSyCpKVaF6ku0yKq-SV__pK8pCsrbao_k5pQ';

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if (data['routes'].isEmpty) {
      setState(() {
        _durations[s.stationId!] = "No route";
        _distances[s.stationId!] = "-";
      });
      return;
    }

    final points = data['routes'][0]['overview_polyline']['points'];
    final decoded = _decodePolyline(points);

    final leg = data['routes'][0]['legs'][0];

    final durationText = leg['duration']['text'];   // e.g. "15 mins"
    final durationValue = leg['duration']['value']; // 秒

    final distanceText = leg['distance']['text'];   // e.g. "5.2 km"

    setState(() {
      _durations[s.stationId!] = durationText;
      _distances[s.stationId!] = distanceText;

      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: PolylineId("route"),
          points: decoded,
          color: Colors.blue,
          width: 5,
        ),
      );
    });

    // ✅ 就放这里（最重要）
    if (decoded.isNotEmpty) {
      _isManualMove = true;

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: decoded.reduce((a, b) => LatLng(
              a.latitude < b.latitude ? a.latitude : b.latitude,
              a.longitude < b.longitude ? a.longitude : b.longitude,
            )),
            northeast: decoded.reduce((a, b) => LatLng(
              a.latitude > b.latitude ? a.latitude : b.latitude,
              a.longitude > b.longitude ? a.longitude : b.longitude,
            )),
          ),
          100,
        ),).then((_) {
        _isManualMove = false;
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return poly;
  }

  Future<void> _getRouteInfo(RecycleStation s) async {
    if (s.stationId == null) return; // ✅ 防 crash

    final stationId = s.stationId!; // ✅ 就放这里
    final mode = _travelMode;

    // ✅ 如果 cache 已存在 → 直接用
    if (_durationCache[stationId]?[mode] != null) {
      setState(() {
        _durations[s.stationId!] = _durationCache[stationId]![mode]!;
        _distances[s.stationId!] = _distanceCache[stationId]![mode]!;
      });
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_currentPosition.latitude},${_currentPosition.longitude}'
        '&destination=${s.latitude},${s.longitude}'
        '&mode=$_travelMode'
        '&departure_time=now'
        '&key=AIzaSyCpKVaF6ku0yKq-SV__pK8pCsrbao_k5pQ';

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if (data['routes'].isEmpty) return;

    final leg = data['routes'][0]['legs'][0];

    final duration = leg['duration']['text'];
    final distance = leg['distance']['text'];

    // ✅ 存进 cache
    _durationCache.putIfAbsent(stationId, () => {});
    _distanceCache.putIfAbsent(stationId, () => {});

    _durationCache[stationId]![mode] = duration;
    _distanceCache[stationId]![mode] = distance;

    setState(() {
      _durations[stationId] = duration;
      _distances[stationId] = distance;
    });
  }

  Future<void> _openDirections(RecycleStation s) async {
    final lat = s.latitude;
    final lng = s.longitude;

    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '&origin=${_currentPosition.latitude},${_currentPosition.longitude}'
          '&destination=$lat,$lng'
          '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch map';
    }
  }

  Widget _modeButton(String mode, IconData icon) {
    final isSelected = _travelMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _travelMode = mode;
          _polylines.clear(); // 清路线
        });

        if (_selectedStation != null) {
          _getRouteInfo(_selectedStation!);
        }
      },
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1DB954) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black54,
        ),
      ),
    );
  }

  Widget _modeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _modeItem("driving", Icons.directions_car),
          _modeItem("walking", Icons.directions_walk),
        ],
      ),
    );
  }

  // ── Map controller ────────────────────────────────────────────────
  GoogleMapController? _mapController;
  CameraPosition? _lastCameraPosition;

  // ── Location state ────────────────────────────────────────────────
  LatLng _currentPosition = const LatLng(3.1390, 101.6869); // KL fallback
  bool _locationReady = false;

  // ── Station state ─────────────────────────────────────────────────
  List<RecycleStation> _stations = [];
  RecycleStation? _selectedStation;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isManualMove = false;
  String? _error;

  // ── Search ────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<RecycleStation> _filteredStations = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadStations();
    _loadSearchHistory();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];

    setState(() {
      _favorites = list.toSet();
    });
  }

  Future<void> _toggleFavorite(String stationId) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (_favorites.contains(stationId)) {
        _favorites.remove(stationId);
      } else {
        _favorites.add(stationId);
      }
    });

    await prefs.setStringList('favorites', _favorites.toList());
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();

    _searchHistory.remove(query);
    _searchHistory.insert(0, query);

    if (_searchHistory.length > 5) {
      _searchHistory = _searchHistory.sublist(0, 5);
    }

    await prefs.setStringList('search_history', _searchHistory);

    setState(() {}); // 👈 记得刷新 UI
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

      print("Location ready: $_locationReady");
      print("Lat: ${_currentPosition.latitude}, Lng: ${_currentPosition.longitude}");

      // Move camera to user location once map is ready
      _isManualMove = true;

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 14.5),
        ),
      ).then((_) {
        _isManualMove = false;
      });

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
        markerId: MarkerId(s.stationId!),
        position: LatLng(s.latitude, s.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          s.isActive
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: s.stationName,
        ),
        onTap: () {
          final index = _filteredStations.indexWhere(
                (e) => e.stationId == s.stationId,
          );

          if (index != -1) {
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_sheetController.isAttached) {
              _sheetController.animateTo(
                0.45,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
          setState(() => _selectedStation = s);
          _getRouteInfo(s);
        },
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
    if (query.isNotEmpty) {
      _saveSearch(query);
    }

    final results = query.isEmpty
        ? _stations
        : _stations.where((s) =>
    s.stationName.toLowerCase().contains(query.toLowerCase()) ||
        s.address.toLowerCase().contains(query.toLowerCase())
    ).toList();

    setState(() {
      _filteredStations = results;
    });

    // ✅ 如果有结果 → 自动跳第一个
    if (results.isNotEmpty) {
      final s = results.first;

      _selectStation(s);

      // 👉 移动地图
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(s.latitude - 0.002, s.longitude),
        ),
      );

      // 👉 滑到对应卡片
      final index = _filteredStations.indexOf(s);
      if (index != -1) {
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }

      // 👉 拿 route info
      _getRouteInfo(s);
    }
  }

  // ── 5. Re-centre camera to user ───────────────────────────────────
  void _goToMyLocation() {
    setState(() {
      _polylines.clear();
      _durations.clear();
      _distances.clear();
    });

    _isManualMove = true;

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition.latitude - 0.002,
            _currentPosition.longitude,
          ),
          zoom: 15,
        ),
      ),
    ).then((_) {
      _isManualMove = false;
    });
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
            onCameraMove: (position) {
              _lastCameraPosition = position;
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition.latitude - 0.002,
                _currentPosition.longitude,
              ),
              zoom: 14.5,
            ),
            markers: _markers,
            polylines: _polylines,
            onCameraIdle: _onMapIdle,
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
            onTap: (_) {
              FocusScope.of(context).unfocus(); // 👈 再保险一次
              setState(() => _selectedStation = null);
            },
          ),

          // ── Top bar ─────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Header row
                SizedBox(height: 10),
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
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _filteredStations = _stations;
                          });
                        } else {
                          setState(() {
                            _filteredStations = _filterStations(value);
                          });
                        }
                      },
                      onSubmitted: (value) {
                        FocusScope.of(context).unfocus(); // 👈 顺便收键盘
                        _onSearch(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search recycle stations..',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                        suffixIcon: const Icon(Icons.tune, color: Color(0xFF1DB954), size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                // 3. 搜索历史 (放在搜索框下面，并增加装饰)
                if (_searchCtrl.text.isEmpty && _searchHistory.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 10, 24, 0), // 左右边距比搜索框稍大一点，更有层次感
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _searchHistory.take(3).map((item) { // 只取最近3条，防止遮挡地图太多
                        return ListTile(
                          dense: true, // 使行高更紧凑
                          leading: const Icon(Icons.history, size: 18, color: Colors.grey),
                          title: Text(
                            item,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                          ),
                          trailing: GestureDetector(
                            onTap: () async {
                              final prefs = await SharedPreferences.getInstance();

                              _searchHistory.remove(item);
                              await prefs.setStringList('search_history', _searchHistory);

                              if (_searchCtrl.text == item) {
                                _searchCtrl.clear();

                                setState(() {
                                  _filteredStations = _stations;
                                });

                                // 👉 optional：回到最近站点
                                if (_stations.isNotEmpty) {
                                  _selectStation(_stations.first);
                                }
                              }

                              setState(() {});
                            },
                            child: const Icon(Icons.close, size: 16, color: Colors.red),
                          ), // 提示点击可填入
                          onTap: () {
                            _searchCtrl.text = item;
                            _onSearch(item);
                          },
                        );
                      }).toList(),
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
            bottom: 180,
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
              bottom: 170,
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
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.2,
            minChildSize: 0.1,
            maxChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: ListView(
                  controller: scrollController,
                  children: [

                    // 👇 拖动条
                    Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // 👇 标题
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Recycle Station",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    _modeSelector(),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        controller: _pageController,// 👈 卡片露一点
                        itemCount: _filteredStations.length,

                        onPageChanged: (index) {
                          final s = _filteredStations[index];

                          setState(() {
                            _selectedStation = s;
                            _currentIndex = index;
                          });
                          _scrollDebounce?.cancel();
                          _scrollDebounce = Timer(Duration(milliseconds: 400), () {
                            _getRouteInfo(s);
                          });

                          _isManualMove = true;

                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(
                              LatLng(s.latitude - 0.002, s.longitude),
                            ),
                          ).then((_) {
                            _isManualMove = false;
                          });

                        },

                        itemBuilder: (context, index) {
                          final s = _filteredStations[index];

                          return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StationDetailScreen(
                                        station: s,
                                        distanceKm: _formatDistanceValue(s),

                                        duration: s.stationId != null ? _durations[s.stationId!] : null,
                                        routeDistance: s.stationId != null ? _distances[s.stationId!] : null,
                                      ),
                                    ),
                                  );

                                  // 👇 如果是从 Navigate 按钮回来
                                  if (result != null && result is RecycleStation) {
                                    setState(() {
                                      _selectedStation = result;
                                    });

                                    // 👉 移动地图
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLng(
                                        LatLng(result.latitude - 0.002, result.longitude),
                                      ),
                                    );

                                    // 👉 画路线（最关键）
                                    await _drawRoute(result);

                                    // 👉 打开 bottom sheet
                                    if (_sheetController.isAttached) {
                                      _sheetController.animateTo(
                                        0.45,
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  }
                                },
                                child: _StationCard(
                                  station: s,
                                  distance: _formatDistance(s),
                                  duration: s.stationId != null ? _durations[s.stationId!] : null,
                                  routeDistance: s.stationId != null ? _distances[s.stationId!] : null,
                                  isFav: s.stationId != null && _favorites.contains(s.stationId!),
                                  onFavoriteToggle: () {
                                    if (s.stationId != null) {
                                      _toggleFavorite(s.stationId!);
                                    }
                                  },
                                  onDirections: () async {
                                    if (!context.mounted) return;

                                    showModalBottomSheet(
                                      context: context,
                                      builder: (_) {
                                        return SafeArea(
                                          child: Wrap(
                                            children: [
                                              ListTile(
                                                leading: Icon(Icons.map, color: Colors.green),
                                                title: Text("View in App"),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  await _drawRoute(s);
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(Icons.open_in_new, color: Colors.blue),
                                                title: Text("Open in Google Maps"),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _openDirections(s);
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              );
            },
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
  final String? duration;
  final String? routeDistance;
  final bool isFav;
  final VoidCallback onFavoriteToggle;

  const _StationCard({
    required this.station,
    required this.distance,
    required this.onDirections,
    required this.isFav,
    required this.onFavoriteToggle,
    this.duration,
    this.routeDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
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
                              totalKg: station.stationCapacity,
                              usedKg: station.totalCapacity,
                            ),
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
                        if (duration != null && routeDistance != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '$duration • $routeDistance',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
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
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : const Color(0xFF1DB954),
                      ),
                      onPressed: onFavoriteToggle,
                    ),
                  )
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
  final double usedKg;

  const _CapacityBadge({
    required this.totalKg,
    required this.usedKg,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (totalKg - usedKg).clamp(0, totalKg);

    final label = remaining >= 1000
        ? '${(remaining / 1000).toStringAsFixed(1)}t left'
        : '${remaining.toStringAsFixed(0)}kg left';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: remaining <= 0
            ? Colors.red.shade100
            : const Color(0xFFDDEEDD),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: remaining <= 0
              ? Colors.red
              : const Color(0xFFB8D8B8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: remaining <= 0
              ? Colors.red
              : const Color(0xFF155E2D),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
