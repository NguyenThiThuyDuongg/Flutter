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

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  LatLng? _currentPosition;

  final LatLng _destination = const LatLng(10.7769, 106.7009); // TP.HCM

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.7769, 106.7009),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 📍 Lấy vị trí hiện tại
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng bật GPS!')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);

      _addMarker(_currentPosition!, "Vị trí của bạn");
      _moveCamera(_currentPosition!);
    });
  }

  // 📌 Thêm marker
  void _addMarker(LatLng position, String id) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: position,
          infoWindow: InfoWindow(title: id),
        ),
      );
    });
  }

  // 🎥 Move camera
  Future<void> _moveCamera(LatLng position) async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  // 🛣️ Lấy đường đi Google Directions API
  Future<void> _getDirections() async {
    if (_currentPosition == null) return;

    const apiKey = "YOUR_API_KEY_HERE";

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${_currentPosition!.latitude},${_currentPosition!.longitude}"
        "&destination=${_destination.latitude},${_destination.longitude}"
        "&key=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["routes"].isNotEmpty) {
        final polyline = data["routes"][0]["overview_polyline"]["points"];
        final points = _decodePolyline(polyline);

        setState(() {
          _polylines.clear();

          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              points: points,
              color: Colors.blue,
              width: 5,
            ),
          );

          _addMarker(_destination, "Điểm đến");
        });
      } else {
        _showMsg("Không tìm thấy đường đi!");
      }
    } else {
      _showMsg("Lỗi API: ${response.statusCode}");
    }
  }

  // 🔓 Decode polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0, b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Map Navigator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.alt_route),
            onPressed: _getDirections,
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (controller) {
          _controller.complete(controller);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}