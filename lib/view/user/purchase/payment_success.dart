import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String itemName;
  final double quantity;
  final double totalPrice;
  final String purchaseId;

  const PaymentSuccessScreen({
    super.key,
    required this.itemName,
    required this.quantity,
    required this.totalPrice,
    required this.purchaseId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Success Header with Icon
              Container(
                width: double.infinity,
                height: size.height * 0.25,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primary,
                      theme.primary.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Payment Successful!',
                        style: TextDesign.headingOne(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Order Details Card
              Container(
                margin: EdgeInsets.all(size.width * 0.05),
                padding: EdgeInsets.all(size.width * 0.05),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Confirmation',
                      style: TextDesign.headingTwo(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Order ID:',
                      purchaseId,
                      theme,
                      isMonospace: true,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Item:', itemName, theme),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Quantity:',
                      '${quantity.toStringAsFixed(2)} kg',
                      theme,
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: TextDesign.normalText(),
                        ),
                        Text(
                          'RM ${totalPrice.toStringAsFixed(2)}',
                          style: TextDesign.headingOne(
                            color: theme.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Info Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                padding: EdgeInsets.all(size.width * 0.04),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your order has been confirmed. You can view your purchase history anytime.',
                        style: TextDesign.smallText(color: theme.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Column(
                  children: [
                    // Continue Shopping Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.shopping_bag),
                        label: const Text('Continue Shopping'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // View History Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            Routes.userPurchaseHistory,
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('View Purchase History'),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget to build detail rows
  Widget _buildDetailRow(String label, String value, dynamic theme,
      {bool isMonospace = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextDesign.smallText(color: Colors.grey[600]),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: isMonospace
                ? TextDesign.smallText(
                    color: Colors.grey[800],
                  ).copyWith(fontFamily: 'monospace', fontSize: 11)
                : TextDesign.normalText(),
          ),
        ),
      ],
    );
  }
}
