# Sensor Collector — Indoor RF & Telemetry App

A Flutter Android app that continuously scans all available RF and environment sensors and streams structured JSON payloads to a configurable backend via HTTP POST or WebSocket.

## Features

| Sensor | Data Collected |
|--------|---------------|
| **Wi-Fi** | SSID, BSSID, RSSI (dBm), Frequency (MHz), Channel, Band (2.4/5 GHz) |
| **Bluetooth / BLE** | Device name, MAC/remote ID, RSSI (dBm), Service UUID, estimated distance |
| **Cellular** | Network type (LTE/5G/etc.), signal strength (dBm) |
| **Magnetometer** | Total field magnitude (µT) |
| **Light Sensor** | Ambient illuminance (lux) |
| **Battery** | Level (%), charging state |

---

## Project Structure

```
sensor_collector/
├── lib/
│   ├── main.dart                    # App entry point, routes, providers
│   ├── models/
│   │   └── sensor_payload.dart      # WifiNetwork, BleDevice, SensorPayload
│   ├── providers/
│   │   ├── config_provider.dart     # Persists user settings
│   │   └── sensor_provider.dart     # Scan engine + backend transport
│   ├── screens/
│   │   ├── permission_screen.dart   # Permission request workflow
│   │   ├── home_screen.dart         # Live dashboard
│   │   └── config_screen.dart       # Backend URL / Room ID settings
│   └── widgets/
│       ├── stat_card.dart           # Top stat row cards
│       ├── sensor_gauge.dart        # Environment reading tiles
│       ├── wifi_list_tile.dart      # Wi-Fi AP row
│       └── ble_list_tile.dart       # BLE device row
└── android/
    └── app/src/main/AndroidManifest.xml
```

---

## Prerequisites

- Flutter SDK ≥ 3.1.0
- Android SDK 34 (compile), min SDK 23 (Android 6.0)
- A physical Android device (sensors do **not** work on emulators)

---

## Installation

### 1. Create the Flutter project scaffold

```bash
flutter create --org com.example --project-name sensor_collector sensor_collector_tmp
# Then copy your lib/ and android/ files from this repo into it
# OR use the files in this directory directly if Flutter created them already
```

### 2. Install dependencies

```bash
cd sensor_collector
flutter pub get
```

### 3. Connect your Android device

Enable **Developer Options** → **USB Debugging** on your phone, then:

```bash
flutter devices        # confirm device appears
flutter run            # build & deploy
```

### 4. Build a release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Android Permission Setup

All permissions are declared in `android/app/src/main/AndroidManifest.xml` and requested at runtime by `PermissionScreen`. Here is a summary:

| Permission | Purpose | Android API |
|-----------|---------|------------|
| `ACCESS_FINE_LOCATION` | Required to read Wi-Fi scan results & BLE | All |
| `NEARBY_WIFI_DEVICES` | Wi-Fi scan without location inference | API 33+ |
| `BLUETOOTH_SCAN` | BLE scanning without location inference | API 31+ |
| `BLUETOOTH_CONNECT` | Read BLE device names | API 31+ |
| `READ_PHONE_STATE` | Cellular network info | All |
| `INTERNET` | HTTP/WS transport to backend | All |
| `ACCESS_WIFI_STATE` | Read Wi-Fi state | All |

> **Note:** `usesCleartextTraffic="true"` is set in the manifest so the app can connect to plain-text `http://` and `ws://` development servers. For production, use HTTPS/WSS and remove this flag.

---

## Backend Configuration

Open **Settings (⚙)** in the app to configure:

| Field | Example |
|-------|---------|
| Protocol | HTTP POST or WebSocket |
| Backend URL | `http://192.168.1.100:8080/api/sensor` |
| WebSocket URL | `ws://192.168.1.100:8080/ws/sensor` |
| Room ID | `Room-A` |
| Device Name | `Phone-1` |
| Polling interval | 2–30 seconds |

---

## JSON Payload Structure

```json
{
  "timestamp": 1700000000,
  "room_id": "Room-A",
  "device_name": "Phone-1",
  "wifi_networks": [
    {
      "ssid": "Home_5G",
      "bssid": "AA:BB:CC:DD:EE:FF",
      "rssi": -65,
      "frequency_mhz": 5180,
      "channel": 36,
      "band": "5GHz"
    }
  ],
  "ble_devices": [
    {
      "name": "Beacon1",
      "id": "AA:BB:CC:DD:EE:FF",
      "rssi": -72,
      "uuid": "0000180f-0000-1000-8000-00805f9b34fb"
    }
  ],
  "cell_signal_dbm": -95,
  "cell_network_type": "LTE",
  "environment": {
    "magnetic_field_ut": 45.2,
    "light_lux": 150.0
  },
  "battery_percent": 85,
  "battery_state": "charging"
}
```

---

## Minimal Python Test Server

Run this to receive and inspect payloads locally:

```python
# test_server.py
from flask import Flask, request, jsonify
import json, datetime

app = Flask(__name__)

@app.route('/api/sensor', methods=['POST'])
def receive():
    data = request.get_json()
    ts   = datetime.datetime.fromtimestamp(data.get('timestamp', 0))
    room = data.get('room_id')
    wifi = len(data.get('wifi_networks', []))
    ble  = len(data.get('ble_devices', []))
    print(f"[{ts}] {room} | Wi-Fi: {wifi}  BLE: {ble}  Cell: {data.get('cell_signal_dbm')} dBm")
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
```

```bash
pip install flask
python test_server.py
```

Point the app to `http://<your-PC-IP>:8080/api/sensor` (must be on the same Wi-Fi network).

---

## Minimal Node.js WebSocket Server

```js
// ws_server.js
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', ws => {
  console.log('Client connected');
  ws.on('message', msg => {
    const data = JSON.parse(msg);
    console.log(`[${data.room_id}] Wi-Fi: ${data.wifi_networks.length}  BLE: ${data.ble_devices.length}`);
  });
});
console.log('WS server on ws://0.0.0.0:8080');
```

```bash
npm install ws
node ws_server.js
```

---

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| Wi-Fi list empty | Grant Location permission; on Android 10+ location must be ON |
| BLE list empty | Grant Bluetooth Scan + Location; ensure Bluetooth is enabled |
| "Connection failed" | Check device and backend are on the same network; use IP not hostname |
| Cleartext error | Add `android:usesCleartextTraffic="true"` (already set) or use HTTPS |
| `minSdkVersion` error | Ensure `minSdkVersion 23` in `android/app/build.gradle` |

---

## License

MIT — free for personal and commercial use.

