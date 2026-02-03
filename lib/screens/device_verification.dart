import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_service.dart';
import '../components/app_layout.dart';

class DeviceVerificationPage extends StatefulWidget {
  const DeviceVerificationPage({super.key});

  @override
  State<DeviceVerificationPage> createState() => _DeviceVerificationPageState();
}

class _DeviceVerificationPageState extends State<DeviceVerificationPage> {
  bool _isLoading = true;
  bool? _isActive;
  String? _error;
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data =
          await ApiService().fetchEbookData('/v1/check-active-doctor-device');
      final status = data['is_active'] == true;
      setState(() {
        _isActive = status;
        _lastChecked = DateTime.now();
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openVerificationPage() async {
    final uri = Uri.parse('https://banglamed.net/my-device-verification');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the verification page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasStatus = _isActive != null;
    final textTheme = theme.textTheme;

    return AppLayout(
      title: 'Device Verification',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: theme.colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current device status', style: textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const LinearProgressIndicator()
                    else if (_error != null)
                      Text('Unable to load status: $_error',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: Colors.redAccent))
                    else
                      Row(
                        children: [
                          Icon(
                            _isActive == true
                                ? Icons.check_circle
                                : Icons.warning_rounded,
                            color: _isActive == true
                                ? Colors.greenAccent.shade700
                                : Colors.orangeAccent,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isActive == true
                                    ? 'Device verified'
                                    : 'Device not verified',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: _isActive == true
                                      ? Colors.greenAccent.shade700
                                      : Colors.orangeAccent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasStatus
                                    ? 'Last checked: ${_formatTimestamp(_lastChecked)}'
                                    : 'Status unknown',
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'If your device is not verified, follow the verification workflow on the web portal. You need an active device record to keep reading ebooks.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _openVerificationPage,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open device verification'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _refreshStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh status'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) return '—';
    return '${value.toLocal()}'.split('.').first;
  }
}
