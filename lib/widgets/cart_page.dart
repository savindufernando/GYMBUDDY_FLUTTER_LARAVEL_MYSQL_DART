import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'CheckoutPage.dart';
import 'bottom_nav.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  /// ✅ Fetch Cart Items from API
  Future<void> fetchCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://gym-buddy.store/api/cart'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          cartItems = List<Map<String, dynamic>>.from(data['cart'] ?? []);
          calculateTotal();
        });
      } else {
        print("❌ Error fetching cart: ${response.body}");
      }
    } catch (e) {
      print("❌ Network error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ✅ Calculate Total Price
  void calculateTotal() {
    setState(() {
      totalPrice = cartItems.fold(0.0, (sum, item) {
        double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
        int quantity = item['quantity'] ?? 1;
        return sum + (price * quantity);
      });
    });
  }

  /// ✅ Remove Item from Cart (API)
  Future<void> removeFromCart(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final item = cartItems[index];

    if (item['id'] == null) {
      print("❌ Cart item ID is null, cannot delete");
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('https://gym-buddy.store/api/cart/remove/${item['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          cartItems.removeAt(index);
          calculateTotal();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Removed from cart ✅")));
      } else {
        print("❌ Failed to remove item: ${response.body}");
      }
    } catch (e) {
      print("❌ Network error: $e");
    }
  }

  /// ✅ Update Item Quantity in Cart (API)
  Future<void> updateCartItem(int cartItemId, int newQuantity) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (cartItemId == null || newQuantity < 1) {
      print("❌ Invalid cart item ID or quantity");
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('https://gym-buddy.store/api/cart/update/$cartItemId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'quantity': newQuantity}),
      );

      if (response.statusCode == 200) {
        setState(() {
          cartItems.firstWhere((item) => item['id'] == cartItemId)['quantity'] = newQuantity;
          calculateTotal();
        });
        print("✅ Cart updated successfully");
      } else {
        print("❌ Failed to update cart: ${response.body}");
      }
    } catch (e) {
      print("❌ Network error: $e");
    }
  }

  /// ✅ Function to Get Full Image URL
  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://gym-buddy.store/default-image.png'; // ✅ Default fallback image
    }
    return imagePath.startsWith('http') ? imagePath : 'https://gym-buddy.store/storage/${imagePath}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Cart")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? Center(child: Text("Your cart is empty 🛒"))
          : ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final item = cartItems[index];

          String imageUrl = getFullImageUrl(item['image']);
          String name = item['name'] ?? 'Unknown Product';
          String price = item['price']?.toString() ?? '0';
          int quantity = item['quantity'] ?? 1;

          return ListTile(
            leading: Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
              },
            ),
            title: Text(name),
            subtitle: Text("Rs $price x $quantity"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => updateCartItem(item['id'], quantity - 1),
                ),
                Text("$quantity"),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.green),
                  onPressed: () => updateCartItem(item['id'], quantity + 1),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => removeFromCart(index),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text("Total: Rs $totalPrice", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CheckoutPage()),
                    );
                  },
                  child: Text("Proceed to Checkout"),
                ),
              ],
            ),
          ),
          BottomNav(currentIndex: 1, cartItemCount: cartItems.length),
        ],
      )
          : BottomNav(currentIndex: 1, cartItemCount: 0),
    );
  }
}
