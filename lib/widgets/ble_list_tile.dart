// ============================================================
//  widgets/ble_list_tile.dart
//  Renders one BLE / Bluetooth device scan result row.
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sensor_payload.dart';

class BleListTile extends StatelessWidget {
  final BleDevice device;
  const BleListTile({super.key, required this.device});

  Color _rssiColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -70) return Colors.lightGreen;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
  }

  /// Log-distance path-loss model estimate (Tx power ≈ −59 dBm @ 1 m)
  String _distance(int rssi) {
    if (rssi == 0) return '?';
    const txPow = -59.0;
    final ratio = rssi / txPow;
    final d = ratio < 1.0
        ? pow(ratio, 3).toDouble()
        : 0.89976 * pow(ratio, 3) + 0.111 * ratio + 0.111;
    return '~${d.toStringAsFixed(1)} m';
  }

  @override
  Widget build(BuildContext context) {
    final color = _rssiColor(device.rssi);
    final c     = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withOpacity(0.15)),
      ),
      child: Row(children: [
        // BT icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bluetooth, color: Colors.purple, size: 17),
        ),
        const SizedBox(width: 12),
        // Name + ID + UUID
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name.isEmpty ? 'Unknown Device' : device.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                device.id,
                style: TextStyle(
                    fontSize: 10,
                    color: c.onSurface.withOpacity(0.4)),
                overflow: TextOverflow.ellipsis,
              ),
              if (device.uuid != null && device.uuid!.isNotEmpty)
                Text(
                  'UUID: ${device.uuid}',
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // RSSI + estimated distance
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${device.rssi} dBm',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            _distance(device.rssi),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ]),
      ]),
    );
  }
}

