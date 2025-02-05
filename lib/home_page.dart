import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shop_page.dart';
import 'services_page.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/cart_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool isSearchBarVisible = false;
  int cartItemCount = 0;
  bool isLoading = true;
  List<dynamic> products = []; // ✅ Fetch products from API

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    fetchProducts(); // ✅ Fetch products from API
  }

  /// ✅ Fetch Cart Items from API
  Future<void> fetchCartItems() async {
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
        Uri.parse('https://gym-buddy.store/api/cart'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          cartItemCount = (data['cart'] as List).length;
        });
      } else {
        print("❌ Error fetching cart: ${response.body}");
      }
    } catch (e) {
      print("❌ Network error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ✅ Fetch Products from API
  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('https://gym-buddy.store/api/products?orderBy=created_at&sort=asc&limit=6'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          setState(() {
            products = data.take(6).toList(); // ✅ Ensures only 6 products are stored
          });
        } else if (data is Map && data.containsKey('products')) {
          setState(() {
            products = List.from(data['products']).reversed.take(6).toList();
          });
        }
      } else {
        print("❌ Error fetching products: ${response.body}");
      }
    } catch (e) {
      print("❌ Network error: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Image.asset('assets/images/logo2.png', height: 40),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              setState(() {
                isSearchBarVisible = !isSearchBarVisible;
                _searchController.clear();
              });
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isLandscape = constraints.maxWidth > constraints.maxHeight;
          return _buildBody(context, isLandscape);
        },
      ),
      bottomNavigationBar: BottomNav(currentIndex: 0, cartItemCount: cartItemCount),
    );
  }

  /// ✅ Drawer
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Image.asset('assets/images/logo2.png'),
            decoration: BoxDecoration(color: Colors.white),
          ),
          _buildDrawerItem(Icons.star, 'Featured'),
          _buildDrawerItem(Icons.store, 'Collections'),
          _buildDrawerItem(Icons.shopping_cart, 'Cart'),
          _buildDrawerItem(Icons.history, 'Orders'),
          _buildDrawerItem(Icons.person, 'Account'),
          _buildDrawerItem(Icons.notifications, 'Notifications'),
          _buildDrawerItem(Icons.local_shipping, 'Shipping Policy'),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: () {});
  }

  /// ✅ Body (Products from API)
  Widget _buildBody(BuildContext context, bool isLandscape) {
    return isLoading
        ? Center(child: CircularProgressIndicator()) // ✅ Show loading indicator
        : SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/images/banner_home.jpg',
                fit: BoxFit.cover,
                height: isLandscape ? 150 : 200,
                width: double.infinity,
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    if (isSearchBarVisible)
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for products...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () {
                              setState(() {
                                searchQuery = _searchController.text;
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Recents Products', style: Theme.of(context).textTheme.headlineSmall),
          ),
          _buildProductGrid(isLandscape),
        ],
      ),
    );
  }

  /// ✅ Display Products from API
  Widget _buildProductGrid(bool isLandscape) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLandscape ? 4 : 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product['image'], product['supplement_name'], product['price']);
        },
      ),
    );
  }

  /// ✅ Product Card
  Widget _buildProductCard(String imageUrl, String title, String price) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rs $price', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
