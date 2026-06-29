class RoadAlert {
  final String location;
  final String type;
  final String description;
  final int estimatedDelayMinutes;
  final String imageUrl;
  final String source;
  final String destination;

  RoadAlert({
    required this.location,
    required this.type,
    required this.description,
    required this.estimatedDelayMinutes,
    required this.imageUrl,
    required this.source,
    required this.destination,
  });

  factory RoadAlert.fromJson(Map<String, dynamic> json) {
    return RoadAlert(
      location: json['location'],
      type: json['type'],
      description: json['description'],
      estimatedDelayMinutes: json['estimated_delay_minutes'],
      imageUrl: json['image_url'],
      source: json['source'],
      destination: json['destination'],
    );
  }
}
