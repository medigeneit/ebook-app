import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_service.dart';
import '../components/app_layout.dart';
import '../theme/app_colors.dart';

enum _DvStep { step1, step2, step3 }

class DeviceVerificationPage extends StatefulWidget {
  const DeviceVerificationPage({super.key});

  @override
  State<DeviceVerificationPage> createState() => _DeviceVerificationPageState();
}

class _DeviceVerificationPageState extends State<DeviceVerificationPage> {
  final _api = ApiService();

  bool _statusLoading = true;
  bool? _isActive;
  String? _statusError;

  bool _flowLoading = true;
  String? _flowError;
  _DvStep _step = _DvStep.step1;
  Map<String, dynamic> _flowData = {};

  bool _agree = false;
  final _otpCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  Timer? _timer;
  int _remainingSec = 0;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _loadInitialFlow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _statusLoading = true;
      _statusError = null;
    });
    try {
      final res = await _api.fetchEbookData('/v1/check-active-doctor-device');
      setState(() {
        _isActive = res['is_active'] == true;
      });
    } catch (e) {
      setState(() => _statusError = e.toString());
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  Future<void> _loadInitialFlow() async {
    // STEP resolver: create() call করলেই backend ঠিক করে দেয় STEP1/2/3
    await _loadStep(_DvStep.step1);
  }

  String _endpointWithQuery(String base, Map<String, String> query) {
    final q = query.entries
        .map((e) =>
    '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return q.isEmpty ? base : '$base?$q';
  }

  Future<void> _loadStep(
      _DvStep desired, {
        bool sendOtp = false,
        bool resendOtp = false,
      }) async {
    setState(() {
      _flowLoading = true;
      _flowError = null;
    });

    try {
      late String endpoint;
      switch (desired) {
        case _DvStep.step1:
          endpoint = '/v1/my-device-verification/create';
          break;
        case _DvStep.step2:
          endpoint = '/v1/my-device-verification/change';
          break;
        case _DvStep.step3:
          endpoint = '/v1/my-device-verification/replace';
          break;
      }

      if (sendOtp) {
        endpoint = _endpointWithQuery(endpoint, {'agreement': 'yes'});
      } else if (resendOtp) {
        endpoint = _endpointWithQuery(endpoint, {'action': 'RESEND OTP'});
      }

      final res = await _api.fetchEbookData(endpoint);
      final data = (res['data'] is Map)
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};

      // create() থেকে STEP2/3 আসলে সেই step এ switch হবে
      final next = (data['next_step'] ?? '').toString();
      final nextStep = switch (next) {
        'STEP1' => _DvStep.step1,
        'STEP2' => _DvStep.step2,
        'STEP3' => _DvStep.step3,
        _ => desired,
      };

      if (nextStep != desired) {
        await _loadStep(nextStep);
        return;
      }

      _setOtpTimerFromData(data);

      final prevStep = _step;
      setState(() {
        _step = desired;
        _flowData = data;
        if (prevStep != desired) {
          _agree = false;
          _otpCtrl.clear();
          _reasonCtrl.clear();
          _timer?.cancel();
          _remainingSec = 0;
        }
      });

      final msg = res['message']?.toString();
      if (msg != null && msg.isNotEmpty) _toast(msg);
    } catch (e) {
      setState(() => _flowError = e.toString());
    } finally {
      if (mounted) setState(() => _flowLoading = false);
    }
  }

  void _setOtpTimerFromData(Map<String, dynamic> data) {
    final raw = data['otp_expire_time_in_second'];
    final sec = (raw is int) ? raw : int.tryParse(raw?.toString() ?? '0') ?? 0;
    final otpSent = data['send_opt_status'] == true;

    if (!otpSent || sec <= 0) {
      _timer?.cancel();
      _remainingSec = 0;
      return;
    }

    _timer?.cancel();
    _remainingSec = sec;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSec <= 0) {
        t.cancel();
        setState(() {});
        return;
      }
      setState(() => _remainingSec--);
    });
  }

  Future<void> _submitOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length < 4) {
      _toast('OTP কোড ৪ ডিজিট দিন', isError: true);
      return;
    }

    setState(() => _flowLoading = true);
    try {
      late String endpoint;
      if (_step == _DvStep.step1) {
        endpoint = '/v1/my-device-verification';
      } else {
        endpoint = '/v1/my-device-verification/change';
      }

      final res = await _api.postData(endpoint, {
        'code': code,
        'target': 'app',
      });

      final ok = res?['ok'] == true;
      final msg = res?['message']?.toString() ??
          (ok ? 'Success' : 'কিছু একটা সমস্যা হয়েছে');

      if (!ok) {
        _toast(msg, isError: true);
        return;
      }

      _toast(msg);
      _otpCtrl.clear();
      await _refreshStatus();

      if (_isActive == true) {
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        await _loadInitialFlow();
      }
    } finally {
      if (mounted) setState(() => _flowLoading = false);
    }
  }

  Future<void> _submitReplaceRequest() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      _toast('কারণ লিখুন', isError: true);
      return;
    }

    setState(() => _flowLoading = true);
    try {
      final res = await _api.postData('/v1/my-device-verification/replace', {
        'reason': reason,
        'target': 'app',
      });

      final ok = res?['ok'] == true;
      final msg = res?['message']?.toString() ??
          (ok ? 'Request sent' : 'Request failed');

      if (!ok) {
        _toast(msg, isError: true);
        return;
      }

      _toast(msg);
      _reasonCtrl.clear();
      await _loadStep(_DvStep.step3);
    } finally {
      if (mounted) setState(() => _flowLoading = false);
    }
  }

  void _toast(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Info',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? AppColors.danger : AppColors.primary,
      colorText: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _openWebPortal() async {
    final uri = Uri.parse('https://banglamed.net/my-device-verification');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppLayout(
      title: 'Device Verification',
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshStatus();
          await _loadInitialFlow();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildStatusCard(theme),
            const SizedBox(height: 12),
            if (_isActive == true) _buildVerifiedHint(theme) else _buildFlowCard(theme),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _openWebPortal,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Web portal খুলে verify করব'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final t = theme.textTheme;

    return Card(
      color: theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('ডিভাইস স্ট্যাটাস', style: t.titleLarge)),
                IconButton(
                  onPressed: _refreshStatus,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_statusLoading)
              const LinearProgressIndicator()
            else if (_statusError != null)
              Text('লোড হয়নি: $_statusError',
                  style: t.bodyMedium?.copyWith(color: theme.colorScheme.error))
            else
              Row(
                children: [
                  Icon(
                    _isActive == true ? Icons.check_circle : Icons.warning_rounded,
                    color: _isActive == true
                        ? Colors.greenAccent.shade700
                        : Colors.orangeAccent,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isActive == true ? 'Verified (Active)' : 'Not verified',
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _isActive == true
                          ? Colors.greenAccent.shade700
                          : Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedHint(ThemeData theme) {
    final t = theme.textTheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ আপনার ডিভাইস Verified',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'এখন আপনি app থেকে বই পড়তে পারবেন। নতুন ডিভাইসে লগইন করলে আবার verify লাগতে পারে।',
              style: t.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowCard(ThemeData theme) {
    final t = theme.textTheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verify করার ধাপ', style: t.titleLarge),
            const SizedBox(height: 10),
            _buildStepper(),
            const SizedBox(height: 12),
            if (_flowLoading) const LinearProgressIndicator(),
            if (_flowError != null) ...[
              const SizedBox(height: 10),
              Text('লোড হয়নি: $_flowError',
                  style: t.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 10),
            _buildStepBody(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    int idx = 0;
    if (_step == _DvStep.step2) idx = 1;
    if (_step == _DvStep.step3) idx = 2;

    return Stepper(
      type: StepperType.horizontal,
      currentStep: idx,
      physics: const NeverScrollableScrollPhysics(),
      controlsBuilder: (_, __) => const SizedBox.shrink(),
      steps: const [
        Step(title: Text('Add'), content: SizedBox.shrink(), isActive: true),
        Step(title: Text('Replace'), content: SizedBox.shrink(), isActive: true),
        Step(title: Text('Request'), content: SizedBox.shrink(), isActive: true),
      ],
    );
  }

  Widget _buildStepBody(ThemeData theme) {
    switch (_step) {
      case _DvStep.step1:
        return _buildStep1(theme);
      case _DvStep.step2:
        return _buildStep2(theme);
      case _DvStep.step3:
        return _buildStep3(theme);
    }
  }

  Widget _buildStep1(ThemeData theme) {
    final terms = (_flowData['terms_and_conditions'] ?? '').toString();
    final otpMsg = (_flowData['otp_sms_message'] ?? '').toString();
    final otpSent = _flowData['send_opt_status'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTermsBlock(theme, 'Add device terms', terms),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _agree,
          onChanged: _flowLoading ? null : (v) => setState(() => _agree = v == true),
          contentPadding: EdgeInsets.zero,
          title: const Text('আমি শর্তাবলীতে সম্মত'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: (_flowLoading || !_agree)
              ? null
              : () => _loadStep(_DvStep.step1, sendOtp: true),
          icon: const Icon(Icons.sms_outlined),
          label: const Text('OTP পাঠান'),
        ),
        const SizedBox(height: 8),
        if (otpMsg.isNotEmpty) Text(otpMsg, style: theme.textTheme.bodySmall),
        if (otpSent) ...[
          const SizedBox(height: 10),
          _buildOtpBox(theme),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _flowLoading ? null : _submitOtp,
                  child: const Text('Verify'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _flowLoading
                      ? null
                      : () => _loadStep(_DvStep.step1, resendOtp: true),
                  child: const Text('Resend OTP'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStep2(ThemeData theme) {
    final terms = (_flowData['terms_and_conditions'] ?? '').toString();
    final otpMsg = (_flowData['otp_sms_message'] ?? '').toString();
    final otpSent = _flowData['send_opt_status'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTermsBlock(theme, 'Replace device terms', terms),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _agree,
          onChanged: _flowLoading ? null : (v) => setState(() => _agree = v == true),
          contentPadding: EdgeInsets.zero,
          title: const Text('আমি শর্তাবলীতে সম্মত'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: (_flowLoading || !_agree)
              ? null
              : () => _loadStep(_DvStep.step2, sendOtp: true),
          icon: const Icon(Icons.sms_outlined),
          label: const Text('OTP পাঠান (Replace)'),
        ),
        const SizedBox(height: 8),
        if (otpMsg.isNotEmpty) Text(otpMsg, style: theme.textTheme.bodySmall),
        if (otpSent) ...[
          const SizedBox(height: 10),
          _buildOtpBox(theme),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _flowLoading ? null : _submitOtp,
                  child: const Text('Verify Replace'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _flowLoading
                      ? null
                      : () => _loadStep(_DvStep.step2, resendOtp: true),
                  child: const Text('Resend OTP'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text('নোট: Replace করলে আগের ডিভাইসটি expire হয়ে যাবে।',
            style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildStep3(ThemeData theme) {
    final settings = (_flowData['settings'] is Map)
        ? Map<String, dynamic>.from(_flowData['settings'] as Map)
        : <String, dynamic>{};
    final note = _extractSettingValue(settings['no_more_otp_note']) ??
        'OTP limit শেষ। এখন admin request দিতে হবে।';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(note, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _reasonCtrl,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Replace reason',
            hintText: 'ডিভাইস কেন পরিবর্তন করতে চান লিখুন…',
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _flowLoading ? null : _submitReplaceRequest,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Request submit'),
        ),
        const SizedBox(height: 8),
        Text('Request approve হলে আবার এই পেজ থেকে status refresh করুন।',
            style: theme.textTheme.bodySmall),
      ],
    );
  }

  String? _extractSettingValue(dynamic settingObj) {
    if (settingObj == null) return null;
    if (settingObj is String) return settingObj;
    if (settingObj is Map) {
      final m = Map<String, dynamic>.from(settingObj);
      return (m['value'] ?? m['text'] ?? m['description'] ?? m['name'])
          ?.toString();
    }
    return settingObj.toString();
  }

  Widget _buildTermsBlock(ThemeData theme, String title, String terms) {
    final t = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: terms.isEmpty
                    ? null
                    : () => _showTermsDialog(theme, title, terms),
                child: const Text('View'),
              ),
            ],
          ),
          if (terms.isEmpty)
            Text('Terms পাওয়া যায়নি (backend settings check করুন)',
                style: t.bodySmall)
          else
            Text('শর্তাবলী দেখে সম্মতি দিন, তারপর OTP পাঠান।',
                style: t.bodySmall),
        ],
      ),
    );
  }

  void _showTermsDialog(ThemeData theme, String title, String terms) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: Html(data: terms)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  Widget _buildOtpBox(ThemeData theme) {
    final t = theme.textTheme;
    final timerText = _remainingSec > 0
        ? 'OTP valid: $_remainingSec s'
        : 'OTP time ended (resend দিন)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(timerText, style: t.bodySmall),
        const SizedBox(height: 6),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'OTP Code',
            hintText: '৪ ডিজিট OTP লিখুন',
            counterText: '',
          ),
        ),
      ],
    );
  }
}
