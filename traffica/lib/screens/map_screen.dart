import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/gradient_background.dart';
import '../widgets/mapbox_widget.dart';
import '../widgets/primary_button.dart';
import '../services/route_provider.dart';
import '../models/optimal_route_input.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/navigation_service.dart';
import '../services/weather_service.dart';
import '../models/weather_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../screens/prediction_screen.dart';

LatLng getCoordinatesForAddress(String address) {
  final entry = NavigationService.dummyAddresses.firstWhere(
    (e) => e['name'] == address,
    orElse: () => {'lat': 20.5937, 'lng': 78.9629}, // Default
  );
  return LatLng(entry['lat'], entry['lng']);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  Position? _currentPosition;
  String _selectedStartAddress = '';
  String _selectedEndAddress = '';
  bool _loadingRoute = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _tabController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _computeRoute() async {
    if (_selectedStartAddress.isEmpty || _selectedEndAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end locations')),
      );
      return;
    }

    setState(() => _loadingRoute = true);
    try {
      // For demo, use hardcoded coordinates based on selected addresses
      final startCoords = getCoordinatesForAddress(_selectedStartAddress);
      final endCoords = getCoordinatesForAddress(_selectedEndAddress);

      final result = await ApiService.instance.getOptimalRoute(
        payload: {
          'fromLocation': _selectedStartAddress,
          'toLocation': _selectedEndAddress,
          'time': DateTime.now().toIso8601String(),
          'weatherCondition': 'clear',
          'startLat': startCoords.latitude,
          'startLng': startCoords.longitude,
          'endLat': endCoords.latitude,
          'endLng': endCoords.longitude,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route: ${result['path'].join(' -> ')}, ETA: ${result['etaMinutes'].toStringAsFixed(1)} min')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error computing route: $e')),
      );
    } finally {
      setState(() => _loadingRoute = false);
    }
  }

  StreamSubscription<Position>? _positionStreamSubscription;

  Future<void> _getCurrentLocation() async {
    try {
      // Get initial position
      Position position = await LocationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _startController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });

      // Listen for updates
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        setState(() {
          _currentPosition = position;
          // Only update text if it was "Current Location" or coordinates
          if (_startController.text.contains(',') || _startController.text == 'Current Location') {
             _startController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          }
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Map', icon: Icon(Icons.map_rounded)),
            Tab(text: 'Weather', icon: Icon(Icons.cloud_outlined)),
            Tab(text: 'Routes', icon: Icon(Icons.alt_route_rounded)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: GradientBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            const MapboxWidget(), // Traffic layer with weather overlay
            _WeatherTab(),
            _RoutesTab(
              startController: _startController,
              endController: _endController,
              selectedStartAddress: _selectedStartAddress,
              selectedEndAddress: _selectedEndAddress,
              onStartAddressChanged: (address) => setState(() => _selectedStartAddress = address),
              onEndAddressChanged: (address) => setState(() => _selectedEndAddress = address),
              onComputeRoute: _computeRoute,
              loadingRoute: _loadingRoute,
              // --- ADDED: Pass current location if found ---
              currentPosition: _currentPosition,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherTab extends StatefulWidget {
  const _WeatherTab();

  @override
  State<_WeatherTab> createState() => _WeatherTabState();
}

class _WeatherTabState extends State<_WeatherTab> {
  String _selectedLocation = NavigationService.dummyAddresses.first['name'];
  WeatherData? _weather;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() => _loading = true);
    try {
      final weather = await WeatherService.getWeather(location: _selectedLocation);
      setState(() => _weather = weather);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch weather. Using demo data.')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Select Location', style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: _selectedLocation,
          items: NavigationService.dummyAddresses.map((address) {
            return DropdownMenuItem<String>(
              value: address['name'] as String,
              child: Text(address['name'] as String),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedLocation = value);
              _fetchWeather();
            }
          },
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_weather != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(_selectedLocation, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${_weather!.temperature.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 48)),
                  Text(_weather!.condition, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Humidity: ${_weather!.humidity.toStringAsFixed(1)}%'),
                  Text('Wind: ${_weather!.windSpeed.toStringAsFixed(1)} m/s'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RoutesTab extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController endController;
  final String selectedStartAddress;
  final String selectedEndAddress;
  final Function(String) onStartAddressChanged;
  final Function(String) onEndAddressChanged;
  final VoidCallback onComputeRoute;
  final bool loadingRoute;
  final Position? currentPosition;

  const _RoutesTab({
    required this.startController,
    required this.endController,
    required this.selectedStartAddress,
    required this.selectedEndAddress,
    required this.onStartAddressChanged,
    required this.onEndAddressChanged,
    required this.onComputeRoute,
    required this.loadingRoute,
    this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.alt_route, color: Colors.blue, size: 32),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Plan Your Journey',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter start and destination to get optimal routes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start Location Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.my_location, color: Colors.green.shade600, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Start Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    if ((startController.text.isEmpty || startController.text == 'Current Location') && currentPosition != null) {
                      // Prefill on first tap
                      startController.text = 'Current Location';
                      onStartAddressChanged('Current Location');
                    }
                  },
                  child: AbsorbPointer(
                    absorbing: false,
                    child: DropdownButtonFormField<String>(
                      value: selectedStartAddress.isEmpty ? null : selectedStartAddress,
                      hint: Text(currentPosition != null ? 'Current Location' : 'Tap to select start location'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      items: [
                        if (currentPosition != null)
                          DropdownMenuItem<String>(
                            value: 'Current Location',
                            child: Row(
                              children: [
                                Icon(Icons.gps_fixed, color: Colors.green.shade600),
                                const SizedBox(width: 8),
                                const Text('Current Location'),
                              ],
                            ),
                          ),
                        ...NavigationService.dummyAddresses.map((address) {
                          return DropdownMenuItem<String>(
                            value: address['name'] as String,
                            child: Row(
                              children: [
                                Icon(Icons.place, color: Colors.blue.shade600),
                                const SizedBox(width: 8),
                                Text(address['name'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        if (value != null) onStartAddressChanged(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Arrow Indicator
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_downward, color: Colors.blue, size: 24),
            ),
          ),

          const SizedBox(height: 16),

          // Destination Location Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red.shade600, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Destination',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedEndAddress.isEmpty ? null : selectedEndAddress,
                  hint: const Text('Tap to select destination'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  items: NavigationService.dummyAddresses.map((address) {
                    return DropdownMenuItem<String>(
                      value: address['name'] as String,
                      child: Row(
                        children: [
                          Icon(Icons.place, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Text(address['name'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) onEndAddressChanged(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Compute Route Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: loadingRoute
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PredictionScreen(
                            source: selectedStartAddress,
                            destination: selectedEndAddress,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: loadingRoute
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Computing route...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Get Optimal Route',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Start Navigation Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: selectedStartAddress.isEmpty || selectedEndAddress.isEmpty ? null : () {
                final startCoords = getCoordinatesForAddress(selectedStartAddress);
                final endCoords = getCoordinatesForAddress(selectedEndAddress);
                Navigator.pushNamed(
                  context,
                  '/navigation',
                  arguments: {
                    'source': selectedStartAddress,
                    'sourceCoords': startCoords,
                    'destination': selectedEndAddress,
                    'coords': endCoords,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Start Navigation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Routes are calculated using Bellman-Ford + A* hybrid algorithms for optimal performance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
