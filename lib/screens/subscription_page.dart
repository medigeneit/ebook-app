import 'dart:convert';
import 'dart:math';

import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/models/all_ebook.dart';
import 'package:ebook_project/models/ebook.dart';
import 'package:ebook_project/screens/payment_page.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Mirrors the web's `choose-plan` experience using locally computed plan data.
class SubscriptionPage extends StatefulWidget {
  final Ebook ebook;
  final AllEbook? softcopy;
  final Uri fallbackUrl;
  final bool showLegacyPlans;

  const SubscriptionPage({
    super.key,
    required this.ebook,
    required this.fallbackUrl,
    this.softcopy,
    this.showLegacyPlans = false,
  });

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  static const int _maxPurchasableMonth = 12;
  static const int _couponRenewalDiscount = 75;
  static const Map<int, int> _discountTable = {
    1: 0,
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 5,
    7: 10,
    8: 15,
    9: 20,
    10: 25,
    11: 30,
    12: 35,
  };

  late final List<SubscriptionPlan> _plans;
  int _selectedPlan = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _plans = _buildPlans();
  }

  @override
  Widget build(BuildContext context) {
    final hasPlans = _plans.isNotEmpty;
    final planTitle =
        widget.showLegacyPlans ? 'Available Plans' : 'Choose a plan';
    final title = widget.ebook.name.isNotEmpty ? widget.ebook.name : planTitle;

    return AppLayout(
      title: title,
      showDrawer: false,
      showNavBar: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              planTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: hasPlans
                  ? ListView.builder(
                      itemCount: _plans.length,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemBuilder: (context, index) {
                        final plan = _plans[index];
                        final isSelected = index == _selectedPlan;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: _PlanCard(
                            plan: plan,
                            selected: isSelected,
                            package: widget.softcopy,
                            onTap: () {
                              setState(() {
                                _selectedPlan = index;
                              });
                            },
                          ),
                        );
                      },
                    )
                  : _buildEmptyState(),
            ),
            if (hasPlans) ...[
              _buildPaymentMethodSection(),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessing
                    ? null
                    : () => _goToPayment(_plans[_selectedPlan]),
                child: _isProcessing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Continue to payment'),
              ),
            ],
            // if (!hasPlans)
            //   ElevatedButton(
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: AppColors.primary,
            //       padding: const EdgeInsets.symmetric(vertical: 14),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //     ),
            //     onPressed: _openFallback,
            //     child: const Text('Open subscription on website'),
            //   ),
            // const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Payment method',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _PaymentMethodTile(
            label: 'Online (Bkash)',
            assetUrl:
                'https://file-mbo.s3.ap-southeast-1.amazonaws.com/images/bkash.webp',
            description:
                'Choose Bkash for instant payment. You will be redirected to the official payment sheet.',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // return Center(
    //   child: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       Icon(Icons.info_outline, size: 48, color: AppColors.primary),
    //       const SizedBox(height: 8),
    //       const Text(
    //         'Subscription details are not available inside the app yet. We will take you to the web version to continue.',
    //         textAlign: TextAlign.center,
    //       ),
    //       const SizedBox(height: 16),
    //       ElevatedButton(
    //         onPressed: _openFallback,
    //         child: const Text('Continue on web'),
    //       ),
    //     ],
    //   ),
    // );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 54, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'This ebook is not available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 220,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFallback() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          url: widget.fallbackUrl,
          title:
              widget.ebook.name.isNotEmpty ? widget.ebook.name : 'Subscription',
          subtitle: 'Continue on banglamed.net',
        ),
      ),
    );
  }

  void _goToPayment(SubscriptionPlan plan) {
    _handleSubscription(plan);
  }

  Future<void> _handleSubscription(SubscriptionPlan plan) async {
    if (_isProcessing) return;
    if (widget.ebook.id <= 0) {
      _showMessage('Select a valid ebook to continue.');
      _openFallback();
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final productId = widget.softcopy?.productId ?? widget.ebook.id;
      final response = await ApiService().createSubscription(
        productId: productId,
        monthlyPlan: plan.month,
      );

      final rawStatus = response['status']?.toString().toLowerCase() ?? '';
      if (rawStatus == 'payment_redirect') {
        final urlString = response['bkash_url']?.toString();
        final redirectUri = urlString != null ? Uri.tryParse(urlString) : null;
        if (redirectUri != null) {
          if (!mounted) return;
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentPage(
              url: redirectUri,
              title: widget.ebook.name.isNotEmpty
                  ? widget.ebook.name
                  : 'Subscription',
              subtitle: 'Pay ${plan.payableAmount} TK',
            ),
          ),
        );
        if (mounted) {
          if (result == true) {
            _showMessage('Payment success! Refreshing your library.');
            Navigator.of(context).pop(true);
          } else {
            _showMessage('Payment was cancelled or failed.');
          }
        }
        return;
        }
        _showMessage('Payment link is not available right now.');
        return;
      }

      _showMessage(_friendlyMessage(response, rawStatus));
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Payment failed. ${error.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _friendlyMessage(Map<String, dynamic> response, String status) {
    return response['message'] ??
        response['status_text'] ??
        'Subscription ${status.isNotEmpty ? status : 'updated'}.';
  }

  List<SubscriptionPlan> _buildPlans() {
    final price = _monthlyPrice(widget.softcopy?.price);
    if (price == null || price == 0) {
      return [];
    }

    // final packages = _normalizePackages(widget.softcopy?.packages ?? []);
    final packages = _normalizePackages(widget.softcopy?.packages ?? [])
        .where((p) => p.month > 0)
        .toList();
    if (packages.isNotEmpty) {
      final sorted = [...packages]..sort((a, b) => a.month.compareTo(b.month));
      return sorted
          .map((package) => _planFromPackage(package, price))
          .toList(growable: false);
    }

    final startMonth = 3;
    final maxMonth = _computeMaxMonth(widget.softcopy?.availability);
    return List.generate(
      maxMonth > 0 ? (maxMonth - startMonth + 1).clamp(0, maxMonth) : 0,
      (index) => _planFromMonth(startMonth + index, price),
    )..removeWhere((plan) => plan.month <= 0);
  }

  SubscriptionPlan _planFromPackage(SubscriptionPackage package, int price) {
    final month = package.month;
    final discountPercent = package.discount ?? _discountTable[month] ?? 0;
    return _planFromMonth(month, price, overrideDiscount: discountPercent);
  }

  SubscriptionPlan _planFromMonth(int month, int price,
      {int? overrideDiscount}) {
    final discountPercent = overrideDiscount ?? _discountTable[month] ?? 0;
    final subtotal = price * month;
    final discountAmount = (subtotal * discountPercent / 100).round();
    final payable = subtotal - discountAmount;
    return SubscriptionPlan(
      month: month,
      days: month * 30,
      amountPerMonth: price,
      subtotalAmount: subtotal,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      payableAmount: payable,
    );
  }

  int _computeMaxMonth(Map<String, dynamic>? availability) {
    final endingValue = availability?['ending']?.toString();
    if (endingValue != null && endingValue.isNotEmpty) {
      final parsed = DateTime.tryParse(endingValue);
      if (parsed != null) {
        final diff = parsed.difference(DateTime.now()).inDays;
        final months = max(1, diff ~/ 30);
        return min(_maxPurchasableMonth, months);
      }
    }
    return _maxPurchasableMonth;
  }

  int? _monthlyPrice(Map<String, dynamic>? price) {
    final candidates = [
      price?['monthly_price'],
      price?['monthlyPrice'],
      price?['monthly'],
      price?['monthly_price_tk'],
      price?['monthly_price_taka'],
    ];
    for (final candidate in candidates) {
      final extracted = _parseInt(candidate);
      if (extracted != null && extracted > 0) {
        return extracted;
      }
    }
    return null;
  }

  List<SubscriptionPackage> _normalizePackages(dynamic packages) {
    if (packages == null) return [];

    if (packages is String) {
      try {
        final data = json.decode(packages);
        return _normalizePackages(data);
      } catch (_) {
        return [];
      }
    }

    if (packages is List) {
      return packages
          .where((item) => item != null)
          .map((item) => item is Map ? _fromMap(item) : _fromMap({}))
          .where((pkg) => pkg.month > 0)
          .toList();
    }

    if (packages is Map) {
      // ✅ Case-1: direct {month:..., discount:...}
      if (packages.containsKey('month')) {
        final p = _fromMap(packages);
        return p.month > 0 ? [p] : [];
      }

      // ✅ Case-2: { "2": {month:..., discount:...}, ... }
      return packages.values
          .where((v) => v != null)
          .map((v) => v is Map ? _fromMap(v) : _fromMap({}))
          .where((pkg) => pkg.month > 0)
          .toList();
    }

    return [];
  }


  SubscriptionPackage _fromMap(Map<dynamic, dynamic> map) {
    final month = _parseInt(map['month']) ?? 0;
    final discount = _parseInt(map['discount']);
    return SubscriptionPackage(month: month, discount: discount);
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp('[^0-9]'), '');
      if (cleaned.isEmpty) return null;
      return int.tryParse(cleaned);
    }
    return null;
  }
}

class SubscriptionPlan {
  final int month;
  final int days;
  final int amountPerMonth;
  final int subtotalAmount;
  final int discountPercent;
  final int discountAmount;
  final int payableAmount;

  const SubscriptionPlan({
    required this.month,
    required this.days,
    required this.amountPerMonth,
    required this.subtotalAmount,
    required this.discountPercent,
    required this.discountAmount,
    required this.payableAmount,
  });

  bool get hasDiscount => discountAmount > 0;
}

class SubscriptionPackage {
  final int month;
  final int? discount;

  const SubscriptionPackage({
    required this.month,
    this.discount,
  });
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool selected;
  final AllEbook? package;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    this.package,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.primaryGradient();
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 6 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      gradient.colors.first.withOpacity(0.18),
                      Colors.white
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${plan.month} Month${plan.month > 1 ? 's' : ''} • ${plan.days} Days',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'TK. ${plan.amountPerMonth} / month',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Text('Subtotal: TK. ${plan.subtotalAmount}'),
              Text(
                'Discount: TK. ${plan.discountAmount} ${plan.hasDiscount ? '(${plan.discountPercent}% Off)' : ''}',
                style: TextStyle(
                  color: plan.hasDiscount
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Payable: '),
                  Text(
                    'TK. ${plan.payableAmount}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (plan.hasDiscount)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${plan.discountPercent}% Off',
                      style: const TextStyle(color: AppColors.onGradient),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String label;
  final String assetUrl;
  final String description;

  const _PaymentMethodTile({
    required this.label,
    required this.assetUrl,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Image.network(
              assetUrl,
              width: 52,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.payment),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
