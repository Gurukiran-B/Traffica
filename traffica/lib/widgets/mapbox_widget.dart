import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../models/weather_data.dart';
import '../models/route_result.dart';
import '../services/realtime_navigation_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../core/config.dart';

class MapboxWidget extends StatefulWidget {
  const MapboxWidget({super.key});

  @override
  State<MapboxWidget> createState() => _MapboxWidgetState();
}

class _MapboxWidgetState extends State<MapboxWidget> {
  MapController? _mapController;
  WeatherData? _weather;
  bool _loadingWeather = false;
  RouteResult? _routeResult;
  LatLng? _currentLocation;
  LatLng? _destination;
  bool _loadingRoute = false;
  bool _isNavigating = false;
  List<LatLng> _routePoints = [];
  int _currentStepIndex = 0;
  StreamSubscription<Position>? _positionStream;
  bool _hasLocationPermission = false;
  List<Marker> _markers = [];
  bool _locationFetched = false;
  bool _mapCentered = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _fetchWeather();
    _initializeLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (mounted) {
      setState(() {
        _hasLocationPermission = status.isGranted;
      });

      if (!_hasLocationPermission) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'This app needs access to your location for navigation and route planning. '
              'Your location will be used to:\n\n'
              '• Show your current position on the map\n'
              '• Provide turn-by-turn navigation\n'
              '• Find the best routes\n\n'
              'Please enable location permissions in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      } else {
        _initializeLocation();
      }
    }
  }

  Future<void> _initializeLocation() async {
    if (!_hasLocationPermission) return;

    try {
      // Get initial position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _locationFetched = true;
        });
        _updateMarkers();
        
        // Start listening to position updates
        _positionStream?.cancel();
        _positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) {
          if (mounted) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
            });
            _updateMarkers();
          }
        });
      }
    } catch (e) {
      print('Error initializing location: $e');
      // Fallback to last known position
      try {
        final position = await Geolocator.getLastKnownPosition();
        if (position != null && mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _locationFetched = true;
          });
          _updateMarkers();
        }
      } catch (e) {
        print('Error getting last known location: $e');
      }
    }
  }

  void _updateMarkers() {
    List<Marker> markers = [];
    
    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 20),
          ),
        ),
      );
    }
    
    // Add destination marker
    if (_destination != null) {
      markers.add(
        Marker(
          point: _destination!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.place, color: Colors.white, size: 20),
          ),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() => _loadingWeather = true);
    try {
      // Get current location for weather
      String location = 'Delhi'; // default
      if (_currentLocation != null) {
        // Use reverse geocoding or approximate location name
        // For now, use Bangalore if in Bangalore area
        if (_currentLocation!.latitude >= 12.8 && _currentLocation!.latitude <= 13.2 &&
            _currentLocation!.longitude >= 77.4 && _currentLocation!.longitude <= 77.8) {
          location = 'Bengaluru';
        }
      }
      final weather = await WeatherService.getWeather(location: location);
      if (mounted) setState(() => _weather = weather);
    } catch (e) {
      print('Error fetching weather: $e');
    } finally {
      if (mounted) setState(() => _loadingWeather = false);
    }
  }

  Future<void> _fetchRoute() async {
    if (_currentLocation == null || _destination == null || !mounted) return;

    setState(() => _loadingRoute = true);
    try {
      final routeResult = await RealtimeNavigationService.getRealtimeRoute(
        startLat: _currentLocation!.latitude,
        startLng: _currentLocation!.longitude,
        endLat: _destination!.latitude,
        endLng: _destination!.longitude,
      );

      if (mounted) {
        setState(() {
          _routeResult = routeResult;
          _routePoints = _convertPathToPoints(routeResult.path);
        });
        _updateMarkers();
      }
    } catch (e) {
      print('Error fetching route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch route. Try different locations or check connectivity.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  List<LatLng> _convertPathToPoints(List<String> path) {
    List<LatLng> points = [];
    
    if (_currentLocation != null && _destination != null) {
      points.add(_currentLocation!);
      
      for (int i = 1; i < path.length - 1; i++) {
        final ratio = i / (path.length - 1);
        final lat = _currentLocation!.latitude + 
            (_destination!.latitude - _currentLocation!.latitude) * ratio;
        final lng = _currentLocation!.longitude + 
            (_destination!.longitude - _currentLocation!.longitude) * ratio;
        points.add(LatLng(lat, lng));
      }
      
      points.add(_destination!);
    }
    
    return points;
  }

  Future<void> _startTurnByTurnNavigation() async {
    if (_routeResult == null || _routePoints.isEmpty || !mounted) return;

    setState(() => _isNavigating = true);
    
    if (_hasLocationPermission) {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((position) {
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });
          
          // Update map camera to follow user
          _mapController?.move(
            LatLng(position.latitude, position.longitude),
            16.0,
          );
          _updateMarkers();
        }
      });
    }
  }

  void _stopNavigation() {
    _positionStream?.cancel();
    if (mounted) {
      setState(() {
        _isNavigating = false;
        _currentStepIndex = 0;
      });
    }
  }

  void _setDestination(double lat, double lng) {
    if (mounted) {
      setState(() {
        _destination = LatLng(lat, lng);
      });
      _updateMarkers();
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    _setDestination(point.latitude, point.longitude);
  }

  @override
  Widget build(BuildContext context) {
    // Center map on current location after it's fetched
    if (_locationFetched && !_mapCentered && _currentLocation != null && _mapController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_mapCentered) {
          _mapController!.move(_currentLocation!, 16.0);
          setState(() {
            _mapCentered = true;
          });
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map with Mapbox-style tiles
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(12.9716, 77.5946), // Bangalore as default
              initialZoom: 12.0,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Mapbox-style tile layer
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=${AppConfig.getMapboxToken()}',
                additionalOptions: {
                  'accessToken': AppConfig.getMapboxToken() ?? '',
                },
                userAgentPackageName: 'com.traffica.mobility',
                maxZoom: 18,
                minZoom: 1,
              ),

              // Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(markers: _markers),
            ],
          ),

          // Location Permission Banner
          if (!_hasLocationPermission)
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Location permission needed for navigation',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: _requestLocationPermission,
                      child: const Text('Enable', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

          // Weather Overlay
          if (_weather != null)
            Positioned(
              top: 80,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.thermostat, color: Colors.red.shade400, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          '${_weather!.temperature.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weather!.condition,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Humidity: ${_weather!.humidity.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Route Info Card
          if (_routeResult != null)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.route, color: Colors.blue.shade700),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Route Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.timer_outlined,
                      'ETA',
                      '${_routeResult!.etaMinutes.toStringAsFixed(1)} min',
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.straighten,
                      'Distance',
                      '${_routeResult!.distanceKm?.toStringAsFixed(1) ?? "N/A"} km',
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.currency_rupee,
                      'Cost',
                      _routeResult!.costDisplay,
                      Colors.blue,
                    ),
                    if (_isNavigating) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.navigation, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Step ${_currentStepIndex + 1} of ${_routePoints.length}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Control Buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadingRoute ? null : _fetchRoute,
                    icon: _loadingRoute
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.route),
                    label: const Text('Plan Route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!_isNavigating)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _destination == null ? null : () {
                        Navigator.pushNamed(
                          context,
                          '/navigation',
                          arguments: {
                            'destination': 'Selected Destination',
                            'coords': _destination!,
                          },
                        );
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopNavigation,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Floating Action Button for Destination & Location
          Positioned(
            top: 100,
            left: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'dest_btn',
                  mini: true,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Set Destination'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDestinationButton('Delhi', 28.6139, 77.2090),
                            _buildDestinationButton('Mumbai', 19.0760, 72.8777),
                            _buildDestinationButton('Bangalore', 12.9716, 77.5946),
                            _buildDestinationButton('Chennai', 13.0827, 80.2707),
                            _buildDestinationButton('Hyderabad', 17.3850, 78.4867),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(Icons.place),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'locate_btn',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _initializeLocation,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationButton(String city, double lat, double lng) {
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: Text(city),
      onTap: () {
        _setDestination(lat, lng);
        Navigator.pop(context);
      },
    );
  }
}