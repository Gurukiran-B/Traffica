import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';
import '../services/route_provider.dart';
import '../services/api_service.dart';
import '../models/traffic_prediction.dart';
import '../models/road_alert.dart';
import '../models/community_photo.dart';
import '../screens/community_feed_screen.dart';
import '../core/config.dart';

class PredictionScreen extends StatefulWidget {
  final String source;
  final String destination;

  const PredictionScreen({
    Key? key,
    required this.source,
    required this.destination,
  }) : super(key: key);

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  TrafficPrediction? _trafficPrediction;
  bool _loadingPrediction = false;

  List<RoadAlert> _roadAlerts = [];
  bool _loadingAlerts = false;

  List<CommunityPhoto> _communityPhotos = [];
  bool _newPhotosAvailable = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchTrafficPrediction();
    _fetchRoadAlerts();
    _startCommunityFeedPolling();
  }

  Future<void> _fetchRoadAlerts() async {
    setState(() => _loadingAlerts = true);
    try {
      final alertsData = await ApiService.instance.getRoadAlerts();
      final alerts = alertsData
          .map((e) => RoadAlert.fromJson(e))
          .toList()
          .cast<RoadAlert>();
      setState(() => _roadAlerts = alerts);
    } catch (e) {
      debugPrint('Failed to fetch alerts: $e');
      setState(() => _roadAlerts = []);
    } finally {
      setState(() => _loadingAlerts = false);
    }
  }

  void _startCommunityFeedPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        final data = await ApiService.instance.getCommunityFeed(limit: 5);
        List<CommunityPhoto> fetchedPhotos = data
            .map((json) => CommunityPhoto.fromJson(json))
            .toList()
            .cast<CommunityPhoto>();

        bool hasNew = false;
        if (fetchedPhotos.isNotEmpty) {
          if (_communityPhotos.isEmpty) {
            hasNew = true;
          } else {
            final existingIds = _communityPhotos.map((e) => e.id).toSet();
            for (var photo in fetchedPhotos) {
              if (!existingIds.contains(photo.id)) {
                hasNew = true;
                break;
              }
            }
          }
        }

        if (hasNew) {
          setState(() {
            _newPhotosAvailable = true;
          });
        }
      } catch (_) {
        // Ignore errors on polling
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _openCommunityFeed() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommunityFeedScreen()),
    );
    setState(() {
      _newPhotosAvailable = false;
    });
  }

  Future<void> _onUploadPhotoResult(dynamic result) async {
    if (result == true) {
      await _fetchRoadAlerts();
    }
  }

  void _navigateToUploadPhoto() async {
    final result = await Navigator.of(context).pushNamed('/upload_photo');
    _onUploadPhotoResult(result);
  }

  Future<void> _fetchTrafficPrediction() async {
    setState(() => _loadingPrediction = true);
    try {
      final predictionsData = await ApiService.instance.getTrafficPrediction();
      final trafficPrediction = TrafficPrediction(
        location: widget.source,
        predictions: predictionsData
            .map((e) => CongestionPrediction.fromJson(e))
            .toList(),
      );
      setState(() => _trafficPrediction = trafficPrediction);
    } catch (_) {
      setState(() => _trafficPrediction = null);
    } finally {
      setState(() => _loadingPrediction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _navigateToUploadPhoto,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: Stack(
        children: [
          GradientBackground(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_loadingAlerts)
                  const GlassCard(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_roadAlerts.isNotEmpty)
                  ..._roadAlerts.map((alert) => GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (alert.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '${alert.imageUrl.startsWith("http") ? alert.imageUrl : "${AppConfig.apiBaseUrl}${alert.imageUrl}"}',
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('Could not load: ${AppConfig.apiBaseUrl}${alert.imageUrl} - Error: $error');
                                    return Container(
                                      color: Colors.grey.shade300,
                                      height: 150,
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                      child: const Text('No Image', style: TextStyle(color: Colors.black54)),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              alert.type,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.location,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(alert.description),
                            const SizedBox(height: 4),
                            Text(
                              'Estimated Delay: ${alert.estimatedDelayMinutes} min',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      )),
                if (!_loadingAlerts && _roadAlerts.isEmpty)
                  const GlassCard(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No major road/construction alerts!\nYour route is good to go.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Short-term Congestion Forecasts',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      RepaintBoundary(
                        child: SizedBox(
                          height: 180,
                          child: _loadingPrediction
                              ? const Center(child: CircularProgressIndicator())
                              : _trafficPrediction != null
                                  ? _TrafficPredictionChart(
                                      predictions: _trafficPrediction!.predictions)
                                  : const _ForecastChart(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_newPhotosAvailable)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(10),
                color: Colors.blueAccent,
                child: InkWell(
                  onTap: _openCommunityFeed,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'New community photos available! Tap to view.',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrafficPredictionChart extends StatelessWidget {
  final List<CongestionPrediction> predictions;

  const _TrafficPredictionChart({required this.predictions});

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    final primary = Theme.of(context).colorScheme.primary;
    final spots = predictions
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.level))
        .toList();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: true, border: Border.all(color: borderColor)),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: spots,
          ),
        ],
      ),
    );
  }
}

class _ForecastChart extends StatelessWidget {
  const _ForecastChart();

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    final primary = Theme.of(context).colorScheme.primary;
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: true, border: Border.all(color: borderColor)),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: const [
              FlSpot(0, 2), FlSpot(1, 2.5), FlSpot(2, 2.2), FlSpot(3, 3.2), FlSpot(4, 2.8), FlSpot(5, 3.6)
            ],
          ),
        ],
      ),
    );
  }
}
