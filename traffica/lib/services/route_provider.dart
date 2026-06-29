import 'package:flutter/foundation.dart';
import '../models/route_result.dart';
import 'api_service.dart';

class RouteProvider extends ChangeNotifier {
  RouteResult? _result;
  bool _loading = false;
  Object? _error;

  RouteResult? get result => _result;
  bool get loading => _loading;
  Object? get error => _error;

  Future<void> fetchRoute({
    required List<Map<String, dynamic>> edges,
    required String start,
    required String end,
    Map<String, double>? heuristic,
  }) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.instance.computeRoute(
        edges: edges,
        start: start,
        end: end,
        heuristic: heuristic,
      );
      _result = RouteResult.fromJson(data);
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}


