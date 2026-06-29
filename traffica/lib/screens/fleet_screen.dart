import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';
import '../models/fleet_status.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  FleetStatus? _fleetStatus;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchFleetStatus();
  }

  Future<void> _fetchFleetStatus() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.instance.getFleetStatus();
      final status = FleetStatus.fromJson(response);
      setState(() => _fleetStatus = status);
    } catch (e) {
      // Fallback to dummy data
      setState(() {
        _fleetStatus = FleetStatus(
          vehicles: [
            VehicleStatus(
              id: 'V001',
              currentLocation: '12.9716, 77.5946',
              status: 'en_route',
              source: 'Warehouse A',
              destination: 'Whitefield',
              etaMinutes: 45.0,
            ),
            VehicleStatus(
              id: 'V002',
              currentLocation: '12.9352, 77.6245',
              status: 'idle',
              source: 'Depot',
            ),
            VehicleStatus(
              id: 'V003',
              currentLocation: '12.9250, 77.5938',
              status: 'maintenance',
              source: 'Garage',
            ),
          ],
        );
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Status')),
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: GradientBackground(
        child: RefreshIndicator(
          onRefresh: _fetchFleetStatus,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_fleetStatus != null)
                ..._fleetStatus!.vehicles.map((vehicle) => GlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            vehicle.status == 'en_route' ? Icons.local_shipping :
                            vehicle.status == 'idle' ? Icons.pause_circle_filled :
                            Icons.build,
                            color: vehicle.status == 'en_route' ? Colors.green :
                                   vehicle.status == 'idle' ? Colors.orange :
                                   Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Vehicle ${vehicle.id}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Status: ${vehicle.status}'),
                      Text('Location: ${vehicle.currentLocation}'),
                      if (vehicle.source != null)
                        Text('Source: ${vehicle.source}'),
                      if (vehicle.destination != null)
                        Text('Destination: ${vehicle.destination}'),
                      if (vehicle.etaMinutes != null)
                        Text('ETA: ${vehicle.etaMinutes!.toStringAsFixed(1)} min'),
                    ],
                  ),
                ))
              else
                const Center(child: Text('No fleet data available')),
            ],
          ),
        ),
      ),
    );
  }
}
