import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// ════════════════════════════════════════════════════════════════════════════
//  CÁC HẰNG SỐ TOÀN CỤC
// ════════════════════════════════════════════════════════════════════════════

// OSRM – miễn phí, không cần API key
// Hỗ trợ profile: driving | walking | cycling
const String _kOsrmBase = 'https://router.project-osrm.org/route/v1';

// Nominatim – geocoding/tìm địa điểm miễn phí (OpenStreetMap)
const String _kNominatim = 'https://nominatim.openstreetmap.org';

// Các loại địa điểm phổ biến để tìm kiếm
const List<Map<String, dynamic>> _kPlaceCategories = [
  {'label': 'Khách sạn',  'icon': Icons.hotel,             'query': 'hotel'},
  {'label': 'Quán ăn',    'icon': Icons.restaurant,        'query': 'restaurant'},
  {'label': 'Bệnh viện',  'icon': Icons.local_hospital,    'query': 'hospital'},
  {'label': 'Trường học', 'icon': Icons.school,            'query': 'school'},
  {'label': 'Café',       'icon': Icons.local_cafe,        'query': 'cafe'},
  {'label': 'Siêu thị',  'icon': Icons.shopping_cart,     'query': 'supermarket'},
  {'label': 'ATM',        'icon': Icons.atm,               'query': 'ATM'},
  {'label': 'Xăng dầu',  'icon': Icons.local_gas_station, 'query': 'fuel'},
];

// ── Phương tiện di chuyển ──────────────────────────────────────────────────
enum TravelMode {
  driving('Ô tô',    Icons.directions_car,  'driving', Colors.blue),
  motorcycle('Xe máy', Icons.two_wheeler,   'driving', Colors.orange),
  walking('Đi bộ',   Icons.directions_walk, 'walking', Colors.green);

  const TravelMode(this.label, this.icon, this.osrmProfile, this.color);
  final String label;
  final IconData icon;
  final String osrmProfile; // profile gửi lên OSRM
  final Color color;
}

// ════════════════════════════════════════════════════════════════════════════
//  MODEL – PlaceResult
// ════════════════════════════════════════════════════════════════════════════

class PlaceResult {
  final String name;
  final String address;
  final LatLng latLng;

  const PlaceResult({
    required this.name,
    required this.address,
    required this.latLng,
  });
}

// ════════════════════════════════════════════════════════════════════════════
//  WIDGET CHÍNH
// ════════════════════════════════════════════════════════════════════════════

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ── Map ──────────────────────────────────────────────────────────────────
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker>   _markers   = {};
  Set<Polyline> _polylines = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.7769, 106.7009),
    zoom: 12,
  );

  // ── Input ─────────────────────────────────────────────────────────────────
  final TextEditingController _startController  = TextEditingController();
  final TextEditingController _endController    = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  LatLng? _startLatLng;
  LatLng? _endLatLng;
  LatLng? _currentLatLng;

  bool _isRouteLoading   = false;
  bool _isSearchLoading  = false;
  bool _isGeocodingStart = false;
  bool _isGeocodingEnd   = false;

  String? _tapMode; // 'start' | 'end' | null

  TravelMode _travelMode = TravelMode.driving;

  List<PlaceResult> _searchResults = [];
  bool _showSearchPanel = false;

  String? _routeInfo; // "🛣️ 5.2 km  •  ⏱️ 12 phút"

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  VỊ TRÍ HIỆN TẠI
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _getCurrentLocation({bool setAsEnd = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { _showSnackBar('Vui lòng bật GPS!'); return; }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        _showSnackBar('Ứng dụng cần quyền truy cập vị trí!');
        return;
      }
    }
    if (perm == LocationPermission.deniedForever) {
      _showSnackBar('Quyền vị trí bị từ chối. Vào Settings để cấp quyền.');
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;

      final latlng    = LatLng(pos.latitude, pos.longitude);
      _currentLatLng  = latlng;
      final coordText =
          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';

      if (setAsEnd) {
        _endLatLng = latlng;
        _endController.text = coordText;
        _updateMarker(latlng, 'end', 'Đích đến (Vị trí hiện tại)',
            BitmapDescriptor.hueRed);
        _showSnackBar('Đã đặt vị trí hiện tại làm điểm đích');
        await _moveCamera(latlng);
      } else {
        _startLatLng = latlng;
        _startController.text = coordText;
        _updateMarker(latlng, 'start', 'Xuất phát (Vị trí hiện tại)',
            BitmapDescriptor.hueGreen);
        await _moveCamera(latlng, zoom: 14);
      }
    } catch (e) {
      _showSnackBar('Không lấy được vị trí: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GEOCODING – địa chỉ → tọa độ (Nominatim)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _geocodeAddress(
    TextEditingController controller,
    bool isStart,
  ) async {
    final text = controller.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Vui lòng nhập địa chỉ trước!');
      return;
    }

    // Nếu đã là tọa độ hợp lệ thì không cần geocode
    final existing = _parseLatLng(text);
    if (existing != null) {
      if (isStart) {
        _startLatLng = existing;
        _updateMarker(existing, 'start', 'Xuất phát', BitmapDescriptor.hueGreen);
      } else {
        _endLatLng = existing;
        _updateMarker(existing, 'end', 'Đích đến', BitmapDescriptor.hueRed);
      }
      await _moveCamera(existing);
      return;
    }

    setState(() {
      if (isStart) _isGeocodingStart = true;
      else         _isGeocodingEnd   = true;
    });

    try {
      final centerLat = _currentLatLng?.latitude  ?? 10.7769;
      final centerLng = _currentLatLng?.longitude ?? 106.7009;
      const delta = 1.5;

      final url = Uri.parse(
        '$_kNominatim/search'
        '?q=${Uri.encodeComponent(text)}'
        '&format=json'
        '&limit=5'
        '&viewbox=${centerLng - delta},${centerLat + delta},${centerLng + delta},${centerLat - delta}'
        '&bounded=0'
        '&addressdetails=1'
        '&accept-language=vi',
      );

      final res = await http.get(url, headers: {
        'User-Agent':      'FlutterMapApp/1.0',
        'Accept-Language': 'vi',
      }).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (res.statusCode != 200) {
        _showSnackBar('Lỗi geocoding: ${res.statusCode}');
        return;
      }

      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) {
        _showSnackBar('Không tìm thấy địa chỉ: "$text"');
        return;
      }

      // Nhiều kết quả → hiện dialog chọn
      if (list.length > 1) {
        final results = list.map((item) => PlaceResult(
              name:    item['display_name'].toString().split(',').first,
              address: item['display_name'] as String,
              latLng:  LatLng(
                double.parse(item['lat'].toString()),
                double.parse(item['lon'].toString()),
              ),
            )).toList();

        final chosen = await _showPickAddressDialog(results);
        if (chosen == null || !mounted) return;

        controller.text = chosen.address.split(',').take(3).join(',');
        if (isStart) {
          _startLatLng = chosen.latLng;
          _updateMarker(chosen.latLng, 'start', 'Xuất phát: ${chosen.name}',
              BitmapDescriptor.hueGreen);
        } else {
          _endLatLng = chosen.latLng;
          _updateMarker(chosen.latLng, 'end', 'Đích: ${chosen.name}',
              BitmapDescriptor.hueRed);
        }
        await _moveCamera(chosen.latLng);
      } else {
        // Chỉ 1 kết quả → dùng luôn
        final item   = list.first;
        final latlng = LatLng(
          double.parse(item['lat'].toString()),
          double.parse(item['lon'].toString()),
        );
        final name = item['display_name'].toString().split(',').first;

        if (isStart) {
          _startLatLng = latlng;
          _updateMarker(latlng, 'start', 'Xuất phát: $name',
              BitmapDescriptor.hueGreen);
        } else {
          _endLatLng = latlng;
          _updateMarker(latlng, 'end', 'Đích: $name',
              BitmapDescriptor.hueRed);
        }
        await _moveCamera(latlng);
        _showSnackBar('Đã tìm thấy: $name');
      }
    } on TimeoutException {
      _showSnackBar('Hết thời gian chờ. Kiểm tra kết nối!');
    } catch (e) {
      _showSnackBar('Lỗi geocoding: $e');
    } finally {
      if (mounted) setState(() {
        _isGeocodingStart = false;
        _isGeocodingEnd   = false;
      });
    }
  }

  /// Dialog chọn địa chỉ khi Nominatim trả về nhiều kết quả
  Future<PlaceResult?> _showPickAddressDialog(List<PlaceResult> results) {
    return showDialog<PlaceResult>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chọn địa chỉ'),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final r = results[i];
              return ListTile(
                leading: const Icon(Icons.place, color: Colors.orange),
                title: Text(r.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(r.address,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(ctx, r),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CLICK TRÊN BẢN ĐỒ
  // ══════════════════════════════════════════════════════════════════════════

  void _onMapTap(LatLng latlng) {
    if (_tapMode == null) return;

    final coordText =
        '${latlng.latitude.toStringAsFixed(5)}, ${latlng.longitude.toStringAsFixed(5)}';

    if (_tapMode == 'start') {
      _startLatLng = latlng;
      _startController.text = coordText;
      _updateMarker(latlng, 'start', 'Xuất phát', BitmapDescriptor.hueGreen);
      _showSnackBar('Đã chọn điểm xuất phát');
    } else {
      _endLatLng = latlng;
      _endController.text = coordText;
      _updateMarker(latlng, 'end', 'Đích đến', BitmapDescriptor.hueRed);
      _showSnackBar('Đã chọn điểm đích');
    }

    setState(() => _tapMode = null);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TÌM ĐƯỜNG ĐI (OSRM) – hỗ trợ 3 phương tiện
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _findRoute() async {
    // Nếu ô nhập là địa chỉ chưa được geocode → tự động geocode trước
    if (_startLatLng == null) {
      final parsed = _parseLatLng(_startController.text);
      if (parsed != null) {
        _startLatLng = parsed;
      } else {
        await _geocodeAddress(_startController, true);
        if (_startLatLng == null) return;
      }
    }
    if (_endLatLng == null) {
      final parsed = _parseLatLng(_endController.text);
      if (parsed != null) {
        _endLatLng = parsed;
      } else {
        await _geocodeAddress(_endController, false);
        if (_endLatLng == null) return;
      }
    }

    final start = _startLatLng!;
    final end   = _endLatLng!;

    setState(() { _isRouteLoading = true; _routeInfo = null; });

    try {
      final profile = _travelMode.osrmProfile;

      final url = Uri.parse(
        '$_kOsrmBase/$profile'
        '/${start.longitude},${start.latitude}'
        ';${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );

      final res = await http
          .get(url, headers: {'User-Agent': 'FlutterMapApp/1.0'})
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      if (res.statusCode != 200) {
        _showSnackBar('Lỗi kết nối OSRM: ${res.statusCode}');
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final code = data['code'] as String?;

      if (code != 'Ok') {
        _showSnackBar(switch (code) {
          'NoRoute'      => 'Không tìm được đường đi giữa 2 điểm!',
          'NoSegment'    => 'Tọa độ không gần đường đi nào!',
          'InvalidInput' => 'Tọa độ không hợp lệ!',
          _              => 'Lỗi OSRM: $code',
        });
        return;
      }

      final routes   = data['routes'] as List;
      final coords   = routes[0]['geometry']['coordinates'] as List;
      final points   = coords
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      final distM    = (routes[0]['distance'] as num).toDouble();
      final durS     = (routes[0]['duration'] as num).toDouble();
      final distText = distM >= 1000
          ? '${(distM / 1000).toStringAsFixed(1)} km'
          : '${distM.toStringAsFixed(0)} m';
      final durText = durS >= 3600
          ? '${(durS / 3600).toStringAsFixed(1)} giờ'
          : '${(durS / 60).toStringAsFixed(0)} phút';

      setState(() {
        _routeInfo = '🛣️ $distText  •  ⏱️ $durText';
        final others = _markers
            .where((m) =>
                m.markerId.value != 'start' && m.markerId.value != 'end')
            .toSet();
        _markers = {
          ...others,
          _buildMarker(start, 'start', 'Xuất phát', BitmapDescriptor.hueGreen),
          _buildMarker(end,   'end',   'Đích đến',  BitmapDescriptor.hueRed),
        };
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: _travelMode.color,
            width: _travelMode == TravelMode.walking ? 4 : 5,
            patterns: _travelMode == TravelMode.walking
                ? [PatternItem.dot, PatternItem.gap(8)]
                : [],
          ),
        };
      });

      await _fitBounds(start, end);
    } on TimeoutException {
      _showSnackBar('Hết thời gian chờ. Kiểm tra kết nối mạng!');
    } catch (e) {
      _showSnackBar('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isRouteLoading = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TÌM KIẾM ĐỊA ĐIỂM (NOMINATIM)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;

    setState(() { _isSearchLoading = true; _searchResults = []; });

    try {
      final centerLat = _currentLatLng?.latitude  ?? 10.7769;
      final centerLng = _currentLatLng?.longitude ?? 106.7009;
      const delta = 0.3;

      final url = Uri.parse(
        '$_kNominatim/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=10'
        '&viewbox=${centerLng - delta},${centerLat + delta},${centerLng + delta},${centerLat - delta}'
        '&bounded=0'
        '&addressdetails=1'
        '&accept-language=vi',
      );

      final res = await http.get(url, headers: {
        'User-Agent':      'FlutterMapApp/1.0',
        'Accept-Language': 'vi',
      }).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (res.statusCode != 200) {
        _showSnackBar('Lỗi tìm kiếm: ${res.statusCode}');
        return;
      }

      final list = jsonDecode(res.body) as List;
      final results = list.map((item) {
        final addr   = item['address'] as Map<String, dynamic>? ?? {};
        final road   = addr['road']   ?? addr['pedestrian'] ?? '';
        final suburb = addr['suburb'] ?? addr['quarter']    ?? '';
        final city   = addr['city']   ?? addr['town']       ?? addr['village'] ?? '';
        final addrText = [road, suburb, city]
            .where((s) => s.toString().isNotEmpty)
            .join(', ');

        return PlaceResult(
          name:    item['display_name']?.toString().split(',').first ?? query,
          address: addrText.isNotEmpty ? addrText : item['display_name'] ?? '',
          latLng:  LatLng(
            double.parse(item['lat'].toString()),
            double.parse(item['lon'].toString()),
          ),
        );
      }).toList();

      setState(() {
        _searchResults   = results;
        _showSearchPanel = true;
      });

      if (results.isEmpty) _showSnackBar('Không tìm thấy địa điểm nào!');
    } on TimeoutException {
      _showSnackBar('Hết thời gian chờ. Kiểm tra kết nối!');
    } catch (e) {
      _showSnackBar('Lỗi tìm kiếm: $e');
    } finally {
      if (mounted) setState(() => _isSearchLoading = false);
    }
  }

  void _selectSearchResult(PlaceResult place) {
    setState(() {
      _showSearchPanel = false;
      final placeMarker = _buildMarker(
        place.latLng,
        'place_${place.latLng.latitude}_${place.latLng.longitude}',
        place.name,
        BitmapDescriptor.hueOrange,
      );
      _markers = {..._markers, placeMarker};
    });
    _moveCamera(place.latLng);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            if (place.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(place.address,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.trip_origin, color: Colors.green),
                  label: const Text('Dùng làm xuất phát'),
                  onPressed: () {
                    Navigator.pop(context);
                    _startLatLng = place.latLng;
                    _startController.text = place.name;
                    _updateMarker(place.latLng, 'start',
                        'Xuất phát: ${place.name}', BitmapDescriptor.hueGreen);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.location_on),
                  label: const Text('Dùng làm đích đến'),
                  onPressed: () {
                    Navigator.pop(context);
                    _endLatLng = place.latLng;
                    _endController.text = place.name;
                    _updateMarker(place.latLng, 'end',
                        'Đích: ${place.name}', BitmapDescriptor.hueRed);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Marker _buildMarker(LatLng pos, String id, String title, double hue) =>
      Marker(
        markerId: MarkerId(id),
        position: pos,
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      );

  void _updateMarker(LatLng pos, String id, String title, double hue) {
    setState(() {
      _markers = {
        ..._markers.where((m) => m.markerId.value != id),
        _buildMarker(pos, id, title, hue),
      };
    });
  }

  Future<void> _moveCamera(LatLng pos, {double zoom = 15}) async {
    final c = await _mapController.future;
    await c.animateCamera(CameraUpdate.newLatLngZoom(pos, zoom));
  }

  Future<void> _fitBounds(LatLng a, LatLng b) async {
    final c = await _mapController.future;
    await c.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(
          a.latitude  < b.latitude  ? a.latitude  : b.latitude,
          a.longitude < b.longitude ? a.longitude : b.longitude,
        ),
        northeast: LatLng(
          a.latitude  > b.latitude  ? a.latitude  : b.latitude,
          a.longitude > b.longitude ? a.longitude : b.longitude,
        ),
      ),
      80,
    ));
  }

  LatLng? _parseLatLng(String text) {
    try {
      final parts = text.split(',');
      if (parts.length != 2) return null;
      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
      return LatLng(lat, lng);
    } catch (_) { return null; }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Finder'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showSearchPanel ? Icons.search_off : Icons.search),
            tooltip: 'Tìm kiếm địa điểm',
            onPressed: () =>
                setState(() => _showSearchPanel = !_showSearchPanel),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Panel nhập địa chỉ / tọa độ ──────────────────────────────
          _buildInputPanel(),

          // ── Thanh chọn phương tiện ────────────────────────────────────
          _buildTravelModeBar(),

          // ── Thông tin tuyến đường ─────────────────────────────────────
          if (_routeInfo != null)
            Container(
              width: double.infinity,
              color: _travelMode.color.withOpacity(0.1),
              padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_travelMode.icon, size: 18, color: _travelMode.color),
                  const SizedBox(width: 6),
                  Text(
                    _routeInfo!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _travelMode.color,
                    ),
                  ),
                ],
              ),
            ),

          // ── Panel tìm kiếm địa điểm ───────────────────────────────────
          if (_showSearchPanel) _buildSearchPanel(),

          // ── Hướng dẫn chế độ click bản đồ ────────────────────────────
          if (_tapMode != null)
            Container(
              color: Colors.amber.shade100,
              padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Row(children: [
                const Icon(Icons.touch_app, size: 18, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _tapMode == 'start'
                        ? 'Nhấn vào bản đồ để chọn điểm XUẤT PHÁT'
                        : 'Nhấn vào bản đồ để chọn điểm ĐÍCH',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _tapMode = null),
                  child: const Text('Huỷ'),
                ),
              ]),
            ),

          // ── Bản đồ ───────────────────────────────────────────────────
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              onTap: _onMapTap,
              onMapCreated: (c) {
                if (!_mapController.isCompleted) _mapController.complete(c);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Panel nhập địa chỉ / tọa độ ──────────────────────────────────────────
  Widget _buildInputPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          // Điểm xuất phát
          Row(children: [
            Expanded(
              child: TextField(
                controller: _startController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Xuất phát (địa chỉ hoặc lat, lng)',
                  hintText: '227 Nguyễn Văn Cừ, Q5 hoặc 10.7769, 106.7009',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: const Icon(Icons.trip_origin,
                      color: Colors.green, size: 20),
                  suffixIcon: _isGeocodingStart
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, size: 18),
                          tooltip: 'Tìm địa chỉ xuất phát',
                          onPressed: () =>
                              _geocodeAddress(_startController, true),
                        ),
                ),
                onSubmitted: (_) => _geocodeAddress(_startController, true),
              ),
            ),
            const SizedBox(width: 4),
            _mapTapButton('start'),
          ]),

          const SizedBox(height: 6),

          // Điểm đích
          Row(children: [
            Expanded(
              child: TextField(
                controller: _endController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Đích đến (địa chỉ hoặc lat, lng)',
                  hintText: 'Sân bay Tân Sơn Nhất hoặc 10.8231, 106.6297',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: const Icon(Icons.location_on,
                      color: Colors.red, size: 20),
                  suffixIcon: _isGeocodingEnd
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, size: 18),
                          tooltip: 'Tìm địa chỉ đích',
                          onPressed: () =>
                              _geocodeAddress(_endController, false),
                        ),
                ),
                onSubmitted: (_) => _geocodeAddress(_endController, false),
              ),
            ),
            const SizedBox(width: 4),
            _mapTapButton('end'),
            const SizedBox(width: 4),
            // Lấy vị trí hiện tại làm đích
            Tooltip(
              message: 'Lấy vị trí hiện tại làm điểm đích',
              child: InkWell(
                onTap: () => _getCurrentLocation(setAsEnd: true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Icon(Icons.my_location,
                      color: Colors.red, size: 20),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 8),

          // Nút tìm đường
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isRouteLoading ? null : _findRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: _travelMode.color,
                foregroundColor: Colors.white,
              ),
              icon: _isRouteLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_travelMode.icon),
              label: Text(_isRouteLoading ? 'Đang tìm...' : 'Tìm đường đi'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Thanh chọn phương tiện ────────────────────────────────────────────────
  Widget _buildTravelModeBar() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: TravelMode.values.map((mode) {
          final selected = _travelMode == mode;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected
                        ? mode.color.withOpacity(0.15)
                        : null,
                    foregroundColor:
                        selected ? mode.color : Colors.grey,
                    side: BorderSide(
                      color: selected ? mode.color : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 8),
                  ),
                  icon: Icon(mode.icon, size: 18),
                  label: Text(mode.label,
                      style: const TextStyle(fontSize: 12)),
                  onPressed: () => setState(() => _travelMode = mode),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Nút nhỏ bên phải ô nhập → bật chế độ click bản đồ
  Widget _mapTapButton(String mode) {
    final active = _tapMode == mode;
    return Tooltip(
      message: mode == 'start'
          ? 'Chọn điểm xuất phát trên bản đồ'
          : 'Chọn điểm đích trên bản đồ',
      child: InkWell(
        onTap: () => setState(() => _tapMode = active ? null : mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:  active ? Colors.blue.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: active ? Colors.blue : Colors.grey.shade300),
          ),
          child: Icon(Icons.touch_app,
              color: active ? Colors.blue : Colors.grey, size: 20),
        ),
      ),
    );
  }

  // ── Panel tìm kiếm địa điểm ──────────────────────────────────────────────
  Widget _buildSearchPanel() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm địa điểm...',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _isSearchLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2)),
                        )
                      : null,
                ),
                onSubmitted: _searchPlaces,
                textInputAction: TextInputAction.search,
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: () => _searchPlaces(_searchController.text),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 13),
              ),
              child: const Text('Tìm'),
            ),
          ]),

          const SizedBox(height: 8),

          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kPlaceCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = _kPlaceCategories[i];
                return ActionChip(
                  avatar: Icon(cat['icon'] as IconData, size: 16),
                  label: Text(cat['label'] as String,
                      style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    _searchController.text = cat['query'] as String;
                    _searchPlaces(cat['query'] as String);
                  },
                );
              },
            ),
          ),

          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (_, i) {
                  final pl = _searchResults[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place,
                        color: Colors.orange, size: 20),
                    title: Text(pl.name,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(pl.address,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    onTap: () => _selectSearchResult(pl),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}