// ============================================================
//  screens/config_screen.dart
//  Configuration: backend URL, room ID, polling interval.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _roomCtrl;
  late final TextEditingController _deviceCtrl;
  late int  _interval;
  late bool _useWs;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final cfg  = context.read<ConfigProvider>();
    _urlCtrl    = TextEditingController(text: cfg.backendUrl);
    _roomCtrl   = TextEditingController(text: cfg.roomId);
    _deviceCtrl = TextEditingController(text: cfg.deviceName);
    _interval   = cfg.pollingInterval;
    _useWs      = cfg.useWebSocket;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _roomCtrl.dispose();
    _deviceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<ConfigProvider>().save(
      backendUrl:      _urlCtrl.text.trim(),
      roomId:          _roomCtrl.text.trim(),
      deviceName:      _deviceCtrl.text.trim(),
      pollingInterval: _interval,
      useWebSocket:    _useWs,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Configuration saved'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c     = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        backgroundColor: const Color(0xFF0A0E1A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── BACKEND section ─────────────────────────
              _Label('Backend Connection'),
              const SizedBox(height: 10),

              // Protocol selector
              Row(children: [
                const Text('Protocol:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('HTTP POST'),
                  selected: !_useWs,
                  onSelected: (_) => setState(() => _useWs = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('WebSocket'),
                  selected: _useWs,
                  onSelected: (_) => setState(() => _useWs = true),
                ),
              ]),
              const SizedBox(height: 12),

              _Field(
                controller: _urlCtrl,
                label:      _useWs ? 'WebSocket URL' : 'HTTP Endpoint URL',
                hint:       _useWs
                    ? 'ws://192.168.1.100:8080/ws/sensor'
                    : 'http://192.168.1.100:8080/api/sensor',
                icon:       Icons.cloud_upload_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'URL is required';
                  if (Uri.tryParse(v) == null) return 'Invalid URL';
                  return null;
                },
              ),
              const SizedBox(height: 6),
              Text(
                _useWs
                    ? 'WebSocket: persistent connection, lowest overhead'
                    : 'HTTP POST: simpler, works with most REST backends',
                style: TextStyle(
                    fontSize: 11,
                    color: c.onSurface.withOpacity(0.45)),
              ),

              const SizedBox(height: 24),

              // ── IDENTITY section ─────────────────────────
              _Label('Identity'),
              const SizedBox(height: 10),

              _Field(
                controller: _roomCtrl,
                label:      'Room ID',
                hint:       'e.g. Room-A, Lab-2, Office-North',
                icon:       Icons.meeting_room_outlined,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Room ID required' : null,
              ),
              const SizedBox(height: 12),

              _Field(
                controller: _deviceCtrl,
                label:      'Device Name',
                hint:       'e.g. Phone-1, Pixel-9',
                icon:       Icons.smartphone,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Device name required' : null,
              ),

              const SizedBox(height: 24),

              // ── POLLING INTERVAL section ─────────────────
              _Label('Polling Interval'),
              const SizedBox(height: 10),

              Row(children: [
                Expanded(
                  child: Slider(
                    value:     _interval.toDouble(),
                    min:       2,
                    max:       30,
                    divisions: 28,
                    label:     '${_interval}s',
                    onChanged: (v) => setState(() => _interval = v.round()),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${_interval}s',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.primary,
                    ),
                  ),
                ),
              ]),
              Text(
                'Collect & send a payload every $_interval seconds  (range: 2–30 s)',
                style: TextStyle(
                    fontSize: 11, color: c.onSurface.withOpacity(0.45)),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon:  const Icon(Icons.save_outlined),
                  label: const Text('Save Configuration'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Payload preview ──────────────────────────
              _PayloadPreview(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController     controller;
  final String                    label;
  final String                    hint;
  final IconData                  icon;
  final String? Function(String?) validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      validator:  validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText:  hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: c.outline.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.primary)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }
}

class _PayloadPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<ConfigProvider>();
    final ts  = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final preview = '''
{
  "timestamp": $ts,
  "room_id": "${cfg.roomId}",
  "device_name": "${cfg.deviceName}",
  "wifi_networks": [
    {"ssid": "Home_5G", "rssi": -65, "frequency_mhz": 5180, "channel": 36, "band": "5GHz"}
  ],
  "ble_devices": [
    {"name": "Beacon1", "id": "AA:BB:CC:DD:EE:FF", "rssi": -72, "uuid": "..."}
  ],
  "cell_signal_dbm": -95,
  "cell_network_type": "LTE",
  "environment": {
    "magnetic_field_ut": 45.2,
    "light_lux": 150.0
  },
  "battery_percent": 85,
  "battery_state": "charging"
}''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.data_object,
              size: 14,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text('Payload Preview',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              )),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              preview.trim(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFF58A6FF),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

