import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'order_page.dart';
import 'login_option_page.dart';
import 'main.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  String profilePhotoUrl = "";
  bool isLoading = true;
  bool isEditing = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://gym-buddy.store/api/profile'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nameController.text = data['name'];
          _emailController.text = data['email'];
          profilePhotoUrl = data['profile_photo'] ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  Future<void> updateProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    try {
      var url = Uri.parse('https://gym-buddy.store/api/profile');

      var headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',  // ✅ Correct JSON format
      };

      var body = jsonEncode({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
      });

      var response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isEditing = false;
          profilePhotoUrl = data['user']['profile_photo_path'] ?? profilePhotoUrl;
        });
        fetchProfile();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated successfully!")));
      } else {
        print("Failed to update profile: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update profile")));
      }
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  Future<void> uploadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || _image == null) return;

    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://gym-buddy.store/api/profile/photo'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add the selected file to the request
      request.files.add(await http.MultipartFile.fromPath('profile_photo', _image!.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        setState(() {
          // Force a reload of the new profile photo URL
          profilePhotoUrl = data['profile_photo_path'];
        });

        // Reload the profile data (including the updated image)
        fetchProfile();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile photo updated successfully!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update profile photo")));
      }
    } catch (e) {
      print("Error uploading profile photo: $e");
    }
  }


  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = GymBuddyApp.themeNotifier.value == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrderPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: isEditing ? showImagePickerDialog : null,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300], // Placeholder color while loading
                    child: ClipOval(
                      child: Image.network(
                        "$profilePhotoUrl?t=${DateTime.now().millisecondsSinceEpoch}", // 🔹 Prevent image caching
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          } else {
                            return Center(child: CircularProgressIndicator()); // 🔹 Show loader while image loads
                          }
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.account_circle, size: 50, color: Colors.grey); // 🔹 Show default icon if image fails to load
                        },
                      ),
                    ),
                  ),
                ),
                if (!isEditing)
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                  ),
              ],
            ),

            SizedBox(height: 16),
            if (!isEditing)
              Column(
                children: [
                  Text(_nameController.text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_emailController.text),
                ],
              )
            else
              Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: updateProfile,
                    child: Text("Update Profile"),
                  ),
                ],
              ),
            SizedBox(height: 30),

            // ✅ "My Orders" Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderPage()),
                  );
                },
                icon: Icon(Icons.shopping_cart, color: Colors.white),
                label: Text("My Orders", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),

            SizedBox(height: 20),

            // ✅ Dark Mode Toggle
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              color: Theme.of(context).primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Dark Mode', style: TextStyle(color: Colors.white)),
                  Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      GymBuddyApp.themeNotifier.value =
                      value ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
