class CongestionPrediction {
  final DateTime timestamp;
  final double level;
  final String description;

  CongestionPrediction({
    required this.timestamp,
    required this.level,
    required this.description,
  });

  factory CongestionPrediction.fromJson(Map<String, dynamic> json) {
    return CongestionPrediction(
      timestamp: DateTime.parse(json['timestamp']),
      level: json['level'].toDouble(),
      description: json['description'],
    );
  }
}

class TrafficPrediction {
  final String location;
  final List<CongestionPrediction> predictions;

  TrafficPrediction({
    required this.location,
    required this.predictions,
  });

  factory TrafficPrediction.fromJson(Map<String, dynamic> json) {
    return TrafficPrediction(
      location: json['location'],
      predictions: (json['predictions'] as List)
          .map((p) => CongestionPrediction.fromJson(p))
          .toList(),
    );
  }
}
