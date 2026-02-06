import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../api/api_service.dart';
import '../../components/app_layout.dart'; // ✅ path ঠিক করুন

class DeviceReplaceRequestScreen extends StatefulWidget {
  const DeviceReplaceRequestScreen({super.key});

  @override
  State<DeviceReplaceRequestScreen> createState() =>
      _DeviceReplaceRequestScreenState();
}

class _DeviceReplaceRequestScreenState extends State<DeviceReplaceRequestScreen> {
  final _api = ApiService();

  bool _loading = true;
  String? _error;

  String _note = '';
  final _reasonCtrl = TextEditingController();

  String get _noteClean => _note.replaceAll('&nbsp;', ' ').trim();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String _extractSetting(dynamic settingObj) {
    if (settingObj == null) return '';
    if (settingObj is String) return settingObj;
    if (settingObj is Map) {
      final m = Map<String, dynamic>.from(settingObj);
      return (m['value'] ?? m['text'] ?? m['description'] ?? '').toString();
    }
    return settingObj.toString();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.fetchEbookData('/v1/my-device-verification/replace');
      final data = (res['data'] is Map)
          ? Map<String, dynamic>.from(res['data'])
          : <String, dynamic>{};

      final settings = (data['settings'] is Map)
          ? Map<String, dynamic>.from(data['settings'])
          : <String, dynamic>{};

      final note = _extractSetting(settings['no_more_otp_note']).trim();

      setState(() {
        _note = note.isNotEmpty
            ? note
            : 'OTP limit শেষ। এখন admin approve এর জন্য request দিতে হবে।';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'কারণ লিখুন');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.postData('/v1/my-device-verification/replace', {
        'reason': reason,
        'target': 'app',
      });

      if (res?['ok'] == true) {
        _reasonCtrl.clear();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res?['message']?.toString() ?? 'Request sent')),
        );

        await _load();
      } else {
        setState(() => _error = res?['message']?.toString() ?? 'Request failed');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Replace Request (STEP3)',
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

            // ✅ NOTE (HTML render)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _noteClean.isEmpty
                  ? const Text('No note')
                  : Html(
                data: _noteClean,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(14),
                    lineHeight: const LineHeight(1.35),
                  ),
                  "p": Style(margin: Margins.only(bottom: 8)),
                  "ul": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.only(left: 18),
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

            TextField(
              controller: _reasonCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'ডিভাইস পরিবর্তন করতে চান কেন লিখুন…',
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _submit,
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
