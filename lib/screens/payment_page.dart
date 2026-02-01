import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

typedef PaymentResultCallback = void Function(bool success, String? status);

class PaymentPage extends StatefulWidget {
  final String title;
  final Uri url;
  final String? subtitle;
  final PaymentResultCallback? onSuccess;

  const PaymentPage({
    super.key,
    required this.title,
    required this.url,
    this.subtitle,
    this.onSuccess,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  double _progress = 0;
  bool _hasError = false;
  bool _handledResult = false;
  String? _callbackErrorMessage;
  Map<String, String>? _callbackErrorDetails;
  String? _callbackRawPayload;

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: widget.title,
      showDrawer: false,
      showNavBar: false,
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url.toString())),
            initialOptions: InAppWebViewGroupOptions(
              android: AndroidInAppWebViewOptions(
                useHybridComposition: true,
              ),
            ),
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
                if (_hasError) _hasError = false;
              });
            },
            onReceivedError: (_, __, ___) {
              setState(() {
                _hasError = true;
              });
            },
            onReceivedHttpError: (_, __, ___) {
              setState(() {
                _hasError = true;
              });
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final urlString = navigationAction.request.url?.toString();
              final uri = urlString != null ? Uri.tryParse(urlString) : null;
              if (uri != null && _handleCallbackUri(uri)) {
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStop: (controller, uri) {
              final urlString = uri?.toString();
              final parsed = urlString != null ? Uri.tryParse(urlString) : null;
              if (parsed != null && _handleCallbackUri(parsed)) {
                return;
              }
            },
          ),
          if (_progress < 1 && !_hasError)
            Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                value: _progress,
                color: AppColors.primary,
                backgroundColor: AppColors.onGradientSoft,
              ),
            ),
          if (_hasError)
            Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Unable to load payment page.\nPlease check your connection and try again.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _progress = 0;
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_callbackErrorMessage != null)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: _buildCallbackErrorOverlay(context),
              ),
            ),
        ],
      ),
    );
  }

  bool _handleCallbackUri(Uri uri) {
    if (_handledResult) return false;
    final path = uri.path.toLowerCase();

    // ✅ API callback URL ধরুন
    final isApiCallback = path.contains('/api/v1/ebooks/') &&
        path.contains('/subscriptions/callback');

    // ? ???? web route fallback (??? ???? ??????? ??)
    final isWebCallback =
        path.contains('/bkash/choose-plan') || path.contains('/bkash/callback');

    if (isApiCallback || isWebCallback) {
      final qp = uri.queryParameters;
      final callbackPayload = uri.toString();

      final status = (qp['status'] ?? '').toLowerCase();
      final paymentId = qp['paymentID'] ?? qp['paymentId'] ?? qp['payment_id'];

      final success =
          status == 'success' || (paymentId != null && paymentId.isNotEmpty);
      final callbackMessage = _extractCallbackMessage(qp, status);
      print('Payment callback hit: $uri');
      debugPrint('Callback payload: $callbackPayload');
      print('Parameters: $qp');
      print('Determined status="$status", paymentId=$paymentId');

      if (success) {
        _handledResult = true;
        _callbackErrorMessage = null;
        _callbackErrorDetails = null;
        _callbackRawPayload = null;
        _finish(success);
      } else {
        setState(() {
          _handledResult = true;
          _callbackErrorMessage = callbackMessage;
          _callbackErrorDetails = qp.isEmpty ? null : qp;
          _callbackRawPayload = callbackPayload;
        });
      }
      return true;
    }

    return false;
  }

  void _finish(bool success) {
    final status = success ? 'success' : 'failure';
    widget.onSuccess?.call(success, status);
    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  String _extractCallbackMessage(Map<String, String> params, String status) {
    const keys = [
      'message',
      'status_text',
      'status_message',
      'error',
      'error_message',
      'remarks',
      'error_description',
    ];
    for (final key in keys) {
      final value = params[key];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    if (status.isNotEmpty) {
      return 'Status: ${status.toUpperCase()}';
    }
    return 'Payment failed. Please try again or contact support.';
  }

  Widget _buildCallbackErrorOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final details = _callbackErrorDetails?.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
    return FractionallySizedBox(
      widthFactor: 0.92,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Payment issue',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _callbackErrorMessage ??
                    'Something went wrong after the payment attempt.',
                style: theme.textTheme.bodyLarge,
              ),
              if (details != null && details.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Details',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: Text(
                      details,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
              if (_callbackRawPayload != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Callback URL',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _callbackRawPayload!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => _finish(false),
                child: const Text('Return to subscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
