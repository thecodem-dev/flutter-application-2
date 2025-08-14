import 'package:flutter/material.dart';

class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 176, 180, 181),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      height: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Row 1: Info texts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('About Us', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Services', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Help', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),

          SizedBox(height: 16),

          // Divider line
          const Divider(
            color: Colors.black,
            thickness: 1,
          ),

          SizedBox(height: 16),

          // Row 2: Social Media Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.facebook, size: 32, color: Color.fromARGB(255, 9, 83, 210)),
              SizedBox(width: 24),
              Icon(Icons.camera_alt, size: 32, color: Color.fromARGB(255, 71, 64, 174)),
              SizedBox(width: 24),
              Icon(Icons.mail_outline, size: 32, color: Color.fromARGB(255, 128, 172, 243)),
            ],
          ),
        ],
      ),
    );
  }
}
