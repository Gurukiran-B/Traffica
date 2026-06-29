import 'package:flutter/material.dart';
import '../models/community_photo.dart';
import '../services/api_service.dart';

typedef LikeCallback = void Function();
typedef ReportCallback = void Function();

class PhotoCard extends StatelessWidget {
  final CommunityPhoto photo;
  final LikeCallback onLike;
  final ReportCallback onReport;

  const PhotoCard({
    Key? key,
    required this.photo,
    required this.onLike,
    required this.onReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            '${ApiService.instance.baseUrl}${photo.imageUrl}',
            fit: BoxFit.cover,
            width: double.infinity,
            height: 240,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox(height: 240, child: Center(child: Text('Image Error'))),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(photo.description ?? "No description"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('Location: (${photo.latitude.toStringAsFixed(4)}, ${photo.longitude.toStringAsFixed(4)})'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('Route: ${photo.route ?? "N/A"}'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('Likes: ${photo.likes}  Reports: ${photo.reports}'),
          ),
          ButtonBar(
            children: [
              TextButton(
                onPressed: onLike,
                child: const Text('Like'),
              ),
              TextButton(
                onPressed: onReport,
                child: const Text('Report'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
