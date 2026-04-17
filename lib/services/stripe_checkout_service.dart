import 'package:recycle_go/services/supabase_service.dart';

class StripeCheckoutService {
  static const String _functionName = 'stripe-create-checkout-session';

  Future<String> createCheckoutSession({
    required String voucherCode,
    required String userId,
    required String bankName,
    required String bankAccountNumber,
    required String voucherName,
    required int pointsRequired,
  }) async {
    try {
      final amountInCents = _deriveAmountInCents(
        voucherName: voucherName,
        pointsRequired: pointsRequired,
      );

      final response = await SupabaseService().client.functions.invoke(
        _functionName,
        body: {
          'voucherCode': voucherCode,
          'userId': userId,
          'bankName': bankName,
          'accountNumber': bankAccountNumber,
          'voucherName': voucherName,
          'amountInCents': amountInCents,
          'currency': 'myr',
        },
      );

      if (response.status < 200 || response.status >= 300) {
        final data = response.data;
        final errorMessage = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Failed to create Stripe checkout session';
        throw Exception(errorMessage);
      }

      final data = response.data;
      if (data is Map && data['checkoutUrl'] is String) {
        final url = data['checkoutUrl'].toString();
        if (url.isNotEmpty) {
          return url;
        }
      }

      throw Exception('Checkout URL not returned by Stripe function');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('404') ||
          msg.toLowerCase().contains('function not found')) {
        throw Exception(
          'Stripe checkout function not deployed. Run: supabase functions deploy $_functionName',
        );
      }
      rethrow;
    }
  }

  int _deriveAmountInCents({
    required String voucherName,
    required int pointsRequired,
  }) {
    // Prefer explicit monetary value in name like "$10" or "RM10.50".
    final match = RegExp(
      r'(?:rm|\$)?\s*(\d+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ).firstMatch(voucherName);
    if (match != null) {
      final parsed = double.tryParse(match.group(1) ?? '');
      if (parsed != null && parsed > 0) {
        return (parsed * 100).round();
      }
    }

    // Fallback mapping: 100 points == RM1.00.
    final fallback = (pointsRequired * 100) ~/ 100;
    return fallback > 0 ? fallback : 100;
  }
}
