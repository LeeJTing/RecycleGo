import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/RecyclePurchases.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final RecyclePurchases purchase;

  const PurchaseDetailScreen({super.key, required this.purchase});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
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
                        pw.Text(widget.purchase.purchaseId ?? 'N/A'),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'Date:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(_formatDate(widget.purchase.createdAt)),
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
                            'Amount',
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
                          child: pw.Text('Recycled Item'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            _formatPrice(widget.purchase.totalPrice),
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
                          _formatPrice(widget.purchase.totalPrice),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (widget.purchase.bankAccount != null &&
                    widget.purchase.bankAccount!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Payment Details:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Bank Account: ${widget.purchase.bankAccount}'),
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
        '${output.path}/RecycleGo_Invoice_${widget.purchase.purchaseId}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      if (mounted) {
        await Share.shareXFiles([
          XFile(file.path),
        ], subject: 'RecycleGo Invoice - ${widget.purchase.purchaseId}');
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

  Color _getPaymentStatusColor(String status) {
    final theme = AppThemes.color;
    switch (status.toLowerCase()) {
      case 'success':
        return theme.success;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return theme.error;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double price) {
    return 'RM ${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;
    final statusColor = _getPaymentStatusColor(widget.purchase.paymentStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Purchase Details', style: TextDesign.normalText()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: theme.appbarBackground, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    statusColor.withOpacity(0.1),
                    statusColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Status',
                        style: TextDesign.smallText(color: Colors.grey[600]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          widget.purchase.paymentStatus.toUpperCase(),
                          style: TextDesign.badgeText(
                            color: statusColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatPrice(widget.purchase.totalPrice),
                    style: TextDesign.priceText(fontSize: 24),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details Section
            Text(
              'Purchase Information',
              style: TextDesign.headingThree(fontSize: size.width * 0.05),
            ),

            const SizedBox(height: 16),

            // Purchase ID
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Purchase ID',
                    style: TextDesign.smallText(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.purchase.purchaseId ?? 'N/A',
                          style: TextDesign.normalText(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          // Copy to clipboard
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Purchase ID copied!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // User ID
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User ID',
                    style: TextDesign.smallText(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.purchase.userId,
                    style: TextDesign.normalText(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Total Price
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextDesign.smallText(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatPrice(widget.purchase.totalPrice),
                        style: TextDesign.priceText(fontSize: 18),
                      ),
                    ],
                  ),
                  Icon(Icons.attach_money, color: theme.primary, size: 32),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Date
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Date & Time',
                        style: TextDesign.smallText(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(widget.purchase.createdAt),
                        style: TextDesign.normalText(fontSize: 14),
                      ),
                    ],
                  ),
                  Icon(Icons.calendar_today, color: theme.primary, size: 24),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            // Only show download invoice for successful payments
            if (widget.purchase.paymentStatus.toLowerCase() == 'success')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.deepOrange,
                  ),
                  onPressed: _isGeneratingInvoice
                      ? null
                      : _generateAndShareInvoice,
                  label: Text(
                    _isGeneratingInvoice
                        ? 'Generating Invoice...'
                        : 'Download Invoice',
                    style: TextDesign.badgeText(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            if (widget.purchase.paymentStatus.toLowerCase() == 'success')
              const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Need help? Contact support'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Text(
                  'Contact Support',
                  style: TextDesign.smallText(color: theme.primary),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
