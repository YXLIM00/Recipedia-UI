import 'dart:convert';
import 'package:http/http.dart' as http;

class PayPalService {
  // PayPal Sandbox Credentials
  final String clientId = 'AaNTCBQBeWsZ1Rmwj-vpnE6tkg9eMTFpmMjknYUowStx4RCRFXw450rZbnX2R6ZbkND_Es2ZWkav5rj4';
  final String secretKey = 'EC6T29o0d5yZUwGpBtCRCuP6hZmxoDLZfRtkmnZQZoJgCOU8qpinw0AcPhLONtD1cfe6QKZha-xcgzEj';

  // PayPal API Base URL (Sandbox for testing)
  final String baseUrl = 'https://api-m.sandbox.paypal.com';

  // Store access token once retrieved
  String? _accessToken;

  // Add this getter to expose the access token
  String? get accessToken => _accessToken;

  Future<void> getAccessToken() async {
    if (_accessToken != null) return; // Use existing token if available

    final response = await http.post(
      Uri.parse('$baseUrl/v1/oauth2/token'),
      headers: {
        'Authorization':
        'Basic ${base64Encode(utf8.encode('$clientId:$secretKey'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      _accessToken = body['access_token'];
    } else {
      throw Exception('Failed to get access token');
    }
  }

  Future<String> createPayPalPayment(double amount, String currency) async {
    // Ensure access token is available
    await getAccessToken();
    if (_accessToken == null) throw Exception('Failed to get access token');

    // Create paypal payment request
    final response = await http.post(
      Uri.parse('$baseUrl/v1/payments/payment'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "intent": "sale",
        "payer": {
          "payment_method": "paypal"
        },
        "transactions": [
          {
            "amount": {
              "total": amount.toStringAsFixed(2),
              "currency": currency
            },
            "description": "Premium Features Purchase"
          }
        ],
        "redirect_urls": {
          "return_url": "https://example.com/success",
          "cancel_url": "https://example.com/cancel"
        }
      }),
    );

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      final approvalUrl = body['links'].firstWhere(
            (link) => link['rel'] == 'approval_url',
        orElse: () => null,
      )['href'];

      if (approvalUrl != null) {
        return approvalUrl;
      } else {
        throw Exception('Failed to get approval URL');
      }
    } else {
      throw Exception('Failed to create payment');
    }
  }

  // Capture PayPal Payment
  Future<bool> capturePayPalPayment(String paymentId, String payerId) async {
    await getAccessToken();

    final response = await http.post(
      Uri.parse('$baseUrl/v1/payments/payment/$paymentId/execute'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({'payer_id': payerId}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final paymentStatus = body['state'];
      return paymentStatus == 'approved';
    } else {
      throw Exception('Failed to capture PayPal payment');
    }
  }

}


