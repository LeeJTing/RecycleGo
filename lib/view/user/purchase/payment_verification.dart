import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/Connector.dart';
import 'package:recycle_go/models/RecyclePurchases.dart';

class PaymentVerificationScreen extends StatefulWidget {
  final String sessionId;
  final String purchaseId;
  final String itemName;
  final double quantity;
  final double totalPrice;

  const PaymentVerificationScreen({
    super.key,
    required this.sessionId,
    required this.purchaseId,
    required this.itemName,
    required this.quantity,
    required this.totalPrice,
  });

  @override
  State<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  late Future<void> _verificationFuture;
  final _connector = Connector();
  String? _paymentStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verificationFuture = _verifyPayment();
  }

  Future<void> _verifyPayment() async {
    try {
      // Call the verify session Edge Function
      final response = await _connector.client.functions.invoke(
        'stripe-verify-session',
        body: {'sessionId': widget.sessionId},
      );

      final responseData = response.data as Map<String, dynamic>?;

      if (responseData != null && responseData['success'] == true) {
        final paymentStatus = responseData['paymentStatus'] as String?;

        setState(() {
          _paymentStatus = paymentStatus;
        });

        // Update purchase status in database
        if (paymentStatus == 'success' || paymentStatus == 'failed') {
          final purchasesModel = RecyclePurchasesModel();
          await purchasesModel.updatePaymentStatus(
            widget.purchaseId,
            paymentStatus!,
          );
        }

        // Show result after a short delay for better UX
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          if (paymentStatus == 'success') {
            // Navigate to success screen
            Navigator.pushReplacementNamed(
              context,
              Routes.paymentSuccess,
              arguments: {
                'itemName': widget.itemName,
                'quantity': widget.quantity,
                'totalPrice': widget.totalPrice,
                'purchaseId': widget.purchaseId,
              },
            );
          } else {
            // Navigate back with error
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment ${paymentStatus == 'failed' ? 'failed' : 'was not completed'}. Please try again.',
                ),
                backgroundColor: AppThemes.color.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        throw Exception(responseData?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: $e'),
            backgroundColor: AppThemes.color.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      color: theme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verifying Payment',
                style: TextDesign.headingTwo(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait...',
                style: TextDesign.smallText(color: Colors.grey[600]),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextDesign.smallText(color: theme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
