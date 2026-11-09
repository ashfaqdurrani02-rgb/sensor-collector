// ============================================================
//  providers/config_provider.dart
//  Persists user configuration: backend URL, room ID, etc.
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigProvider extends ChangeNotifier {
  // ── Storage keys ──────────────────────────────────────────
  static const _kUrl      = 'backend_url';
  static const _kRoom     = 'room_id';
  static const _kDevice   = 'device_name';
  static const _kInterval = 'polling_interval';
  static const _kUseWs    = 'use_websocket';

  // ── Defaults ──────────────────────────────────────────────
  String _backendUrl       = 'http://192.168.1.100:8080/api/sensor';
  String _roomId           = 'Room-A';
  String _deviceName       = 'Phone-1';
  int    _pollingInterval  = 3; // seconds (range 2–30)
  bool   _useWebSocket     = false;

  // ── Getters ───────────────────────────────────────────────
  String get backendUrl      => _backendUrl;
  String get roomId          => _roomId;
  String get deviceName      => _deviceName;
  int    get pollingInterval => _pollingInterval;
  bool   get useWebSocket    => _useWebSocket;

  ConfigProvider() {
    _load();
  }

  // ── Load from SharedPreferences ───────────────────────────
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _backendUrl      = p.getString(_kUrl)      ?? _backendUrl;
    _roomId          = p.getString(_kRoom)     ?? _roomId;
    _deviceName      = p.getString(_kDevice)   ?? _deviceName;
    _pollingInterval = p.getInt(_kInterval)    ?? _pollingInterval;
    _useWebSocket    = p.getBool(_kUseWs)      ?? _useWebSocket;
    notifyListeners();
  }

  // ── Persist changes ───────────────────────────────────────
  Future<void> save({
    required String backendUrl,
    required String roomId,
    required String deviceName,
    required int    pollingInterval,
    required bool   useWebSocket,
  }) async {
    _backendUrl      = backendUrl;
    _roomId          = roomId;
    _deviceName      = deviceName;
    _pollingInterval = pollingInterval.clamp(2, 30);
    _useWebSocket    = useWebSocket;

    final p = await SharedPreferences.getInstance();
    await p.setString(_kUrl,      _backendUrl);
    await p.setString(_kRoom,     _roomId);
    await p.setString(_kDevice,   _deviceName);
    await p.setInt(_kInterval,    _pollingInterval);
    await p.setBool(_kUseWs,      _useWebSocket);
    notifyListeners();
  }
}

