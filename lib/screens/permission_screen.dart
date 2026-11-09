// ============================================================
//  screens/permission_screen.dart
//  Requests all runtime permissions before the app can scan.
// ============================================================

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _checking = false;
  Map<String, PermissionStatus> _statuses = {};

  /// All permissions the app needs, with human-readable metadata.
  final _items = const [
    _PermItem(
      perm:  Permission.location,
      label: 'Fine Location',
      desc:  'Required by Android for Wi-Fi & BLE scanning',
      icon:  Icons.location_on,
    ),
    _PermItem(
      perm:  Permission.bluetoothScan,
      label: 'Bluetooth Scan',
      desc:  'Discover nearby BLE / Bluetooth devices',
      icon:  Icons.bluetooth_searching,
    ),
    _PermItem(
      perm:  Permission.bluetoothConnect,
      label: 'Bluetooth Connect',
      desc:  'Read device names from BLE advertisements',
      icon:  Icons.bluetooth_connected,
    ),
    _PermItem(
      perm:  Permission.phone,
      label: 'Phone State',
      desc:  'Read cellular network type and signal strength',
      icon:  Icons.signal_cellular_alt,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkAll();
  }

  Future<void> _checkAll() async {
    setState(() => _checking = true);
    final m = <String, PermissionStatus>{};
    for (final item in _items) {
      m[item.label] = await item.perm.status;
    }
    if (mounted) setState(() { _statuses = m; _checking = false; });
  }

  Future<void> _requestAll() async {
    setState(() => _checking = true);
    final perms   = _items.map((i) => i.perm).toList();
    final results = await perms.request();
    final m = <String, PermissionStatus>{};
    for (int i = 0; i < _items.length; i++) {
      m[_items[i].label] = results[perms[i]] ?? PermissionStatus.denied;
    }
    if (mounted) setState(() { _statuses = m; _checking = false; });
  }

  bool get _allGranted =>
      _items.every((i) => _statuses[i.label] == PermissionStatus.granted);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // ── App icon + title ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.sensors, color: c.primary, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sensor Collector',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: c.primary,
                          )),
                      Text('Indoor RF & Telemetry',
                          style: TextStyle(
                            fontSize: 13,
                            color: c.onSurface.withOpacity(0.55),
                          )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text('Required Permissions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                  )),
              const SizedBox(height: 4),
              Text(
                'These permissions are needed for sensor scanning. '
                'None of your data is shared without your consent.',
                style: TextStyle(
                  fontSize: 12,
                  color: c.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),

              // ── Permission list ──
              Expanded(
                child: _checking
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final item    = _items[i];
                          final status  = _statuses[item.label];
                          final granted = status == PermissionStatus.granted;
                          final denied  = status == PermissionStatus.permanentlyDenied;
                          return _PermCard(
                            item:    item,
                            granted: granted,
                            denied:  denied,
                            onOpenSettings: denied
                                ? () => openAppSettings()
                                : null,
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // ── Buttons ──
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _checking ? null : _requestAll,
                  icon:  const Icon(Icons.security),
                  label: const Text('Grant All Permissions'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _allGranted
                      ? () => Navigator.pushReplacementNamed(context, '/home')
                      : null,
                  child: const Text('Continue →'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
                child: Center(
                  child: Text(
                    'Skip (some sensors may not work)',
                    style: TextStyle(
                      color: c.onSurface.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data class ───────────────────────────────────────────────
class _PermItem {
  final Permission perm;
  final String     label;
  final String     desc;
  final IconData   icon;
  const _PermItem({
    required this.perm,
    required this.label,
    required this.desc,
    required this.icon,
  });
}

// ── Permission row card ───────────────────────────────────────
class _PermCard extends StatelessWidget {
  final _PermItem       item;
  final bool            granted;
  final bool            denied;
  final VoidCallback?   onOpenSettings;
  const _PermCard({
    required this.item,
    required this.granted,
    required this.denied,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: granted
              ? Colors.green.withOpacity(0.5)
              : denied
                  ? Colors.orange.withOpacity(0.4)
                  : c.outline.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(item.icon,
              color: granted ? Colors.green : denied ? Colors.orange : c.primary,
              size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(item.desc,
                    style: TextStyle(
                        fontSize: 11,
                        color: c.onSurface.withOpacity(0.55))),
                if (denied)
                  TextButton(
                    onPressed: onOpenSettings,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 24)),
                    child: const Text('Open Settings →',
                        style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ),
          Icon(
            granted
                ? Icons.check_circle
                : denied
                    ? Icons.warning_amber
                    : Icons.radio_button_unchecked,
            color: granted
                ? Colors.green
                : denied
                    ? Colors.orange
                    : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}

