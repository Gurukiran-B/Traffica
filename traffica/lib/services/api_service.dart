import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config.dart';
import '../models/weather_data.dart';
import '../models/traffic_prediction.dart';
import '../models/fleet_status.dart';
import '../models/optimal_route_input.dart';
import '../models/route_result.dart';
import '../models/delivery_search_result.dart';
import '../models/road_alert.dart';
import '../models/community_photo.dart';

class ApiService {
  ApiService._internal()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
      onError: (e, handler) {
        return handler.next(e);
      },
    ));
  }

  static final ApiService instance = ApiService._internal();

  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

  Future<Map<String, dynamic>> uploadCommunityPhoto({
    required String userId,
    required double latitude,
    required double longitude,
    String? route,
    String? description,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        if (route != null) 'route': route,
        if (description != null) 'description': description,
        'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });
      final response = await _dio.post('/community/upload_photo', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Upload failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> uploadCommunityPhotoWeb({
    required String userId,
    required double latitude,
    required double longitude,
    String? route,
    String? description,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        if (route != null) 'route': route,
        if (description != null) 'description': description,
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final response = await _dio.post('/community/upload_photo', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Upload failed: ${e.message}');
    }
  }

  Future<List<dynamic>> getCommunityFeed({int skip = 0, int limit = 20, String? route}) async {
    try {
      final response = await _dio.get('/community/feed', queryParameters: {
        'skip': skip,
        'limit': limit,
        if (route != null) 'route': route,
      });
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Fetch feed failed: ${e.message}');
    }
  }

  // Stub method for getFleetStatus returning dummy data to avoid build errors
  Future<Map<String, dynamic>> getFleetStatus() async {
    // Provide realistic dummy response matching expected ApiService usage
    return {
      "status": "active",
      "vehicles": [
        {"id": "vehicle1", "location": {"lat": 12.9716, "lng": 77.5946}, "status": "idle"},
        {"id": "vehicle2", "location": {"lat": 12.2958, "lng": 76.6394}, "status": "en_route"},
      ],
    };
  }

  // Stub method for searchDeliveryAddresses to fix missing method error
  Future<List<dynamic>> searchDeliveryAddresses({required String query}) async {
    // Provide dummy result list with minimal address info
    return [
      {
        "address": "123 Main St",
        "city": "Sample City",
        "state": "Sample State",
        "pincode": "123456",
        "latitude": 12.9716,
        "longitude": 77.5946,
      },
      {
        "address": "456 Another Rd",
        "city": "Sample City",
        "state": "Sample State",
        "pincode": "654321",
        "latitude": 12.2958,
        "longitude": 76.6394,
      }
    ];
  }

  Future<Map<String, dynamic>> likeCommunityPhoto(String photoId) async {
    try {
      final response = await _dio.post('/community/like/$photoId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Like photo failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> reportCommunityPhoto(String photoId) async {
    try {
      final response = await _dio.post('/community/report/$photoId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Report photo failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> computeRoute({
    required List<Map<String, dynamic>> edges,
    required String start,
    required String end,
    Map<String, double>? heuristic,
  }) async {
    final payload = {
      'edges': edges,
      'start': start,
      'end': end,
      if (heuristic != null) 'heuristic': heuristic,
    };

    try {
      final res = await _dio.post('/route', data: payload);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Compute route failed: ${e.message}');
    }
  }

  Future<List<dynamic>> getTrafficPrediction({String location = "Mumbai"}) async {
    try {
      final res = await _dio.get('/predict_traffic', queryParameters: {'location': location});
      return res.data['predictions'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Get traffic prediction failed: ${e.message}');
    }
  }

  Future<List<dynamic>> getRoadAlerts({String? source, String? destination}) async {
    try {
      final res = await _dio.get('/alerts/search', queryParameters: {
        if (source != null) 'source': source,
        if (destination != null) 'destination': destination,
      });
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Get road alerts failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getOptimalRoute({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final res = await _dio.post('/optimal_route', data: payload);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Get optimal route failed: ${e.message}');
    }
  }
}


