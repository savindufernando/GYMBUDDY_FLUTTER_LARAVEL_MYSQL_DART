import 'package:flutter/material.dart';
import 'cart_page.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartItemCount;

  BottomNav({required this.currentIndex, required this.cartItemCount});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.black, // Black background
      shape: CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.shopping_bag,
                color: currentIndex == 0 ? Colors.orange : Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pushNamed(context, '/shop'),
            ),
            FloatingActionButton(
              backgroundColor: Colors.orange,
              elevation: 5,
              child: Icon(Icons.home, color: Colors.black, size: 30),
              onPressed: () => Navigator.pushNamed(context, '/home'),
            ),
            IconButton(
              icon: Stack(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    color: currentIndex == 1 ? Colors.orange : Colors.white,
                    size: 28,
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          cartItemCount.toString(),
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                color: currentIndex == 2 ? Colors.orange : Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ),
    );
  }
}