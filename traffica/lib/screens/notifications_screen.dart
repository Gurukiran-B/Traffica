import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/gradient_background.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Traffic', Icons.traffic_rounded, 'Heavy traffic on NH44'),
      ('Delivery', Icons.local_shipping_outlined, 'Order #248 ETA updated'),
      ('Weather', Icons.cloud_outlined, 'Rain expected at 5 PM'),
      ('Traffic', Icons.warning_amber_outlined, 'Accident near Downtown'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      drawer: const AppDrawer(),
      body: GradientBackground(
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                leading: Icon(item.$2),
                title: Text(item.$1),
                subtitle: Text(item.$3),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            );
          },
        ),
      ),
    );
  }
}
