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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _resolveStep();
    await _redirectIfVerified();
  }

  Future<void> _redirectIfVerified() async {
    try {
      final res = await _api.fetchEbookData('/v1/check-active-doctor-device');
      final isActive = res['is_active'] == true;

      if (isActive && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/my-ebooks', (_) => false);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _resolveStep() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // create call করলেই backend next_step বলে দেয় (STEP1/2/3)
      final res = await _api.fetchEbookData('/v1/my-device-verification/create');
      final data = (res['data'] is Map)
          ? Map<String, dynamic>.from(res['data'])
          : <String, dynamic>{};
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRefresh() async {
    // refresh -> step resolve -> check verified -> redirect if verified
    await _resolveStep();
    await _redirectIfVerified();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Verification')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 120),

            Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : (_error == null
                  ? const Text('Loading...')
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('লোড হয়নি: $_error',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}
