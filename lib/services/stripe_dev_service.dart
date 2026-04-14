import 'package:recycle_go/services/supabase_service.dart';

class StripeDevService {
  static const String _functionName = 'stripe-process-payout-dev';

  Future<Map<String, dynamic>> processPayout({
    required String voucherCode,
    required String userId,
    required String bankName,
    required String bankAccountNumber,
  }) async {
    try {
      final response = await SupabaseService().client.functions.invoke(
        _functionName,
        body: {
          'voucherCode': voucherCode,
          'userId': userId,
          'bankName': bankName,
          'accountNumber': bankAccountNumber,
        },
      );

      if (response.status < 200 || response.status >= 300) {
        final data = response.data;
        final errorMessage = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Stripe development payout failed';
        throw Exception(errorMessage);
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'result': data};
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('404') ||
          msg.toLowerCase().contains('function not found')) {
        throw Exception(
          'Stripe dev function not deployed. Run: supabase functions deploy $_functionName',
        );
      }
      rethrow;
    }
  }
}
