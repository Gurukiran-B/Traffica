class TrafficPrediction {
  final DateTime timestamp;
  final double congestionIndex; // 0..1
  TrafficPrediction({required this.timestamp, required this.congestionIndex});
}

class NotificationItem {
  final String category;
  final String message;
  final DateTime createdAt;
  NotificationItem({required this.category, required this.message, required this.createdAt});
}


