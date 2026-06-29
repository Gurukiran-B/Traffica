import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/navigation_service.dart';
import '../services/realtime_navigation_service.dart';
import 'community_feed_screen.dart';

class NavigationScreen extends StatefulWidget {
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final String? startLabel;
  final String? endLabel;

  const NavigationScreen({
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.startLabel,
    this.endLabel,
    Key? key,
  }) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  List<Marker> _communityMarkers = [];
  bool _loading = false;
  String _status = 'Ready';
  bool _showCommunityLayer = true;
  bool _isNavigating = false;
  double _distanceKm = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.startLat != null &&
        widget.startLng != null &&
        widget.endLat != null &&
        widget.endLng != null) {
      _buildRoute(widget.startLat!, widget.startLng!, widget.endLat!, widget.endLng!);
    }
  }

  Future<void> _buildRoute(double sLat, double sLng, double eLat, double eLng) async {
    setState(() { _loading = true; _status = 'Calculating route...'; });
    try {
      final result = await RealtimeNavigationService.getRealtimeRoute(
        startLat: sLat,
        startLng: sLng,
        endLat: eLat,
        endLng: eLng,
      );
      
      if (result.points.isNotEmpty) {
        setState(() { 
          _routePoints = result.points; 
          _distanceKm = result.distanceKm ?? 0.0;
          _status = 'Ready to navigate'; 
        });
        
        final bounds = LatLngBounds.fromPoints(_routePoints);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );

        if (_routePoints.length > 2) {
          final midIndex = _routePoints.length ~/ 2;
          final alertPos = _routePoints[midIndex];
          
          setState(() {
            _communityMarkers = [
              Marker(
                point: alertPos,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CommunityFeedScreen()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ];
          });
        }
      }
    } catch (e) {
      print('Route error: $e');
      setState(() {
        _routePoints = [LatLng(sLat, sLng), LatLng(eLat, eLng)];
        _status = 'Error: ${e.toString().substring(0, 50)}...'; // Show first 50 chars of error
      });
      _mapController.move(LatLng(sLat, sLng), 13.0);
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Navigation Error'),
            content: Text('Failed to calculate route: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Road Construction'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reported 10 mins ago'),
            const SizedBox(height: 8),
            const Text('Single lane traffic due to bridge work. Expect delays.'),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                'https://picsum.photos/seed/construction/300/200', 
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120, 
                  color: Colors.grey[300], 
                  child: const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CommunityFeedScreen()),
              );
            },
            child: const Text('View Discussions'),
          ),
        ],
      ),
    );
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _status = 'Navigating to ${widget.endLabel ?? "Destination"}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = LatLng(
      widget.startLat ?? 12.9716,
      widget.startLng ?? 77.5946,
    );
    final end = LatLng(
      widget.endLat ?? 12.9352,
      widget.endLng ?? 77.6245,
    );

    return Scaffold(
      appBar: _isNavigating ? null : AppBar(title: const Text('Navigation')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: start,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.traffica',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(points: _routePoints, strokeWidth: 5.0, color: Colors.blue),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: start,
                    child: const Icon(Icons.my_location, color: Colors.green),
                  ),
                  Marker(
                    point: end,
                    child: const Icon(Icons.flag, color: Colors.red),
                  ),
                  if (_showCommunityLayer) ..._communityMarkers,
                ],
              ),
            ],
          ),
          // Debug Info
          Positioned(
            top: 100,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                'Start: ${start.latitude}, ${start.longitude}\nEnd: ${end.latitude}, ${end.longitude}\nPoints: ${_routePoints.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          if (!_isNavigating)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(_status)),
                      ElevatedButton(
                        onPressed: _loading
                            ? null
                            : _startNavigation,
                        child: _loading 
                          ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2)) 
                          : const Text('Start'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isNavigating)
            Positioned(
              top: 40,
              left: 12,
              right: 12,
              child: Card(
                color: Colors.blue,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '${_distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'to ${widget.endLabel ?? "Destination"}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'layer_toggle',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () => setState(() => _showCommunityLayer = !_showCommunityLayer),
            child: Icon(_showCommunityLayer ? Icons.layers : Icons.layers_clear, color: Colors.blue),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'community_btn',
            backgroundColor: Colors.orange,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CommunityFeedScreen()),
              );
            },
            child: const Icon(Icons.people),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'report_btn',
            backgroundColor: Colors.red,
            onPressed: () {
              Navigator.pushNamed(context, '/upload_photo');
            },
            child: const Icon(Icons.add_a_photo),
          ),
        ],
      ),
    );
  }
}
