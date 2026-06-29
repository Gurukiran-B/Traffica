import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/map');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/prediction');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/fleet');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/delivery_search');
            break;
          default:
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
        NavigationDestination(icon: Icon(Icons.show_chart_outlined), label: 'Predict'),
        NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Fleet'),
        NavigationDestination(icon: Icon(Icons.search_outlined), label: 'Delivery'),
      ],
    );
  }
}


