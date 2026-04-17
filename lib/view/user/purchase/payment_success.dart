import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String itemName;
  final double quantity;
  final double totalPrice;
  final String purchaseId;
  final String? bankAccount;

  const PaymentSuccessScreen({
    super.key,
    required this.itemName,
    required this.quantity,
    required this.totalPrice,
    required this.purchaseId,
    this.bankAccount,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isGeneratingInvoice = false;

  Future<void> _generateAndShareInvoice() async {
    try {
      setState(() {
        _isGeneratingInvoice = true;
      });

      final pdf = pw.Document();
      final theme = AppThemes.color;
      final now = DateTime.now();
      final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'RecycleGo',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 16),

                // Invoice Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Invoice Number:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(widget.purchaseId),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'Date:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(dateFormat.format(now)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Items Table
                pw.Text(
                  'Order Details',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF32A852),
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Item',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Quantity (kg)',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Total Amount',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    // Data row
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(widget.itemName),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            widget.quantity.toStringAsFixed(2),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'RM ${widget.totalPrice.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Total Amount:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'RM ${widget.totalPrice.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (widget.bankAccount != null &&
                    widget.bankAccount!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Payment Details:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Bank Account: ${widget.bankAccount}'),
                ],

                pw.SizedBox(height: 32),

                // Footer
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Thank you for your purchase! This invoice is proof of your transaction.',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'RecycleGo - Sustainable Recycling Platform',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to file
      final output = await getApplicationDocumentsDirectory();
      final file = File(
        '${output.path}/RecycleGo_Invoice_${widget.purchaseId}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      if (mounted) {
        await Share.shareXFiles([
          XFile(file.path),
        ], subject: 'RecycleGo Invoice - ${widget.purchaseId}');
      }

      setState(() {
        _isGeneratingInvoice = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingInvoice = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                    colors: [theme.primary, theme.primary.withOpacity(0.85)],
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
                      widget.purchaseId,
                      theme,
                      isMonospace: true,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Item:', widget.itemName, theme),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Quantity:',
                      '${widget.quantity.toStringAsFixed(2)} kg',
                      theme,
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount:', style: TextDesign.normalText()),
                        Text(
                          'RM ${widget.totalPrice.toStringAsFixed(2)}',
                          style: TextDesign.headingOne(
                            color: theme.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    if (widget.bankAccount != null &&
                        widget.bankAccount!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Bank Account:',
                        widget.bankAccount!,
                        theme,
                      ),
                    ],
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
                  border: Border.all(color: theme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.primary, size: 24),
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
                    // Download Invoice Button - Only show for successful payments
                    if (widget.bankAccount != null ||
                        true) // Always show on success screen
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingInvoice
                              ? null
                              : _generateAndShareInvoice,
                          icon: _isGeneratingInvoice
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: Text(
                            _isGeneratingInvoice
                                ? 'Generating Invoice...'
                                : 'Download Invoice',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (widget.bankAccount != null ||
                        true) // Always show on success screen
                      const SizedBox(height: 12),
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
  Widget _buildDetailRow(
    String label,
    String value,
    dynamic theme, {
    bool isMonospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextDesign.smallText(color: Colors.grey[600])),
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
