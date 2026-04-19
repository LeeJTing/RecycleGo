import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:recycle_go/app/app_theme.dart';

class StripeWebViewCheckout extends StatefulWidget {
  final String checkoutUrl;
  final VoidCallback onPaymentSuccess;
  final Function(String error) onPaymentError;

  const StripeWebViewCheckout({
    super.key,
    required this.checkoutUrl,
    required this.onPaymentSuccess,
    required this.onPaymentError,
  });

  @override
  State<StripeWebViewCheckout> createState() => _StripeWebViewCheckoutState();
}

class _StripeWebViewCheckoutState extends State<StripeWebViewCheckout> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  final theme = AppThemes.color;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started loading: $url');
            setState(() => _isLoading = true);

            // Check if URL contains success indicators
            if (_isSuccessRedirect(url)) {
              print('✅ Payment success redirect detected!');
              widget.onPaymentSuccess();
              Navigator.pop(context);
              return;
            }

            // Check for cancel/error redirects
            if (_isErrorRedirect(url)) {
              print('❌ Payment error/cancel detected');
              widget.onPaymentError('Payment was cancelled');
              Navigator.pop(context);
              return;
            }
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: ${error.description}');
            widget.onPaymentError('Connection error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request: ${request.url}');

            // Check for return URL after payment
            if (_isSuccessRedirect(request.url)) {
              print('✅ Payment successful - return URL detected');
              widget.onPaymentSuccess();
              return NavigationDecision.prevent;
            }

            if (_isErrorRedirect(request.url)) {
              print('❌ Payment cancelled/error - return URL detected');
              widget.onPaymentError('Payment was not completed');
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  bool _isSuccessRedirect(String url) {
    // Check for Stripe success indicators
    // Stripe returns to success_url or shows success page
    final successIndicators = [
      'success',
      'payment_intent',
      'redirect_status=succeeded',
      'status=success',
    ];

    return successIndicators.any((indicator) => url.contains(indicator));
  }

  bool _isErrorRedirect(String url) {
    // Check for Stripe error/cancel indicators
    final errorIndicators = [
      'cancel',
      'error',
      'fail',
      'redirect_status=failed',
      'status=cancel',
    ];

    return errorIndicators.any((indicator) => url.contains(indicator));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            Center(
              child: Container(
                color: Colors.black26,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: theme.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'Processing payment...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onPaymentError('Payment cancelled by user');
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(Icons.close, color: theme.error, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
