// ============================================================
//  providers/sensor_provider.dart
//  Core engine: collects all sensor data and streams to backend.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/sensor_payload.dart';

class SensorProvider extends ChangeNotifier {
  // ── Public state ──────────────────────────────────────────
  bool   _isScanning       = false;
  int    _packetsSent      = 0;
  int    _packetsError     = 0;
  String _statusMessage    = 'Idle — tap START to begin';
  String _connectionStatus = 'Disconnected';
  String _lastError        = '';

  // Live sensor snapshots
  List<WifiNetwork> _wifiNetworks  = [];
  List<BleDevice>   _bleDevices    = [];
  int?   _cellSignalDbm;
  String? _cellNetworkType;
  double  _magneticFieldUt = 0.0;
  double  _lightLux        = 0.0;
  int     _batteryPercent  = 0;
  String  _batteryState    = 'unknown';

  SensorPayload? _lastPayload;

  // ── Getters ───────────────────────────────────────────────
  bool              get isScanning       => _isScanning;
  int               get packetsSent      => _packetsSent;
  int               get packetsError     => _packetsError;
  String            get statusMessage    => _statusMessage;
  String            get connectionStatus => _connectionStatus;
  String            get lastError        => _lastError;
  List<WifiNetwork> get wifiNetworks     => _wifiNetworks;
  List<BleDevice>   get bleDevices       => _bleDevices;
  int?              get cellSignalDbm    => _cellSignalDbm;
  String?           get cellNetworkType  => _cellNetworkType;
  double            get magneticFieldUt  => _magneticFieldUt;
  double            get lightLux         => _lightLux;
  int               get batteryPercent   => _batteryPercent;
  String            get batteryState     => _batteryState;
  SensorPayload?    get lastPayload      => _lastPayload;

  // ── Private internals ─────────────────────────────────────
  Timer?                              _scanTimer;
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<List<ScanResult>>?  _bleSub;
  WebSocketChannel?                   _wsChannel;
  final Battery                       _battery = Battery();

  // Accumulate BLE devices by remoteId so they persist between scan windows
  final Map<String, BleDevice> _bleMap = {};

  // ── Public API ────────────────────────────────────────────

  /// Toggle scanning on/off.
  Future<void> toggleScanning({
    required String backendUrl,
    required String roomId,
    required String deviceName,
    required int    intervalSec,
    required bool   useWebSocket,
  }) async {
    if (_isScanning) {
      await _stopScanning();
    } else {
      await _startScanning(
        backendUrl:   backendUrl,
        roomId:       roomId,
        deviceName:   deviceName,
        intervalSec:  intervalSec,
        useWebSocket: useWebSocket,
      );
    }
  }

  // ── Start ─────────────────────────────────────────────────
  Future<void> _startScanning({
    required String backendUrl,
    required String roomId,
    required String deviceName,
    required int    intervalSec,
    required bool   useWebSocket,
  }) async {
    _isScanning    = true;
    _statusMessage = 'Initialising sensors…';
    _packetsError  = 0;
    notifyListeners();

    // 1. Start continuous sensor streams
    _startMagnetometerStream();
    _startBleStream();

    // 2. Connect WebSocket if chosen
    if (useWebSocket) _connectWebSocket(backendUrl);

    // 3. Immediate first collect
    await _collectAndSend(
      backendUrl:   backendUrl,
      roomId:       roomId,
      deviceName:   deviceName,
      useWebSocket: useWebSocket,
    );

    // 4. Periodic loop
    _scanTimer = Timer.periodic(
      Duration(seconds: intervalSec),
      (_) => _collectAndSend(
        backendUrl:   backendUrl,
        roomId:       roomId,
        deviceName:   deviceName,
        useWebSocket: useWebSocket,
      ),
    );

    _statusMessage = 'Scanning every ${intervalSec}s → $roomId';
    notifyListeners();
  }

  // ── Stop ──────────────────────────────────────────────────
  Future<void> _stopScanning() async {
    _scanTimer?.cancel();
    _scanTimer = null;

    await _magSub?.cancel();
    _magSub = null;

    await _bleSub?.cancel();
    _bleSub = null;

    try { await FlutterBluePlus.stopScan(); } catch (_) {}

    _wsChannel?.sink.close();
    _wsChannel = null;

    _isScanning       = false;
    _connectionStatus = 'Disconnected';
    _statusMessage    = 'Stopped';
    notifyListeners();
  }

  // ── Wi-Fi ─────────────────────────────────────────────────
  Future<void> _scanWifi() async {
    try {
      final can = await WiFiScan.instance.canStartScan(askPermissions: false);
      if (can == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
      }
      final results = await WiFiScan.instance.getScannedResults();
      _wifiNetworks = results
          .map((ap) => WifiNetwork(
                ssid:         ap.ssid,
                bssid:        ap.bssid,
                rssi:         ap.level,
                frequencyMhz: ap.frequency,
                channel:      _freqToChannel(ap.frequency),
              ))
          .toList()
        // Sort strongest first
        ..sort((a, b) => b.rssi.compareTo(a.rssi));
    } catch (e) {
      _wifiNetworks = [];
    }
  }

  int _freqToChannel(int freq) {
    if (freq >= 2412 && freq <= 2484) return (freq - 2412) ~/ 5 + 1;
    if (freq >= 5170 && freq <= 5825) return (freq - 5170) ~/ 5 + 34;
    return 0;
  }

  // ── BLE ───────────────────────────────────────────────────
  void _startBleStream() {
    try {
      _bleSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final adv  = r.advertisementData;
          final uuid = adv.serviceUuids.isNotEmpty
              ? adv.serviceUuids.first.toString()
              : null;
          final name = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : adv.advName;
          _bleMap[r.device.remoteId.toString()] = BleDevice(
            name: name,
            id:   r.device.remoteId.toString(),
            rssi: r.rssi,
            uuid: uuid,
          );
        }
        _bleDevices = _bleMap.values.toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));
        notifyListeners();
      });

      FlutterBluePlus.startScan(
        timeout:           const Duration(seconds: 60),
        continuousUpdates: true,
      ).onError((_, __) {});
    } catch (_) {}
  }

  // ── Magnetometer ──────────────────────────────────────────
  void _startMagnetometerStream() {
    try {
      _magSub = magnetometerEventStream(
        samplingPeriod: SensorInterval.normalInterval,
      ).listen((e) {
        _magneticFieldUt = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      });
    } catch (_) {}
  }

  // ── Battery ───────────────────────────────────────────────
  Future<void> _updateBattery() async {
    try {
      _batteryPercent = await _battery.batteryLevel;
      final s         = await _battery.batteryState;
      _batteryState   = s.name;
    } catch (_) {}
  }

  // ── Collect & Send ────────────────────────────────────────
  Future<void> _collectAndSend({
    required String backendUrl,
    required String roomId,
    required String deviceName,
    required bool   useWebSocket,
  }) async {
    await Future.wait([_scanWifi(), _updateBattery()]);

    final payload = SensorPayload(
      timestamp:       DateTime.now().millisecondsSinceEpoch ~/ 1000,
      roomId:          roomId,
      deviceName:      deviceName,
      wifiNetworks:    List.from(_wifiNetworks),
      bleDevices:      List.from(_bleDevices),
      cellSignalDbm:   _cellSignalDbm,
      cellNetworkType: _cellNetworkType,
      environment: EnvironmentData(
        magneticFieldUt: double.parse(_magneticFieldUt.toStringAsFixed(2)),
        lightLux:        _lightLux,
      ),
      batteryPercent: _batteryPercent,
      batteryState:   _batteryState,
    );

    _lastPayload = payload;
    notifyListeners();

    final json = jsonEncode(payload.toJson());

    if (useWebSocket && _wsChannel != null) {
      await _sendWebSocket(json);
    } else {
      await _sendHttp(backendUrl, json);
    }
  }

  // ── HTTP POST ─────────────────────────────────────────────
  Future<void> _sendHttp(String url, String body) async {
    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body:    body,
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        _packetsSent++;
        _connectionStatus = 'HTTP ${res.statusCode} OK';
        _lastError = '';
      } else {
        _packetsError++;
        _connectionStatus = 'HTTP ${res.statusCode} Error';
        _lastError = 'Server returned ${res.statusCode}';
      }
    } catch (e) {
      _packetsError++;
      _connectionStatus = 'Connection failed';
      _lastError = e.toString().split('\n').first;
    }
    notifyListeners();
  }

  // ── WebSocket send ────────────────────────────────────────
  Future<void> _sendWebSocket(String body) async {
    try {
      _wsChannel!.sink.add(body);
      _packetsSent++;
      _connectionStatus = 'WS Connected';
      _lastError = '';
    } catch (e) {
      _packetsError++;
      _connectionStatus = 'WS Error';
      _lastError = e.toString().split('\n').first;
      _wsChannel = null; // force reconnect next cycle
    }
    notifyListeners();
  }

  // ── WebSocket connect ─────────────────────────────────────
  void _connectWebSocket(String url) {
    try {
      // Normalize http(s) → ws(s)
      final wsUrl = url
          .replaceFirst(RegExp(r'^https://'), 'wss://')
          .replaceFirst(RegExp(r'^http://'),  'ws://');
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _connectionStatus = 'WS Connecting…';

      // Listen for server messages / errors
      _wsChannel!.stream.listen(
        (_) {},
        onError: (e) {
          _connectionStatus = 'WS Disconnected';
          _wsChannel = null;
          notifyListeners();
        },
        onDone: () {
          _connectionStatus = 'WS Closed';
          _wsChannel = null;
          notifyListeners();
        },
      );
    } catch (e) {
      _connectionStatus = 'WS Connect Failed';
      _lastError = e.toString().split('\n').first;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stopScanning();
    super.dispose();
  }
}

