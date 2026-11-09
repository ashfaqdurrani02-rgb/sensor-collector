// ============================================================
//  widgets/wifi_list_tile.dart
//  Renders one Wi-Fi access point scan result row.
// ============================================================

import 'package:flutter/material.dart';
import '../models/sensor_payload.dart';

class WifiListTile extends StatelessWidget {
  final WifiNetwork network;
  const WifiListTile({super.key, required this.network});

  int _bars(int rssi) {
    if (rssi >= -55) return 4;
    if (rssi >= -65) return 3;
    if (rssi >= -75) return 2;
    if (rssi >= -85) return 1;
    return 0;
  }

  Color _rssiColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -70) return Colors.lightGreen;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final bars  = _bars(network.rssi);
    final color = _rssiColor(network.rssi);
    final is5G  = network.frequencyMhz >= 5000;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.15)),
      ),
      child: Row(children: [
        // Signal bars
        _SignalBars(bars: bars, color: color),
        const SizedBox(width: 12),
        // Name + BSSID
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                network.ssid.isEmpty ? '(Hidden Network)' : network.ssid,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${network.bssid}  •  ch ${network.channel}',
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.45)),
              ),
            ],
          ),
        ),
        // RSSI + band badge
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${network.rssi} dBm',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (is5G ? Colors.orange : Colors.blue).withOpacity(0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              is5G ? '5 GHz' : '2.4 GHz',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: is5G ? Colors.orange : Colors.blue),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Signal bar renderer ───────────────────────────────────────
class _SignalBars extends StatelessWidget {
  final int   bars;
  final Color color;
  const _SignalBars({required this.bars, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final active = i < bars;
        return Container(
          width: 4,
          height: 6.0 + i * 4.5,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: active ? color : Colors.grey.withOpacity(0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

