import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/role_selection_screen.dart';
import 'src/screens/professional_teacher_dashboard.dart';
import 'src/screens/professional_student_dashboard.dart';
import 'pages/home_page.dart';
import 'pages/about_page.dart';
import 'pages/ai_page.dart';
import 'pages/contact.dart';
import 'pages/pricing_page.dart';

void main() {
  runApp(const EduApp());
}

class EduApp extends StatelessWidget {
  const EduApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseBlue = Colors.blue;
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: baseBlue),
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 1),
    );

    return MaterialApp(
      title: 'Edu Platform',
      theme: theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/login': (_) => const LoginScreen(),
        '/role-selection': (_) => const RoleSelectionScreen(),
        '/teacher': (_) => const ProfessionalTeacherDashboard(),
        '/student': (_) => const ProfessionalStudentDashboard(),
        '/AboutUs_page': (_) => const AboutUsPage(),
        '/AI_page': (_) => const AIPage(),
        '/contact': (_) => const Contact(),
        '/pricingpage': (_) => const PricingPage(),
      },
    );
  }
}
