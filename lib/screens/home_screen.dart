// ============================================================
//  screens/home_screen.dart
//  Live dashboard: scan toggle, stat cards, Wi-Fi & BLE lists.
// ============================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/sensor_provider.dart';
import '../providers/config_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/sensor_gauge.dart';
import '../widgets/wifi_list_tile.dart';
import '../widgets/ble_list_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorProvider>();
    final config = context.watch<ConfigProvider>();
    final theme  = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: Row(
          children: [
            Icon(Icons.sensors, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text('Sensor Collector',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        actions: [
          // Connection status chip
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sensor.isScanning
                      ? Colors.green.withOpacity(0.18)
                      : Colors.red.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sensor.isScanning ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sensor.isScanning ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      sensor.isScanning ? 'ACTIVE' : 'IDLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            sensor.isScanning ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/config'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Scan toggle button ──────────────────────
                  _ScanButton(sensor: sensor, config: config),
                  const SizedBox(height: 8),

                  // ── Status line ─────────────────────────────
                  Row(children: [
                    Icon(Icons.info_outline,
                        size: 13,
                        color: theme.colorScheme.primary.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${sensor.statusMessage}  •  ${config.roomId}  •  ${config.pollingInterval}s interval',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),

                  if (sensor.lastError.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.error_outline,
                          size: 13, color: Colors.orange),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          sensor.lastError,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.orange),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 14),

                  // ── Top stat cards ──────────────────────────
                  Row(children: [
                    Expanded(
                      child: StatCard(
                        label: 'Packets Sent',
                        value: '${sensor.packetsSent}',
                        icon: Icons.upload_rounded,
                        color: Colors.cyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        label: 'Errors',
                        value: '${sensor.packetsError}',
                        icon: Icons.error_outline,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        label: 'Wi-Fi APs',
                        value: '${sensor.wifiNetworks.length}',
                        icon: Icons.wifi,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        label: 'BLE',
                        value: '${sensor.bleDevices.length}',
                        icon: Icons.bluetooth,
                        color: Colors.purple,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),

                  // ── Environment gauges ──────────────────────
                  Row(children: [
                    Expanded(
                      child: SensorGauge(
                        label: 'Magnetic',
                        value:
                            '${sensor.magneticFieldUt.toStringAsFixed(1)} µT',
                        icon: Icons.explore,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SensorGauge(
                        label: 'Cell Signal',
                        value: sensor.cellSignalDbm != null
                            ? '${sensor.cellSignalDbm} dBm'
                            : 'N/A',
                        icon: Icons.signal_cellular_alt,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SensorGauge(
                        label: 'Battery',
                        value: '${sensor.batteryPercent}%',
                        icon: Icons.battery_std,
                        color: Colors.lightGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SensorGauge(
                        label: 'Light',
                        value:
                            '${sensor.lightLux.toStringAsFixed(0)} lx',
                        icon: Icons.light_mode,
                        color: Colors.yellow,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 18),
                  _SectionHeader(
                    icon: Icons.wifi,
                    label:
                        'Wi-Fi Networks (${sensor.wifiNetworks.length})',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          // ── Wi-Fi list ────────────────────────────────────
          if (sensor.wifiNetworks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _EmptyHint(
                    icon: Icons.wifi_off,
                    text: sensor.isScanning
                        ? 'Scanning for Wi-Fi…'
                        : 'Press START to scan'),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  child: WifiListTile(network: sensor.wifiNetworks[i]),
                ),
                childCount: sensor.wifiNetworks.length,
              ),
            ),

          // ── BLE section header ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
              child: _SectionHeader(
                icon:  Icons.bluetooth,
                label: 'BLE Devices (${sensor.bleDevices.length})',
                color: Colors.purple,
              ),
            ),
          ),

          // ── BLE list ──────────────────────────────────────
          if (sensor.bleDevices.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _EmptyHint(
                    icon: Icons.bluetooth_disabled,
                    text: sensor.isScanning
                        ? 'Scanning for BLE…'
                        : 'Press START to scan'),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  child: BleListTile(device: sensor.bleDevices[i]),
                ),
                childCount: sensor.bleDevices.length,
              ),
            ),

          // ── Last payload JSON viewer ──────────────────────
          if (sensor.lastPayload != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                child: _SectionHeader(
                    icon: Icons.data_object,
                    label: 'Last Payload JSON',
                    color: Colors.teal),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                child: _JsonViewer(payload: sensor.lastPayload!),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ── Scan toggle button ────────────────────────────────────────
class _ScanButton extends StatelessWidget {
  final SensorProvider sensor;
  final ConfigProvider config;
  const _ScanButton({required this.sensor, required this.config});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => sensor.toggleScanning(
          backendUrl:   config.backendUrl,
          roomId:       config.roomId,
          deviceName:   config.deviceName,
          intervalSec:  config.pollingInterval,
          useWebSocket: config.useWebSocket,
        ),
        icon:  Icon(sensor.isScanning ? Icons.stop_circle_outlined : Icons.play_circle_outlined, size: 22),
        label: Text(
          sensor.isScanning ? 'STOP SCANNING' : 'START SCANNING',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        style: FilledButton.styleFrom(
          backgroundColor:
              sensor.isScanning ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withOpacity(0.3))),
      ],
    );
  }
}

// ── Empty hint ────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ]),
    );
  }
}

// ── Last payload JSON viewer ──────────────────────────────────
class _JsonViewer extends StatelessWidget {
  final dynamic payload;
  const _JsonViewer({required this.payload});

  @override
  Widget build(BuildContext context) {
    final encoder = const JsonEncoder.withIndent('  ');
    final text    = encoder.convert(payload.toJson());
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON copied to clipboard')),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.teal.withOpacity(0.25)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFF58A6FF),
            ),
          ),
        ),
      ),
    );
  }
}

