import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_page.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://gym-buddy.store/api/orders'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orders = data['orders'];
        });
      } else {
        print("❌ Error fetching orders: ${response.body}");
      }
    } catch (e) {
      print("❌ Network error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('https://gym-buddy.store/api/orders/update/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        fetchOrders();
      } else {
        print("❌ Error updating order: ${response.body}");
      }
    } catch (e) {
      print("❌ Network error: $e");
    }
  }

  void showOrderDetails(dynamic order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Order #${order['id']}"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Price: LKR ${double.tryParse(order['total_price']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}"),
                Text("Status: ${order['status']}", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text("Ordered Items:", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                order['items'] != null
                    ? Column(
                  children: List.generate(order['items'].length, (index) {
                    final item = order['items'][index];
                    return ListTile(
                      title: Text(item['name'] ?? 'Unknown Item'),
                      subtitle: Text("Quantity: ${item['quantity'] ?? 0} - LKR ${(double.tryParse(item['price'].toString())?.toStringAsFixed(2) ?? '0.00')} each"),
                      trailing: Text("Total: LKR ${(double.tryParse(item['price'].toString())! * (item['quantity'] ?? 0)).toStringAsFixed(2)}"),
                    );
                  }),
                )
                    : Text("No items found"),
                SizedBox(height: 10),
                if (order['status'] != 'delivered')
                  ElevatedButton(
                    onPressed: () {
                      updateOrderStatus(order['id'], 'delivered');
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text("Mark as Delivered"),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
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
        title: Text("My Orders"),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(child: Text("No orders found."))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text("Order #${order['id']}", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Status: ${order['status']}", style: TextStyle(color: Colors.blue)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => showOrderDetails(order),
            ),
          );
        },
      ),
    );
  }
}