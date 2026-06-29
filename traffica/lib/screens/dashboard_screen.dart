import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: GradientBackground(
        child: RepaintBoundary(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _QuickStatCard(title: 'Live Traffic', icon: Icons.traffic_rounded, onTap: () => Navigator.pushReplacementNamed(context, '/map')),
                _QuickStatCard(title: 'Predictions', icon: Icons.show_chart_rounded, onTap: () => Navigator.pushReplacementNamed(context, '/prediction')),
                _QuickStatCard(title: 'Weather', icon: Icons.cloud_outlined, onTap: () => Navigator.pushReplacementNamed(context, '/map')),
                _QuickStatCard(title: 'Notifications', icon: Icons.notifications_active_outlined, onTap: () => Navigator.pushReplacementNamed(context, '/notifications')),
              ],
            ),
            const SizedBox(height: 20),
            const GlassCard(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('Traffic is moderate in your area. Expect slight delays due to weather conditions. Predictions indicate peak congestion between 5-6 PM.'),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickStatCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      height: 110,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
