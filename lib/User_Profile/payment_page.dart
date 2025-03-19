import 'package:flutter/material.dart';
import 'package:fyp_recipe/User_Profile/paypal_webview.dart';
import 'paypal_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PayPalService _payPalService = PayPalService();
  bool _isLoading = false;
  String? _paymentStatus;

  Future<void> _startPayment() async {
    setState(() => _isLoading = true);

    try {
      // Step 1: Create PayPal Payment
      String approvalUrl = await _payPalService.createPayPalPayment(10.0, 'USD');

      // Step 2: Open WebView for Approval
      var result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayPalWebView(approvalUrl: approvalUrl),
        ),
      );

      // Check result (user could cancel)
      if (result != null) {
        String paymentId = result['paymentId'];
        String payerId = result['PayerID'];

        // Step 3: Capture Payment
        bool isSuccess = await _payPalService.capturePayPalPayment(paymentId, payerId);

        setState(() {
          _paymentStatus = isSuccess ? 'Payment Successful ✅' : 'Payment Failed ❌';
        });
      } else {
        setState(() {
          _paymentStatus = 'Payment Cancelled 🚫';
        });
      }

      // Show dialog with payment status
      _showPaymentStatusDialog(_paymentStatus!);

    } catch (e) {
      setState(() {
        _paymentStatus = 'Error: $e';
      });

      _showPaymentStatusDialog(_paymentStatus!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show Payment Status Dialog
  void _showPaymentStatusDialog(String status) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          title: Text(
            status.trim().contains('Successful') ? 'Success' : 'Error',
            style: TextStyle(
              color: status.trim().contains('Successful') ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            status,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (status.trim().contains('Successful')) {
                  Navigator.of(context).pop(); // Go back after success
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recipedia',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Page Title
          SizedBox(height: 20),
          Center(
            child: Text(
              'Payment',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ),

          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Message
                  Center(
                    child: Text(
                      'Choose Your Payment Method:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),

                  // PayPal Button with Neumorphic Design
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // Background color (adjust to match your theme)
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                      boxShadow: [
                        // Light shadow (top-left) for raised effect
                        BoxShadow(
                          color: Colors.white,
                          offset: Offset(-3, -3),
                          blurRadius: 5,
                        ),
                        // Dark shadow (bottom-right) for depth
                        BoxShadow(
                          color: Colors.grey.shade600,
                          offset: Offset(3, 3),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _startPayment,
                      style: ElevatedButton.styleFrom(
                        elevation: 0, // Remove button's default shadow
                        backgroundColor: Colors.grey[200], // Match container color
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Same as container
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // PayPal Logo
                          Image.asset(
                            'assets/images/paypal_logo.jpg',
                            height: 30,
                          ),
                          SizedBox(width: 10),

                          // PayPal Text
                          Text(
                            'PayPal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

    );
  }
}
