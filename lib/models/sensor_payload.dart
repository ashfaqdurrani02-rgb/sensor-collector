// ============================================================
//  models/sensor_payload.dart
//  Data models for the RF & Sensor telemetry JSON payload.
// ============================================================

/// Represents a single Wi-Fi access point from a scan result.
class WifiNetwork {
  final String ssid;
  final String bssid;
  final int rssi; // in dBm
  final int frequencyMhz;
  final int channel;

  const WifiNetwork({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.frequencyMhz,
    required this.channel,
  });

  String get band => frequencyMhz >= 5000 ? '5GHz' : '2.4GHz';

  Map<String, dynamic> toJson() => {
        'ssid': ssid,
        'bssid': bssid,
        'rssi': rssi,
        'frequency_mhz': frequencyMhz,
        'channel': channel,
        'band': band,
      };
}

/// Represents a nearby Bluetooth / BLE device.
class BleDevice {
  final String name;
  final String id; // MAC address / remote ID
  final int rssi; // in dBm
  final String? uuid; // primary service UUID if available

  const BleDevice({
    required this.name,
    required this.id,
    required this.rssi,
    this.uuid,
  });

  Map<String, dynamic> toJson() => {
        'name': name.isEmpty ? 'Unknown' : name,
        'id': id,
        'rssi': rssi,
        'uuid': uuid ?? '',
      };
}

/// Magnetometer + Light sensor readings.
class EnvironmentData {
  final double magneticFieldUt; // magnitude in µT
  final double lightLux; // ambient light in lux

  const EnvironmentData({
    required this.magneticFieldUt,
    required this.lightLux,
  });

  Map<String, dynamic> toJson() => {
        'magnetic_field_ut': magneticFieldUt,
        'light_lux': lightLux,
      };
}

/// Top-level telemetry packet sent to the backend.
class SensorPayload {
  final int timestamp; // Unix epoch seconds
  final String roomId;
  final String deviceName;
  final List<WifiNetwork> wifiNetworks;
  final List<BleDevice> bleDevices;
  final int? cellSignalDbm;
  final String? cellNetworkType;
  final EnvironmentData environment;
  final int batteryPercent;
  final String batteryState;

  const SensorPayload({
    required this.timestamp,
    required this.roomId,
    required this.deviceName,
    required this.wifiNetworks,
    required this.bleDevices,
    this.cellSignalDbm,
    this.cellNetworkType,
    required this.environment,
    required this.batteryPercent,
    required this.batteryState,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'room_id': roomId,
        'device_name': deviceName,
        'wifi_networks': wifiNetworks.map((w) => w.toJson()).toList(),
        'ble_devices': bleDevices.map((b) => b.toJson()).toList(),
        'cell_signal_dbm': cellSignalDbm,
        'cell_network_type': cellNetworkType,
        'environment': environment.toJson(),
        'battery_percent': batteryPercent,
        'battery_state': batteryState,
      };
}

