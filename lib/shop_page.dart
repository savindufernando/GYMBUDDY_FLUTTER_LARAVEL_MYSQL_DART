import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'product_detail_page.dart';
import 'widgets/bottom_nav.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart'; // ✅ Import Gyroscope Sensor

class ShopPage extends StatefulWidget {
  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  List<dynamic> products = [];
  Map<String, List<dynamic>> categorizedProducts = {};
  bool isLoading = true;
  bool hasError = false;
  int cartItemCount = 0;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String selectedCategory = "All"; // Default category
  File? _selectedImage;
  List<dynamic> imageSearchResults = [];
  final picker = ImagePicker();
  StreamSubscription? _gyroscopeSubscription;

  final List<String> supplementCategories = [
    'All', 'Creatine', 'Protein', 'Whey Protein', 'Mass Gainers', 'BCAAs',
    'Gainers', 'Glutamine', 'Pre Workout', 'Vitamins'
  ];

  final String apiUrl = 'https://gym-buddy.store/api/products';
  final String imageSearchApi = 'https://gym-buddy.store/api/search-by-image';

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _startGyroscopeListener();
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data is Map && data.containsKey('products')) {
          List<dynamic> allProducts = data['products'];

          Map<String, List<dynamic>> tempCategorizedProducts = {
            for (var category in supplementCategories) category: []
          };

          for (var product in allProducts) {
            String category = product['supplement_category'] ?? 'Others';
            if (supplementCategories.contains(category)) {
              tempCategorizedProducts[category]?.add(product);
            }
            tempCategorizedProducts["All"]?.add(product);
          }

          setState(() {
            products = allProducts;
            categorizedProducts = tempCategorizedProducts;
            isLoading = false;
            hasError = false;
            searchQuery = ""; // Reset search
            selectedCategory = "All"; // Reset category
          });
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception('Failed to load products: Status ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }
  void _startGyroscopeListener() {
    double shakeThreshold = 5.0; // Adjust sensitivity
    _gyroscopeSubscription = accelerometerEvents.listen((event) {
      double acceleration = (event.x * event.x + event.y * event.y + event.z * event.z);

      if (acceleration > shakeThreshold) {
        print("Shake detected! Refreshing...");
        fetchProducts();
      }
    });
  }
  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        // ✅ Request Camera Permission
        var status = await Permission.camera.request();
        if (status != PermissionStatus.granted) {
          print("Camera permission denied.");
          return;
        }
      }

      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        setState(() {
          _selectedImage = imageFile;
        });

        _searchByImage(imageFile);
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }


  Future<void> _searchByImage(File image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(imageSearchApi));
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseData);
        setState(() {
          imageSearchResults = data['products'];
        });
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Image Search Error: $error');
    }
  }

  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://gym-buddy.store/default-image.png';
    }
    return imagePath.replaceAll(RegExp(r'([^:])\/{2,}'), r'\1/');
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredProducts = searchQuery.isEmpty
        ? categorizedProducts[selectedCategory] ?? []
        : products.where((product) {
      return (product['supplement_name'] ?? '')
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Shop'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: "Search Products",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (query) {
                      setState(() {
                        searchQuery = query;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, size: 30),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                IconButton(
                  icon: Icon(Icons.photo_library, size: 30),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),

          if (searchQuery.isEmpty && imageSearchResults.isEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: supplementCategories.map((category) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          if (_selectedImage != null)
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  Image.file(_selectedImage!, height: 150),
                  SizedBox(height: 10),
                  Text('Searching for products...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : hasError
                ? Center(child: Text('Failed to load products.'))
                : (imageSearchResults.isNotEmpty
                ? imageSearchResults
                : filteredProducts).isEmpty
                ? Center(child: Text('No products found'))
                : GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72, // Adjusted for better spacing
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: (imageSearchResults.isNotEmpty ? imageSearchResults : filteredProducts).length,
              itemBuilder: (context, index) {
                final product = (imageSearchResults.isNotEmpty ? imageSearchResults : filteredProducts)[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailPage(
                          id: product['id'],
                          name: product['supplement_name'] ?? 'No Name',
                          price: product['price'].toString(),
                          imageUrl: getFullImageUrl(product['image']),
                          description: product['description'] ?? 'No description available',
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                          child: Image.network(
                            getFullImageUrl(product['image']),
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 140,
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['supplement_name'] ?? 'No Name',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 5),

                              // 💰 Product Price (Fixed)
                              Text(
                                product['price'] != null ? 'Rs ${product['price']}' : 'Price not available',
                                style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          ),
        ],
      ),
      bottomNavigationBar: BottomNav(currentIndex: 0, cartItemCount: cartItemCount),
    );
  }
}
