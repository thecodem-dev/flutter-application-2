import 'package:flutter/material.dart';
import 'dashboard_sidebar.dart';

class DashboardLayout extends StatelessWidget {
  final String title;
  final String userType;
  final String currentPage;
  final Widget child;
  final List<Widget>? actions;

  const DashboardLayout({
    super.key,
    required this.title,
    required this.userType,
    required this.currentPage,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: DashboardSidebar(
        userType: userType,
        currentPage: currentPage,
        onNavigation: (page) {
          // Handle navigation
          Navigator.of(context).pop(); // Close drawer
          // In a real app, you would handle page navigation here
        },
      ),
      body: child,
    );
  }
}
