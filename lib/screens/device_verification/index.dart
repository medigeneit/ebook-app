import 'package:flutter/material.dart';
import '../../api/api_service.dart';

class DeviceVerificationIndexScreen extends StatefulWidget {
  const DeviceVerificationIndexScreen({super.key});

  @override
  State<DeviceVerificationIndexScreen> createState() =>
      _DeviceVerificationIndexScreenState();
}

class _DeviceVerificationIndexScreenState
    extends State<DeviceVerificationIndexScreen> {
  final _api = ApiService();
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveStep();
  }

  Future<void> _resolveStep() async {
    try {
      // create call করলেই backend next_step বলে দেয় (STEP1/2/3)
      final res = await _api.fetchEbookData('/v1/my-device-verification/create');
      final data = (res['data'] is Map) ? Map<String, dynamic>.from(res['data']) : {};
      final next = (data['next_step'] ?? 'STEP1').toString();

      if (!mounted) return;

      if (next == 'STEP2') {
        Navigator.pushReplacementNamed(context, '/device-change');
      } else if (next == 'STEP3') {
        Navigator.pushReplacementNamed(context, '/device-replace-request');
      } else {
        Navigator.pushReplacementNamed(context, '/device-add');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Verification')),
      body: Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('লোড হয়নি: $_error'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _resolveStep,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
