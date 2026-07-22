import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/local/local_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/payments_repository.dart';
import '../auth/auth_controller.dart';

const _proPricePaise = 4900;

const _proFeatures = [
  'WhatsApp, SMS & Email alerts',
  'All alert channels included',
  'Priority AI Coach',
  'Net-worth timeline & EMI tracker',
  'Cloud sync across devices',
];

const _freeFeatures = ['Expense & budget tracking', 'Push reminders', 'Basic insights'];

/// Direct port of the PlansBlock component in settings.tsx — Free/Pro cards
/// + Razorpay checkout (native SDK instead of the web checkout.js script).
class PlansSheet extends ConsumerStatefulWidget {
  const PlansSheet({super.key, required this.currentPlan, required this.onPicked});
  final String currentPlan;
  final ValueChanged<String> onPicked;

  @override
  ConsumerState<PlansSheet> createState() => _PlansSheetState();
}

class _PlansSheetState extends ConsumerState<PlansSheet> {
  final _phone = TextEditingController();
  bool _paying = false;
  late Razorpay _razorpay;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
    LocalPrefs.getPhone().then((p) {
      if (mounted) _phone.text = p;
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _phone.dispose();
    super.dispose();
  }

  bool get _validPhone => RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.text.replaceAll(RegExp(r'\D'), ''));

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pay() async {
    if (!_validPhone) {
      _toast('Enter a valid mobile number first');
      return;
    }
    setState(() => _paying = true);
    try {
      final order = await const PaymentsRepository().createOrder(amountPaise: _proPricePaise, plan: 'pro');
      _pendingOrderId = order.orderId;
      final user = ref.read(authControllerProvider).user;
      _razorpay.open({
        'key': order.keyId,
        'amount': order.amount,
        'currency': order.currency,
        'order_id': order.orderId,
        'name': 'MoneyPilot',
        'description': 'Pro plan · 1 year',
        'prefill': {
          'name': (user?.userMetadata?['full_name'] as String?) ?? '',
          'contact': '+91${_phone.text}',
          'email': user?.email ?? '',
        },
        'theme': {'color': '#0F766E'},
      });
    } catch (e) {
      setState(() => _paying = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse r) async {
    try {
      // Server-side verification activates Pro on profiles.plan (and the
      // razorpay-webhook function does the same independently, in case this
      // call never completes) — the plan we cache locally is whatever the
      // server confirms, not an assumption made here.
      final verified = await const PaymentsRepository().verifyPayment(
        orderId: r.orderId ?? _pendingOrderId ?? '',
        paymentId: r.paymentId ?? '',
        signature: r.signature ?? '',
      );
      await LocalPrefs.setPlan(verified.plan);
      await LocalPrefs.setPhone(_phone.text);
      _toast('Payment successful — Pro unlocked instantly.');
      widget.onPicked(verified.plan);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse r) {
    setState(() => _paying = false);
    _toast(r.message ?? 'Payment failed');
  }

  @override
  Widget build(BuildContext context) {
    final isPro = widget.currentPlan == 'pro';
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose your plan', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          Text('Unlock WhatsApp & SMS alerts, exports and more.', style: TextStyle(fontSize: 14, color: colors.mutedForeground)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _PlanCard(name: 'Free', price: '₹0', suffix: '', features: _freeFeatures, highlight: false, active: !isPro)),
              const SizedBox(width: 10),
              Expanded(child: _PlanCard(name: 'Pro', price: '₹49', suffix: '/year', features: _proFeatures, highlight: true, active: isPro)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.primaryTint.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phone number for WhatsApp & SMS alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    height: 44,
                    width: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(10)),
                    child: const Text('+91', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(hintText: '10-digit mobile number', counterText: ''),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ]),
                if (_phone.text.isNotEmpty && !_validPhone)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Enter a valid Indian mobile number.', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.error)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: (!_validPhone || _paying || isPro) ? null : _pay,
              icon: _paying
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 20),
              label: Text(isPro ? "You're on Pro" : 'Pay ₹49 · Unlock Pro for 1 year'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 13, color: colors.mutedForeground),
              const SizedBox(width: 4),
              Text('Secured by Razorpay · PCI-DSS compliant', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.name, required this.price, required this.suffix, required this.features, required this.highlight, required this.active});
  final String name;
  final String price;
  final String suffix;
  final List<String> features;
  final bool highlight;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? colors.primaryTint.withValues(alpha: 0.4) : colors.card,
        border: Border.all(color: highlight ? scheme.primary : colors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlight)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(999)),
                child: const Text('POPULAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(suffix, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
          ]),
          const SizedBox(height: 8),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check, size: 16, color: scheme.primary),
                const SizedBox(width: 4),
                Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
              ]),
            ),
          if (active) Text('Current plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.primary)),
        ],
      ),
    );
  }
}
