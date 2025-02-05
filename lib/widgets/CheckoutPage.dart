import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'cart_page.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  double totalPrice = 0.0;
  String? checkoutUrl;

  final TextEditingController billingNameController = TextEditingController();
  final TextEditingController billingEmailController = TextEditingController();
  final TextEditingController billingPhoneController = TextEditingController();
  final TextEditingController billingAddressController = TextEditingController();
  final TextEditingController billingCityController = TextEditingController();
  final TextEditingController billingStateController = TextEditingController();
  final TextEditingController billingPostalCodeController = TextEditingController();
  final TextEditingController billingCountryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> checkout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final Map<String, String> billingData = {
      'billing_name': billingNameController.text,
      'billing_email': billingEmailController.text,
      'billing_phone': billingPhoneController.text,
      'billing_address': billingAddressController.text,
      'billing_city': billingCityController.text,
      'billing_state': billingStateController.text,
      'billing_postal_code': billingPostalCodeController.text,
      'billing_country': billingCountryController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('https://gym-buddy.store/api/checkout'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        body: jsonEncode(billingData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        checkoutUrl = data['session_url'];

        if (await canLaunchUrl(Uri.parse(checkoutUrl!))) {
          await launchUrl(Uri.parse(checkoutUrl!), mode: LaunchMode.externalApplication);
          checkPaymentStatus();
        } else {
          throw 'Could not launch checkout URL';
        }
      } else {
        print("Error during checkout: ${response.body}");
      }
    } catch (e) {
      print("Network error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Checkout")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: billingNameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: billingEmailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: billingPhoneController, decoration: InputDecoration(labelText: 'Phone')),
            TextField(controller: billingAddressController, decoration: InputDecoration(labelText: 'Address')),
            TextField(controller: billingCityController, decoration: InputDecoration(labelText: 'City')),
            TextField(controller: billingStateController, decoration: InputDecoration(labelText: 'State')),
            TextField(controller: billingPostalCodeController, decoration: InputDecoration(labelText: 'Postal Code')),
            TextField(controller: billingCountryController, decoration: InputDecoration(labelText: 'Country')),
            SizedBox(height: 10),
            ElevatedButton(onPressed: checkout, child: Text("Pay Now with Stripe")),
          ],
        ),
      ),
    );
  }

  void checkPaymentStatus() {}

  void fetchCartItems() {}
}
