import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../domain/entities/app_notification.dart';

/// Sends driver GPS location to the server via Socket.IO `/drivers` namespace
/// and receives real-time notifications for the driver.
///
/// Call [connect] after login to join the driver notification room (no GPS).
/// Call [start] when an active booking exists to begin GPS tracking.
/// Call [stop] when the booking ends (GPS stops, socket stays connected).
/// Call [disconnect] on logout (full cleanup).
class DriverLocationService {
  DriverLocationService({
    required String socketUrl,
    String? socketPath,
  })  : _socketUrl = socketUrl,
        _socketPath = socketPath;

  final String _socketUrl;
  final String? _socketPath;

  io.Socket? _socket;
  StreamSubscription<Position>? _positionSub;
  String? _driverId;
  Position? _lastPosition;

  final _notificationCtrl = StreamController<AppNotification>.broadcast();

  /// Stream of real-time notifications received from the server.
  Stream<AppNotification> get notificationStream => _notificationCtrl.stream;

  /// Whether location tracking (GPS) is currently active.
  bool get isTracking => _positionSub != null;

  /// Last known driver position, or null if tracking has not started.
  Position? get lastPosition => _lastPosition;

  /// Connect socket and join the driver notification room (no GPS).
  /// Safe to call multiple times — no-ops if already connected for same driver.
  Future<void> connect(String driverId) async {
    if (_socket != null && _socket!.connected && _driverId == driverId) return;
    _driverId = driverId;
    _connectSocket();
  }

  /// Start GPS tracking and emit location updates.
  /// Calls [connect] internally if socket is not already up.
  Future<void> start(String driverId, {int intervalSeconds = 10}) async {
    if (_positionSub != null && _driverId == driverId) return; // already tracking
    // If switching driver, clean up GPS first (keep socket if same driver)
    if (_positionSub != null) {
      _positionSub?.cancel();
      _positionSub = null;
    }

    // Request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return; // Can't track without permission
      }
    }

    // Connect socket if not already connected for this driver
    if (_socket == null || !_socket!.connected || _driverId != driverId) {
      await connect(driverId);
    } else {
      _driverId = driverId;
    }

    // Send initial position
    await _emitCurrentPosition();

    // Start continuous position stream (works in background)
    late final LocationSettings locationSettings;
    if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: Duration(seconds: intervalSeconds),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'TowFactory Driver',
          notificationText: 'Sharing your location with customers',
          enableWakeLock: true,
        ),
      );
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _lastPosition = position;
        _emitPosition(position);
      },
      onError: (e) {
        if (kDebugMode) print('[DriverLocation] stream error: $e');
      },
    );
  }

  /// Stop GPS tracking and notify server driver is offline.
  /// Socket stays connected so notifications keep arriving.
  void stop() {
    _positionSub?.cancel();
    _positionSub = null;

    if (_driverId != null && _socket != null && _socket!.connected) {
      _socket!.emit('driverOffline', {'driverId': _driverId});
    }

    _lastPosition = null;
    // Socket intentionally kept alive for notifications
  }

  /// Full disconnect on logout — stops GPS, notifies server, disconnects socket.
  void disconnect() {
    _positionSub?.cancel();
    _positionSub = null;

    if (_driverId != null && _socket != null && _socket!.connected) {
      _socket!.emit('driverOffline', {'driverId': _driverId});
    }

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _driverId = null;
    _lastPosition = null;
  }

  void _connectSocket() {
    _socket?.disconnect();
    _socket?.dispose();

    final optionBuilder = io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(double.maxFinite.toInt())
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(30000);

    if (_socketPath != null && _socketPath!.isNotEmpty) {
      optionBuilder.setPath(_socketPath!);
    }

    _socket = io.io(_socketUrl, optionBuilder.build());

    _socket!.onConnect((_) {
      if (kDebugMode) print('[DriverLocation] socket connected');
      // Join driver notification room
      if (_driverId != null) {
        _socket!.emit('joinDriverRoom', {'driverId': _driverId});
      }
      // Re-send last known position on reconnect (only when GPS is active)
      if (_positionSub != null) {
        if (_lastPosition != null) {
          _emitPosition(_lastPosition!);
        } else {
          _emitCurrentPosition();
        }
      }
    });

    // Forward server notifications to the broadcast stream
    _socket!.on('newNotification', (data) {
      try {
        final map = Map<String, dynamic>.from(data as Map);
        final notification = AppNotification.fromJson(map);
        _notificationCtrl.add(notification);
      } catch (e) {
        if (kDebugMode) print('[DriverLocation] newNotification parse error: $e');
      }
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) print('[DriverLocation] socket disconnected');
    });

    _socket!.onError((data) {
      if (kDebugMode) print('[DriverLocation] socket error: $data');
    });
  }

  void _emitPosition(Position position) {
    if (_socket == null || _driverId == null) return;
    _socket!.emit('updateLocation', {
      'driverId': _driverId,
      'truckNumber': '',
      'lat': position.latitude,
      'lng': position.longitude,
      'heading': position.heading,
      'speed': position.speed,
    });
    if (kDebugMode) {
      print('[DriverLocation] emitted: ${position.latitude}, ${position.longitude}');
    }
  }

  Future<void> _emitCurrentPosition() async {
    if (_socket == null || _driverId == null) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      _lastPosition = position;
      _emitPosition(position);
    } catch (e) {
      if (kDebugMode) print('[DriverLocation] getCurrentPosition error: $e');
    }
  }
}
