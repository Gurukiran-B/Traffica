import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/community_photo.dart';
import '../widgets/photo_card.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({Key? key}) : super(key: key);

  @override
  _CommunityFeedScreenState createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final ApiService apiService = ApiService.instance;
  List<CommunityPhoto> photos = [];
  bool isLoading = false;
  int skip = 0;
  final int limit = 20;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPhotos();
      _startPolling();
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _refreshPhotos();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshPhotos() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    try {
      // Reset pagination and fetch fresh feed
      final data = await apiService.getCommunityFeed(skip: 0, limit: skip + limit);
      List<CommunityPhoto> refreshedPhotos = data
          .map((json) => CommunityPhoto.fromJson(json))
          .toList()
          .cast<CommunityPhoto>();
      setState(() {
        photos = refreshedPhotos;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh photos: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadPhotos() async {
    setState(() => isLoading = true);
    try {
      final data = await apiService.getCommunityFeed(skip: skip, limit: limit);
      List<CommunityPhoto> fetchedPhotos = data
          .map((json) => CommunityPhoto.fromJson(json))
          .toList()
          .cast<CommunityPhoto>();
      setState(() {
        photos.addAll(fetchedPhotos);
        skip += limit;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load photos: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _likePhoto(int index) async {
    try {
      final photoId = photos[index].id;
      final result = await apiService.likeCommunityPhoto(photoId);
      setState(() {
        photos[index] = CommunityPhoto(
          id: photos[index].id,
          userId: photos[index].userId,
          imageUrl: photos[index].imageUrl,
          latitude: photos[index].latitude,
          longitude: photos[index].longitude,
          route: photos[index].route,
          description: photos[index].description,
          likes: result['likes'] ?? photos[index].likes + 1,
          reports: photos[index].reports,
          timestamp: photos[index].timestamp,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to like photo: $e')));
    }
  }

  Future<void> _reportPhoto(int index) async {
    try {
      final photoId = photos[index].id;
      final result = await apiService.reportCommunityPhoto(photoId);
      setState(() {
        photos[index] = CommunityPhoto(
          id: photos[index].id,
          userId: photos[index].userId,
          imageUrl: photos[index].imageUrl,
          latitude: photos[index].latitude,
          longitude: photos[index].longitude,
          route: photos[index].route,
          description: photos[index].description,
          likes: photos[index].likes,
          reports: result['reports'] ?? photos[index].reports + 1,
          timestamp: photos[index].timestamp,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to report photo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Feed'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          photos.clear();
          skip = 0;
          await _loadPhotos();
        },
        child: ListView.builder(
          itemCount: photos.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < photos.length) {
              return PhotoCard(
                photo: photos[index],
                onLike: () => _likePhoto(index),
                onReport: () => _reportPhoto(index),
              );
            } else {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
          controller: ScrollController()
            ..addListener(() {
              if (!isLoading &&
                  photos.length >= limit &&
                  photos.length - 5 <= skip) {
                _loadPhotos();
              }
            }),
        ),
      ),
    );
  }
}
