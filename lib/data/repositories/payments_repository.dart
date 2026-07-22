import '../../core/supabase/supabase_config.dart';

class RazorpayOrder {
  const RazorpayOrder({required this.orderId, required this.amount, required this.currency, required this.keyId});
  final String orderId;
  final int amount;
  final String currency;
  final String keyId;
}

/// Talks to the `razorpay-create-order` / `razorpay-verify-payment` edge
/// functions (see supabase/functions/) — the Razorpay secret key must never
/// ship inside the mobile client, so order creation + signature verification
/// stay server-side, mirroring src/lib/razorpay.functions.ts.
class PaymentsRepository {
  const PaymentsRepository();

  Future<RazorpayOrder> createOrder({required int amountPaise, String currency = 'INR', required String plan}) async {
    final res = await supabase.functions.invoke('razorpay-create-order', body: {
      'amount': amountPaise,
      'currency': currency,
      'plan': plan,
    });
    if (res.status != 200) {
      throw Exception((res.data is Map ? res.data['error'] : null) ?? 'Could not start payment');
    }
    final d = Map<String, dynamic>.from(res.data as Map);
    return RazorpayOrder(
      orderId: d['order_id'] as String,
      amount: (d['amount'] as num).toInt(),
      currency: d['currency'] as String,
      keyId: d['key_id'] as String,
    );
  }

  /// Returns the server-confirmed plan + expiry once verified — the source
  /// of truth is `profiles.plan` (updated server-side), not a local guess.
  /// The razorpay-webhook function activates the same fields independently,
  /// so Pro still unlocks even if this call never completes.
  Future<VerifiedPayment> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final res = await supabase.functions.invoke('razorpay-verify-payment', body: {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
    });
    if (res.status != 200) {
      throw Exception((res.data is Map ? res.data['error'] : null) ?? 'Verification failed');
    }
    final d = Map<String, dynamic>.from(res.data as Map);
    return VerifiedPayment(
      plan: d['plan'] as String? ?? 'pro',
      planExpiresAt: DateTime.tryParse(d['plan_expires_at'] as String? ?? ''),
    );
  }
}

class VerifiedPayment {
  const VerifiedPayment({required this.plan, this.planExpiresAt});
  final String plan;
  final DateTime? planExpiresAt;
}
