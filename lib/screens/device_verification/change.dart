import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../api/api_service.dart';
import '../../components/app_layout.dart'; // ✅ path ঠিক করুন

class DeviceChangeScreen extends StatefulWidget {
  const DeviceChangeScreen({super.key});

  @override
  State<DeviceChangeScreen> createState() => _DeviceChangeScreenState();
}

class _DeviceChangeScreenState extends State<DeviceChangeScreen> {
  final _api = ApiService();

  bool _loading = true;
  String? _error;

  bool _agree = false;
  bool _otpSent = false;

  String _otpMsg = '';
  String _terms = '';
  int _remaining = 0;
  Timer? _timer;

  final _otpCtrl = TextEditingController();

  String get _termsClean => _terms.replaceAll('&nbsp;', ' ').trim();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool sendOtp = false, bool resend = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String endpoint = '/v1/my-device-verification/change';
      if (sendOtp) endpoint += '?agreement=yes';
      if (resend) endpoint += '?action=RESEND%20OTP';

      final res = await _api.fetchEbookData(endpoint);
      final data = (res['data'] is Map)
          ? Map<String, dynamic>.from(res['data'])
          : <String, dynamic>{};

      final next = (data['next_step'] ?? 'STEP2').toString();

      if (!mounted) return;

      if (next == 'STEP1') {
        Navigator.pushReplacementNamed(context, '/device-add');
        return;
      }
      if (next == 'STEP3') {
        Navigator.pushReplacementNamed(context, '/device-replace-request');
        return;
      }

      setState(() {
        _terms = (data['terms_and_conditions'] ?? '').toString();
        _otpMsg = (data['otp_sms_message'] ?? '').toString();
        _otpSent = data['send_opt_status'] == true;
      });

      final secRaw = data['otp_expire_time_in_second'];
      final sec = (secRaw is int)
          ? secRaw
          : int.tryParse(secRaw?.toString() ?? '0') ?? 0;

      if (_otpSent && sec > 0) _startTimer(sec);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startTimer(int sec) {
    _timer?.cancel();
    setState(() => _remaining = sec);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 0) {
        t.cancel();
        setState(() {});
        return;
      }
      setState(() => _remaining--);
    });
  }

  Future<void> _verify() async {
    final code = _otpCtrl.text.trim();
    if (code.length < 4) return;

    setState(() => _loading = true);
    try {
      final res = await _api.postData('/v1/my-device-verification/change', {
        'code': code,
        'target': 'app',
      });

      if (res?['ok'] == true) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      } else {
        setState(() => _error = res?['message']?.toString() ?? 'OTP mismatch');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerText = _otpSent
        ? (_remaining > 0 ? 'OTP Valid: $_remaining s' : 'OTP expired, Resend দিন')
        : '';

    return AppLayout(
      title: 'Change Device (STEP2)',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],

            Text('Terms:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            // ✅ HTML Render
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _termsClean.isEmpty
                  ? const Text('Terms not found')
                  : Html(
                data: _termsClean,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(14),
                    lineHeight: const LineHeight(1.35),
                  ),
                  "ol": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.only(left: 18),
                  ),
                  "li": Style(margin: Margins.only(bottom: 8)),
                  "strong": Style(fontWeight: FontWeight.w700),
                },
              ),
            ),

            const SizedBox(height: 12),

            CheckboxListTile(
              value: _agree,
              onChanged: (v) => setState(() => _agree = v == true),
              title: const Text('আমি শর্তাবলীতে সম্মত'),
              contentPadding: EdgeInsets.zero,
            ),

            ElevatedButton(
              onPressed: _agree ? () => _load(sendOtp: true) : null,
              child: const Text('OTP পাঠান (Replace)'),
            ),

            const SizedBox(height: 10),
            if (_otpMsg.isNotEmpty) Text(_otpMsg),

            if (_otpSent) ...[
              const SizedBox(height: 10),
              Text(timerText),
              const SizedBox(height: 8),

              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'OTP Code',
                  counterText: '',
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _verify,
                      child: const Text('Verify Replace'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _load(resend: true),
                      child: const Text('Resend OTP'),
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
