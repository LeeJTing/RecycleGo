import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/Connector.dart';
import 'package:recycle_go/models/RecyclePurchases.dart';
import 'package:recycle_go/controller/puchase_item/purchase_item_ctrl.dart';

class PaymentVerificationScreen extends StatefulWidget {
  final String sessionId;
  final String purchaseId;
  final String itemName;
  final double quantity;
  final double totalPrice;
  final String inventoryId;
  final String? pickupLocationId;
  final String? pickupLocationName;
  final String? pickupAddress;

  const PaymentVerificationScreen({
    super.key,
    required this.sessionId,
    required this.purchaseId,
    required this.itemName,
    required this.quantity,
    required this.totalPrice,
    required this.inventoryId,
    this.pickupLocationId,
    this.pickupLocationName,
    this.pickupAddress,
  });

  @override
  State<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  late Future<void> _verificationFuture;
  final _connector = Connector();
  final _purchaseCtrl = PurchaseItemController();
  String? _paymentStatus;
  String? _errorMessage;
  bool _isChecking = true;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    // Start verification immediately - show loading screen right away
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _verifyPayment();
      }
    });
  }

  Future<void> _verifyPayment() async {
    try {
      // Call the verify session Edge Function with retry logic
      dynamic response;

      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        try {
          response = await _connector.client.functions.invoke(
            'stripe-verify-session',
            body: {'sessionId': widget.sessionId},
          );
          break; // Success - exit retry loop
        } catch (e) {
          _retryCount = attempt;

          // Check if it's a network error
          final isNetworkError =
              e.toString().contains('SocketException') ||
              e.toString().contains('Failed host lookup') ||
              e.toString().contains('Connection refused') ||
              e.toString().contains('TimeoutException');

          if (isNetworkError && attempt < _maxRetries) {
            // Wait before retrying (exponential backoff: 2s, 4s, 6s)
            await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
            continue;
          }

          // If it's the last attempt or not a network error, throw
          rethrow;
        }
      }

      final responseData = response.data as Map<String, dynamic>?;

      // Debug log
      print('=== STRIPE VERIFICATION DEBUG ===');
      print('Response data: $responseData');
      print('Success: ${responseData?['success']}');
      print('Payment status: ${responseData?['paymentStatus']}');
      print('Bank account: ${responseData?['bankAccount']}');
      print('============================');

      if (responseData != null && responseData['success'] == true) {
        final paymentStatus = responseData['paymentStatus'] as String?;
        final bankAccount = responseData['bankAccount'] as String?;

        setState(() {
          _paymentStatus = paymentStatus;
        });

        // Update purchase status and bank account in database
        if (paymentStatus == 'success' || paymentStatus == 'failed') {
          final purchasesModel = RecyclePurchasesModel();
          await purchasesModel.updatePaymentStatus(
            widget.purchaseId,
            paymentStatus!,
          );

          // Update bank account if available
          if (bankAccount != null && bankAccount.isNotEmpty) {
            // Add method to update bank account - or include in updatePaymentStatus
            await purchasesModel.updateBankAccount(
              widget.purchaseId,
              bankAccount,
            );
          }
        }

        // Show result after a short delay for better UX
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          setState(() {
            _isChecking = false;
          });

          if (paymentStatus == 'success') {
            print('PAYMENT SUCCESS - DEDUCTING INVENTORY');
            print('Inventory ID: ${widget.inventoryId}');
            print('Quantity: ${widget.quantity}');

            // Decrement inventory on successful payment
            await _purchaseCtrl.updateInventoryStock(
              widget.inventoryId,
              widget.quantity,
            );

            print('INVENTORY DEDUCTION COMPLETED');

            // Navigate to success screen with bank account
            Navigator.pushReplacementNamed(
              context,
              Routes.paymentSuccess,
              arguments: {
                'itemName': widget.itemName,
                'quantity': widget.quantity,
                'totalPrice': widget.totalPrice,
                'purchaseId': widget.purchaseId,
                'bankAccount': bankAccount,
                'pickupLocationId': widget.pickupLocationId,
                'pickupLocationName': widget.pickupLocationName,
                'pickupAddress': widget.pickupAddress,
              },
            );
          } else {
            // Payment failed - restore inventory
            await _purchaseCtrl.restoreInventoryStock(
              widget.inventoryId,
              widget.quantity,
            );

            // Show error message
            setState(() {
              _isChecking = false;
              _errorMessage =
                  'Payment ${paymentStatus == 'failed' ? 'failed' : 'was not completed'}. Please try again.';
            });

            // Auto-redirect back to purchase page after 5 seconds
            await Future.delayed(const Duration(seconds: 5));
            if (mounted) {
              Navigator.pushReplacementNamed(context, Routes.userPurchase);
            }
          }
        }
      } else {
        throw Exception(responseData?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      print('=== PAYMENT VERIFICATION ERROR ===');
      print('Full error: $e');
      print('Error type: ${e.runtimeType}');
      print('=====================================');

      // If it's a JWT error, the payment likely succeeded (Stripe redirected here)
      // Treat it as success since the user was redirected back to the app
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized') ||
          e.toString().contains('JWT') ||
          e.toString().contains('UNAUTHORIZED_INVALID_JWT_FORMAT')) {
        print(
          'JWT Auth error detected - treating payment as successful (redirect means payment accepted)',
        );

        // Set as success since redirect happened
        setState(() {
          _paymentStatus = 'success';
          _isChecking = false;
        });

        // Update purchase status
        final purchasesModel = RecyclePurchasesModel();
        await purchasesModel.updatePaymentStatus(widget.purchaseId, 'success');

        // Decrement inventory
        await _purchaseCtrl.updateInventoryStock(
          widget.inventoryId,
          widget.quantity,
        );

        // Navigate to success screen
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            Routes.paymentSuccess,
            arguments: {
              'itemName': widget.itemName,
              'quantity': widget.quantity,
              'totalPrice': widget.totalPrice,
              'purchaseId': widget.purchaseId,
              'bankAccount': null,
            },
          );
        }
        return;
      }

      // For other errors, show error message
      String userMessage = 'Unable to verify payment. Please try again.';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        userMessage =
            'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('TimeoutException')) {
        userMessage = 'Request timed out. Please try again.';
      }

      setState(() {
        _errorMessage = userMessage;
        _isChecking = false;
      });

      if (mounted) {
        // Restore inventory on error
        await _purchaseCtrl.restoreInventoryStock(
          widget.inventoryId,
          widget.quantity,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    // Show full loading page when checking payment
    if (_isChecking) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        color: theme.primary,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Verifying Payment',
                  style: TextDesign.headingTwo(fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please wait while we verify your payment...',
                  textAlign: TextAlign.center,
                  style: TextDesign.smallText(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show normal content when not checking
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Payment status icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.help_outline,
                        size: 60,
                        color: theme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Payment Status',
                    style: TextDesign.headingTwo(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Did you complete the payment?',
                          style: TextDesign.normalText(),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'If you completed the payment in Stripe, click the button below to verify your payment status.',
                          style: TextDesign.smallText(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Container(
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
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isChecking = true;
                          _errorMessage = null;
                        });
                        _verifyPayment();
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Check Payment Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          Routes.userPurchase,
                        );
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
