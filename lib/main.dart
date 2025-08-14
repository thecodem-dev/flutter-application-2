import 'package:flutter/material.dart';
import 'package:flutter_application_2/pages/about_page.dart';
import 'package:flutter_application_2/pages/ai_page.dart';
import 'package:flutter_application_2/pages/home_page.dart';
import 'package:flutter_application_2/pages/login_page.dart';
import 'package:flutter_application_2/pages/pricing_page.dart';
import 'package:flutter_application_2/pages/contact.dart';
import 'package:flutter_application_2/pages/register.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context)  {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      routes: {
        '/firstpage': (context) => HomePage(),
        '/pricingpage' : (context)=> PricingPage(),
        '/AbousUs_page' : (context)=> AboutUsPage(),
        '/AI_page' : (context)=> AIPage(),
        '/Login_page' : (context)=> LoginPage(),
        '/contact': (context) => Contact(),
        '/register': (context) => RegisterPage(),

      },      
    );
  }
}