import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'profile_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'shop_page.dart';
import 'services_page.dart';
import 'login_page.dart';
import 'themes/app_theme.dart';
import 'start.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Ensures Flutter is initialized
  runApp(GymBuddyApp());
}

class GymBuddyApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          title: 'Gym Buddy',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: StartPage(),
          routes: {
            '/home': (context) => HomePage(),
            '/shop': (context) => ShopPage(),
            '/profile': (context) => ProfilePage(),
            '/login': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
          },
        );
      },
    );
  }
}
