import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
//import '../widgets/custom_footer.dart';

class Contact extends StatelessWidget {
  const Contact({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
    );
  }
}