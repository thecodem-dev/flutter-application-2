import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isOnHomePage = currentRoute == '/' || currentRoute == null;

    return AppBar(
      leading: isOnHomePage
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/Picture1.png',
                fit: BoxFit.contain,
                height: 32,
              ),
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Go to Home',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
      title: const Center(
        child: Text(
          'FUNDISA',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/pricingpage');
          },
          child: const Text('Pricing', style: TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/AbousUs_page');
          },
          child: const Text('About Us', style: TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/AI_page');
          },
          child: Text('Chat With Disa', style: TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/Login_page');
          },
          child: Text('Login', style: TextStyle(color: Colors.black)),
        ),
      ],

      // ✅ Set different background color based on route
      backgroundColor: isOnHomePage
          ? Color(0xFFE0F7FA) // Light teal for homepage
          : Color.fromARGB(255, 255, 255, 255),// Light grey for other pages

      elevation: 4,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
