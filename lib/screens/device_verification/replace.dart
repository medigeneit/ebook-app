import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../api/api_service.dart';
import '../../components/app_layout.dart';

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

  // ✅ existing request state
  Map<String, dynamic>? _existingRequest;
  bool _canEdit = false;
  bool _editing = true; // request না থাকলে default edit mode

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

  String _s(dynamic v) => (v ?? '').toString().trim();

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

      // settings note
      final settings = (data['settings'] is Map)
          ? Map<String, dynamic>.from(data['settings'])
          : <String, dynamic>{};

      final note = _extractSetting(settings['no_more_otp_note']).trim();

      // ✅ replace_request & can_edit (backend থেকে আসবে)
      Map<String, dynamic>? existing;
      final rr = data['replace_request'];
      if (rr is Map) existing = Map<String, dynamic>.from(rr);

      final canEdit = data['can_edit'] == true;

      if (!mounted) return;

      setState(() {
        _note = note.isNotEmpty
            ? note
            : 'OTP limit শেষ। এখন admin approve এর জন্য request দিতে হবে।';

        _existingRequest = existing;
        _canEdit = canEdit;

        // request থাকলে default edit mode বন্ধ
        _editing = (_existingRequest == null);

        // request থাকলে reason prefill
        if (_existingRequest != null) {
          _reasonCtrl.text = _s(_existingRequest?['reason']);
        }
      });
    } catch (e) {
      if (!mounted) return;
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
      // ✅ একই endpoint: backend pending থাকলে update / না থাকলে create
      final res = await _api.postData('/v1/my-device-verification/replace', {
        'reason': reason,
        'target': 'app',
      });

      if (res?['ok'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res?['message']?.toString() ?? 'Request sent')),
        );

        // reload করে request details দেখাবে
        await _load();

        if (mounted) {
          setState(() => _editing = false);
        }
      } else {
        if (!mounted) return;
        setState(() => _error = res?['message']?.toString() ?? 'Request failed');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _statusChip(String text) {
    final t = text.toLowerCase();
    final isPending = t.contains('pending') || t == '0';
    final isAccepted = t.contains('accept') || t.contains('approve') || t == '1';
    final isRejected = t.contains('reject') || t == '2';

    Color border = Colors.black26;
    Color bg = Colors.black12;
    Color fg = Colors.black87;

    if (isPending) {
      border = Colors.orange;
      bg = Colors.orange.withOpacity(.12);
      fg = Colors.orange.shade900;
    } else if (isAccepted) {
      border = Colors.green;
      bg = Colors.green.withOpacity(.12);
      fg = Colors.green.shade900;
    } else if (isRejected) {
      border = Colors.red;
      bg = Colors.red.withOpacity(.12);
      fg = Colors.red.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: .8),
        color: bg,
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRequest = _existingRequest != null;

    final status = hasRequest ? _s(_existingRequest?['status']) : '';
    final reason = hasRequest ? _s(_existingRequest?['reason']) : '';
    final createdAt = hasRequest ? _s(_existingRequest?['created_at']) : '';
    final updatedAt = hasRequest ? _s(_existingRequest?['updated_at']) : '';

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

            // ✅ Existing request details
            if (hasRequest) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'আপনার Replace Request',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (status.isNotEmpty) _statusChip(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (reason.isNotEmpty) Text('Reason: $reason'),
                    if (createdAt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Submitted: $createdAt'),
                    ],
                    if (updatedAt.isNotEmpty && updatedAt != createdAt) ...[
                      const SizedBox(height: 6),
                      Text('Updated: $updatedAt'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ✅ Edit toggle (only if can_edit)
              if (_canEdit)
                OutlinedButton(
                  onPressed: () {
                    setState(() => _editing = !_editing);
                    if (_editing) {
                      _reasonCtrl.text = _s(_existingRequest?['reason']);
                    }
                  },
                  child: Text(_editing ? 'Cancel Edit' : 'Edit Request'),
                ),

              const SizedBox(height: 12),
            ],

            // ✅ Editor (new request OR editing mode)
            if (!hasRequest || _editing) ...[
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
                child: Text(hasRequest ? 'Update Request' : 'Submit Request'),
              ),
            ] else ...[
              // ✅ Not editing and request exists
              const Text(
                'আপনার রিকোয়েস্টটি সাবমিট করা আছে। Pending থাকলে “Edit Request” দিয়ে আপডেট করতে পারবেন।',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
