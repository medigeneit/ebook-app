import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../components/app_layout.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  final _api = ApiService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _current;
  List<Map<String, dynamic>> _activeDevices = [];
  int _expiredCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.fetchEbookData('/v1/my-device-verification');
      final data = (res['data'] is Map) ? Map<String, dynamic>.from(res['data']) : {};

      final current = (data['current_device'] is Map)
          ? Map<String, dynamic>.from(data['current_device'])
          : <String, dynamic>{};

      final actives = <Map<String, dynamic>>[];
      if (data['active_devices'] is List) {
        for (final x in (data['active_devices'] as List)) {
          if (x is Map) actives.add(Map<String, dynamic>.from(x));
        }
      }

      final expired = (data['count_expired_doctor_devices'] is int)
          ? data['count_expired_doctor_devices'] as int
          : int.tryParse((data['count_expired_doctor_devices'] ?? '0').toString()) ?? 0;

      if (!mounted) return;
      setState(() {
        _current = current;
        _activeDevices = actives;
        _expiredCount = expired;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isCurrentActive => (_current?['is_active'] == true);

  String _s(dynamic v) => (v ?? '').toString();

  Widget _statusChip({required bool ok, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? Colors.green.withOpacity(.12) : Colors.red.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ok ? Colors.green : Colors.red, width: .7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: ok ? Colors.green.shade800 : Colors.red.shade800,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _deviceTile(Map<String, dynamic> d, {bool showActiveDot = false}) {
    final name = _s(d['name']).isEmpty ? 'Unknown Device' : _s(d['name']);
    final lastUsed = _s(d['last_used_at']);
    final verifiedAt = _s(d['verified_at']);
    final isActive = d['is_active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            const Icon(Icons.devices_rounded, size: 28),
            if (showActiveDot)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastUsed.isNotEmpty) Text('Last used: $lastUsed'),
            if (verifiedAt.isNotEmpty) Text('Verified: $verifiedAt'),
          ],
        ),
        trailing: _statusChip(
          ok: isActive,
          text: isActive ? 'ACTIVE' : 'INACTIVE',
        ),
      ),
    );
  }

  void _goVerifyFlow({String redirectTo = '/device-info'}) {
    Navigator.pushNamed(
      context,
      '/device-verification',
      arguments: {'redirectTo': redirectTo},
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Device Information',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],

            // Top summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.blue.withOpacity(.06),
                border: Border.all(color: Colors.blue.withOpacity(.18)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isCurrentActive
                          ? '✅ আপনার বর্তমান ডিভাইস Verified/Active আছে।'
                          : '⚠️ আপনার বর্তমান ডিভাইস Verified নয়। Verify করলে My Ebooks দেখা যাবে।',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            if (_expiredCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.orange.withOpacity(.08),
                  border: Border.all(color: Colors.orange.withOpacity(.25)),
                ),
                child: Text('Expired devices: $_expiredCount'),
              ),
            ],

            const SizedBox(height: 18),

            // Verified devices
            Text(
              'Verified Devices (Device + Browser)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),

            if (_activeDevices.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Text('কোন Verified device পাওয়া যায়নি।'),
              )
            else
              ..._activeDevices.map((d) => _deviceTile(d, showActiveDot: true)),

            const SizedBox(height: 18),

            // Current device
            Text(
              'Current Device (This device)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),

            if (_current == null)
              const Text('Current device info পাওয়া যায়নি')
            else
              _deviceTile(_current!, showActiveDot: true),

            const SizedBox(height: 16),

            // Actions
            if (_isCurrentActive) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/my-ebooks');
                      },
                      child: const Text('Continue to My Ebooks'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/device-change');
                      },
                      child: const Text('Change Device'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _goVerifyFlow(redirectTo: '/device-info'),
                      child: const Text('Request to verify'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/device-replace-request');
                      },
                      child: const Text('Replace Request'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
