import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class PayPalWebView extends StatefulWidget {
  final String approvalUrl;

  const PayPalWebView({super.key, required this.approvalUrl});

  @override
  State<PayPalWebView> createState() => _PayPalWebViewState();
}

class _PayPalWebViewState extends State<PayPalWebView> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.approvalUrl))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (url.contains('https://example.com/success')) {
              Uri uri = Uri.parse(url);
              String? paymentId = uri.queryParameters['paymentId'];
              String? payerId = uri.queryParameters['PayerID'];

              if (paymentId != null && payerId != null) {
                Navigator.pop(context, {'paymentId': paymentId, 'PayerID': payerId});
              }
            } else if (url.contains('https://example.com/cancel')) {
              Navigator.pop(context);
            }
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PayPal Payment')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
