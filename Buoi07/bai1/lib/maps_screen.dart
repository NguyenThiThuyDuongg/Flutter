import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  bool _isLoading = false;

  // OSRM public server - hoàn toàn miễn phí, không cần API key
  // Lưu ý: OSRM nhận tọa độ theo thứ tự lng,lat (khác Google Maps)
  static const String _osrmBase = 'https://router.project-osrm.org/route/v1/driving';

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.7769, 106.7009), // TP.HCM
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  // Lấy vị trí hiện tại
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Vui lòng bật GPS!');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Ứng dụng cần quyền truy cập vị trí!');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Quyền vị trí bị từ chối vĩnh viễn. Vào Settings để cấp quyền.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;

      final current = LatLng(position.latitude, position.longitude);
      _startController.text =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      setState(() {
        _markers = {
          _buildMarker(current, 'start', 'Xuất phát', BitmapDescriptor.hueGreen),
        };
      });

      await _moveCamera(current, zoom: 14);
    } catch (e) {
      _showSnackBar('Không lấy được vị trí: $e');
    }
  }

  // Helper tạo Marker
  Marker _buildMarker(LatLng position, String id, String title, double hue) {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(title: title),
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
    );
  }

  // Di chuyển camera
  Future<void> _moveCamera(LatLng position, {double zoom = 14}) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
  }

  // Zoom vừa khít cả 2 điểm
  Future<void> _fitBounds(LatLng start, LatLng end) async {
    final GoogleMapController controller = await _controller.future;
    final southwest = LatLng(
      start.latitude < end.latitude ? start.latitude : end.latitude,
      start.longitude < end.longitude ? start.longitude : end.longitude,
    );
    final northeast = LatLng(
      start.latitude > end.latitude ? start.latitude : end.latitude,
      start.longitude > end.longitude ? start.longitude : end.longitude,
    );
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southwest, northeast: northeast),
        80,
      ),
    );
  }

  // Parse tọa độ từ chuỗi "lat, lng"
  LatLng? _parseLatLng(String text) {
    try {
      final parts = text.split(',');
      if (parts.length != 2) return null;
      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }

  // ── OSRM: Giải mã geometry dạng GeoJSON coordinates ──────────────────────
  // OSRM trả về danh sách [lng, lat] (GeoJSON format) khi dùng geometries=geojson
  List<LatLng> _parseGeoJsonCoordinates(List coords) {
    return coords.map((c) {
      final lng = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      return LatLng(lat, lng);
    }).toList();
  }

  // ── Tìm đường đi qua OSRM ────────────────────────────────────────────────
  Future<void> _findRoute() async {
    final startText = _startController.text.trim();
    final endText = _endController.text.trim();

    if (startText.isEmpty || endText.isEmpty) {
      _showSnackBar('Vui lòng nhập cả điểm xuất phát và điểm đích!');
      return;
    }

    final start = _parseLatLng(startText);
    final end = _parseLatLng(endText);

    if (start == null) {
      _showSnackBar('Tọa độ xuất phát không hợp lệ!\nVí dụ: 10.7769, 106.7009');
      return;
    }
    if (end == null) {
      _showSnackBar('Tọa độ đích không hợp lệ!\nVí dụ: 10.8231, 106.6297');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // OSRM format: /route/v1/driving/{lng_start},{lat_start};{lng_end},{lat_end}
      // Lưu ý: OSRM dùng lng trước, lat sau (ngược với Google Maps)
      final url = Uri.parse(
        '$_osrmBase'
        '/${start.longitude},${start.latitude}'   // điểm xuất phát: lng,lat
        ';${end.longitude},${end.latitude}'        // điểm đích: lng,lat
        '?overview=full'                           // lấy toàn bộ polyline
        '&geometries=geojson'                      // định dạng GeoJSON cho dễ parse
        '&steps=false',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterApp/1.0'}, // OSRM yêu cầu User-Agent
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode != 200) {
        _showSnackBar('Lỗi kết nối OSRM: ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final code = data['code'] as String?;

      if (code != 'Ok') {
        final message = switch (code) {
          'NoRoute'        => 'Không tìm được đường đi giữa 2 điểm!',
          'NoSegment'      => 'Tọa độ không gần đường đi nào!',
          'InvalidInput'   => 'Tọa độ không hợp lệ!',
          _                => 'Lỗi OSRM: $code',
        };
        _showSnackBar(message);
        return;
      }

      final routes = data['routes'] as List;
      if (routes.isEmpty) {
        _showSnackBar('Không tìm thấy tuyến đường nào!');
        return;
      }

      // Lấy danh sách tọa độ từ GeoJSON
      final coords = routes[0]['geometry']['coordinates'] as List;
      final points = _parseGeoJsonCoordinates(coords);

      // Lấy khoảng cách (mét) và thời gian (giây) từ OSRM
      final distanceM = (routes[0]['distance'] as num).toDouble();
      final durationS = (routes[0]['duration'] as num).toDouble();

      final distanceText = distanceM >= 1000
          ? '${(distanceM / 1000).toStringAsFixed(1)} km'
          : '${distanceM.toStringAsFixed(0)} m';
      final durationText = durationS >= 3600
          ? '${(durationS / 3600).toStringAsFixed(1)} giờ'
          : '${(durationS / 60).toStringAsFixed(0)} phút';

      setState(() {
        _markers = {
          _buildMarker(start, 'start', 'Xuất phát', BitmapDescriptor.hueGreen),
          _buildMarker(end, 'end', 'Đích đến', BitmapDescriptor.hueRed),
        };
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 5,
          ),
        };
      });

      await _fitBounds(start, end);
      _showSnackBar('🛣️ $distanceText  •  ⏱️ $durationText');
    } on TimeoutException {
      _showSnackBar('Hết thời gian chờ. Kiểm tra kết nối mạng!');
    } catch (e) {
      _showSnackBar('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Finder'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Column(
              children: [
                TextField(
                  controller: _startController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Điểm xuất phát (lat, lng)',
                    hintText: 'Ví dụ: 10.7769, 106.7009',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trip_origin, color: Colors.green),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _endController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Điểm đích (lat, lng)',
                    hintText: 'Ví dụ: 10.8231, 106.6297',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _findRoute,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.directions),
                    label: Text(_isLoading ? 'Đang tìm...' : 'Tìm đường đi'),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}