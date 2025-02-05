import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];
  double totalPrice = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  // ✅ Load Cart Items from API
  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    print("🔑 Stored Token: $token"); // ✅ Debugging

    if (token == null) {
      print("⚠ No Auth Token Found!");
      setState(() { isLoading = false; });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/cart'),
        headers: {
          'Authorization': 'Bearer $token', // ✅ Make sure token is included
          'Accept': 'application/json',
        },
      );

      print("📡 Response Status: ${response.statusCode}");
      print("📡 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('message')) {
          print("⚠ ${data['message']}"); // Logs "Your cart is empty"
          setState(() { cartItems = []; });
        } else {
          setState(() {
            cartItems = List<Map<String, dynamic>>.from(data);
            totalPrice = cartItems.fold(0, (sum, item) => sum + (item['product']['price'] * item['quantity']));
          });
        }
      } else {
        print("❌ API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Cart")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? Center(child: Text("Your cart is empty"))
          : ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final item = cartItems[index]['product'];
          return ListTile(
            leading: Image.network(
              item['image'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.broken_image, size: 50),
            ),
            title: Text(item['name']),
            subtitle: Text("Rs ${item['price']} x ${cartItems[index]['quantity']}"),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () {}, // Implement remove function
            ),
          );
        },
      ),
    );
  }
}
