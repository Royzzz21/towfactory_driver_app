import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class EtaResult {
  final String duration; // e.g. "12 mins"
  final String distance; // e.g. "3.2 km"

  const EtaResult({required this.duration, required this.distance});
}

class EtaService {
  static final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// Returns [EtaResult] from the driver's current GPS location to [destLat]/[destLng].
  ///
  /// Pass [knownPosition] (e.g. from [DriverLocationService.lastPosition]) to skip
  /// a fresh GPS fix — useful when the tracker is already running.
  /// Falls back to [Geolocator.getCurrentPosition] if not provided.
  static Future<EtaResult?> getEta({
    required double destLat,
    required double destLng,
    Position? knownPosition,
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint('[EtaService] No API key');
      return null;
    }

    Position? position = knownPosition;

    if (position == null) {
      // Check & request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[EtaService] Location permission denied: $permission');
        return null;
      }

      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    }

    final origin = '${position.latitude},${position.longitude}';
    final destination = '$destLat,$destLng';

    debugPrint('[EtaService] origin=$origin destination=$destination');

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$origin&destination=$destination&key=$_apiKey',
    );

    final response = await http.get(uri);
    debugPrint('[EtaService] HTTP ${response.statusCode}');
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map<String, dynamic>;
    debugPrint('[EtaService] API status=${data['status']} error_message=${data['error_message']}');
    if (data['status'] != 'OK') return null;

    final leg = (data['routes'] as List?)?.first?['legs']?[0];
    if (leg == null) {
      debugPrint('[EtaService] No leg in response');
      return null;
    }

    final duration = leg['duration']?['text'] as String? ?? '';
    final distance = leg['distance']?['text'] as String? ?? '';

    debugPrint('[EtaService] duration=$duration distance=$distance');
    if (duration.isEmpty) return null;
    return EtaResult(duration: duration, distance: distance);
  }
}
