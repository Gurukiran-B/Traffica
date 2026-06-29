import 'package:flutter/material.dart';
import '../models/delivery_search_result.dart';
import '../widgets/gradient_background.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class DeliverySearchScreen extends StatefulWidget {
  const DeliverySearchScreen({super.key});

  @override
  State<DeliverySearchScreen> createState() => _DeliverySearchScreenState();
}

class _DeliverySearchScreenState extends State<DeliverySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DeliverySearchResult> _searchResults = [];
  bool _isLoading = false;
  Position? _currentPosition;

  // Mock data for Bangalore areas
  final List<DeliverySearchResult> _mockResults = [
    DeliverySearchResult(
      address: "MG Road, Bangalore",
      city: "Bangalore",
      state: "Karnataka",
      pincode: "560001",
      latitude: 12.9716,
      longitude: 77.5946,
      deliveryType: "standard",
      deliveryFee: 50.0,
      estimatedTimeMinutes: 45,
    ),
    DeliverySearchResult(
      address: "Marathahalli, Bangalore",
      city: "Bangalore",
      state: "Karnataka",
      pincode: "560037",
      latitude: 12.9553,
      longitude: 77.6984,
      deliveryType: "express",
      deliveryFee: 75.0,
      estimatedTimeMinutes: 30,
    ),
    DeliverySearchResult(
      address: "Jayanagar, Bangalore",
      city: "Bangalore",
      state: "Karnataka",
      pincode: "560011",
      latitude: 12.9299,
      longitude: 77.5838,
      deliveryType: "same_day",
      deliveryFee: 100.0,
      estimatedTimeMinutes: 20,
    ),
    DeliverySearchResult(
      address: "Indiranagar, Bangalore",
      city: "Bangalore",
      state: "Karnataka",
      pincode: "560038",
      latitude: 12.9784,
      longitude: 77.6408,
      deliveryType: "standard",
      deliveryFee: 60.0,
      estimatedTimeMinutes: 35,
    ),
    DeliverySearchResult(
      address: "Koramangala, Bangalore",
      city: "Bangalore",
      state: "Karnataka",
      pincode: "560034",
      latitude: 12.9352,
      longitude: 77.6245,
      deliveryType: "express",
      deliveryFee: 70.0,
      estimatedTimeMinutes: 25,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await LocationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      // Handle error silently for delivery search
    }
  }

  void _searchAddresses(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final resultsJson = await ApiService.instance.searchDeliveryAddresses(query: query);
      final results = resultsJson.map<DeliverySearchResult>((json) => DeliverySearchResult.fromJson(json)).toList();
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      final filteredResults = _mockResults.where((result) {
        final searchTerm = query.toLowerCase();
        return result.address.toLowerCase().contains(searchTerm) ||
            result.city.toLowerCase().contains(searchTerm) ||
            result.state.toLowerCase().contains(searchTerm) ||
            result.pincode.contains(searchTerm);
      }).toList();

      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    }
  }

  String _getDeliveryTypeIcon(String type) {
    switch (type) {
      case 'standard':
        return '🚚';
      case 'express':
        return '⚡';
      case 'same_day':
        return '📦';
      default:
        return '🚚';
    }
  }

  Color _getDeliveryTypeColor(String type) {
    switch (type) {
      case 'standard':
        return Colors.blue;
      case 'express':
        return Colors.orange;
      case 'same_day':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner Search'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: GradientBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Enter delivery location (city, address, pincode)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
                onChanged: _searchAddresses,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty && _searchController.text.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.location_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No delivery locations found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try searching for a different location',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getDeliveryTypeColor(result.deliveryType).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getDeliveryTypeIcon(result.deliveryType),
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  result.address,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('${result.city}, ${result.state} - ${result.pincode}'),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getDeliveryTypeColor(result.deliveryType),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            result.deliveryType.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '₹${result.deliveryFee}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${result.estimatedTimeMinutes} min',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  onPressed: () async {
                                    if (_currentPosition != null) {
                                      try {
                                        final routeResultMap = await ApiService.instance.getOptimalRoute(
                                          payload: {
                                            'fromLocation': 'Current Location',
                                            'toLocation': result.address,
                                            'time': DateTime.now().toIso8601String(),
                                            'weatherCondition': 'clear',
                                            'startLat': _currentPosition!.latitude,
                                            'startLng': _currentPosition!.longitude,
                                            'endLat': result.latitude,
                                            'endLng': result.longitude,
                                          },
                                        );
                                        final path = routeResultMap['path'] as List<dynamic>;
                                        final etaMinutes = routeResultMap['total_cost'] as num;
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Route computed: ${path.join(' -> ')}, ETA: ${etaMinutes.toStringAsFixed(1)} min'),
                                              action: SnackBarAction(
                                                label: 'View Route',
                                                onPressed: () {
                                                  Navigator.pushNamed(context, '/map');
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error computing route: $e')),
                                          );
                                        }
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Current location not available')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: 3,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/map');
                break;
              case 1:
                Navigator.pushNamed(context, '/prediction');
                break;
              case 2:
                Navigator.pushNamed(context, '/fleet');
                break;
              case 3:
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
