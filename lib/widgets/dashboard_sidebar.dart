import 'package:flutter/material.dart';

class DashboardSidebar extends StatelessWidget {
  final String userType;
  final String currentPage;
  final Function(String) onNavigation;

  const DashboardSidebar({
    super.key,
    required this.userType,
    required this.currentPage,
    required this.onNavigation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          // Header with user info
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    userType == 'teacher' ? Icons.school : Icons.person,
                    size: 30,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userType == 'teacher'
                      ? 'Teacher Dashboard'
                      : 'Student Dashboard',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Welcome back!',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Navigation items
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: currentPage == 'dashboard',
            onTap: () => onNavigation('dashboard'),
          ),

          if (userType == 'teacher') ...[
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create Module'),
              selected: currentPage == 'create',
              onTap: () => onNavigation('create'),
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('My Modules'),
              selected: currentPage == 'modules',
              onTap: () => onNavigation('modules'),
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('My Modules'),
              selected: currentPage == 'modules',
              onTap: () => onNavigation('modules'),
            ),
          ],

          const Divider(),

          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('AI Assistant'),
            selected: currentPage == 'ai',
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.pushNamed(context, '/AI_page');
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            selected: currentPage == 'settings',
            onTap: () => onNavigation('settings'),
          ),

          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help'),
            selected: currentPage == 'help',
            onTap: () => onNavigation('help'),
          ),

          const Spacer(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
