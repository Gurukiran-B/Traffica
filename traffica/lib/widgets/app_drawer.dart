import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Profile'),
              onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () => Navigator.pushReplacementNamed(context, '/notifications'),
            ),
            ListTile(
              leading: const Icon(Icons.traffic_rounded),
              title: const Text('Traffic & Predictions'),
              onTap: () => Navigator.pushReplacementNamed(context, '/prediction'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('About'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Traffica',
                applicationVersion: '1.0.0',
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false),
            ),
          ],
        ),
      ),
    );
  }
}


