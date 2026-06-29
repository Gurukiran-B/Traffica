import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_result.dart';

class NavigationService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  /// Fetches a driving route from OSRM API with ETA, distance, and cost
  static Future<RouteResult> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      '$_osrmBaseUrl/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final routes = data['routes'] as List<dynamic>;

      if (routes.isNotEmpty) {
        final route = routes[0];
        final geometry = route['geometry']['coordinates'] as List<dynamic>;
        final points = geometry.map((coord) => LatLng(coord[1] as double, coord[0] as double)).toList();
        final distance = route['distance'] as double;
        final duration = route['duration'] as double;
        // Mock cost calculation: ₹10 per km + ₹5 base
        final cost = (distance / 1000) * 10 + 5;

        return RouteResult(
          path: ['start', 'end'], // Simplified path
          totalCost: cost,
          etaMinutes: duration / 60,
          distanceKm: distance / 1000,
          points: points,
        );
      } else {
        throw Exception('No route found');
      }
    } else {
      throw Exception('Failed to fetch route: ${response.statusCode}');
    }
  }

  /// Dummy address suggestions for testing
  static const List<Map<String, dynamic>> dummyAddresses = [
    {'name': 'MG Road, Bengaluru', 'lat': 12.9740, 'lng': 77.6100},
    {'name': 'Whitefield, Bengaluru', 'lat': 12.9698, 'lng': 77.7499},
    {'name': 'Koramangala, Bengaluru', 'lat': 12.9352, 'lng': 77.6245},
    {'name': 'Indiranagar, Bengaluru', 'lat': 12.9719, 'lng': 77.6412},
    {'name': 'Electronic City, Bengaluru', 'lat': 12.8440, 'lng': 77.6636},
    {'name': 'Hebbal, Bengaluru', 'lat': 13.0456, 'lng': 77.5913},
    {'name': 'Jayanagar, Bengaluru', 'lat': 12.9250, 'lng': 77.5938},
    {'name': 'Bengaluru Central', 'lat': 12.9716, 'lng': 77.5946}, // legacy, fallback
    {'name': 'New Delhi', 'lat': 28.6139, 'lng': 77.2090},
    {'name': 'Chennai', 'lat': 13.0827, 'lng': 80.2707},
    {'name': 'Mysuru', 'lat': 12.2958, 'lng': 76.6394},
    {'name': 'Hyderabad', 'lat': 17.3850, 'lng': 78.4867},
    {'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777},
  ];
}
