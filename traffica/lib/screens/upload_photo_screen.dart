import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class UploadPhotoScreen extends StatefulWidget {
  const UploadPhotoScreen({Key? key}) : super(key: key);

  @override
  _UploadPhotoScreenState createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  final ApiService apiService = ApiService.instance;
  final _formKey = GlobalKey<FormState>();

  File? _selectedImage; // For mobile/desktop
  XFile? _pickedFile; // For web
  Uint8List? _pickedBytes; // For web preview

  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _pickedFile = picked;
            _pickedBytes = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(picked.path);
            _pickedFile = null;
            _pickedBytes = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selection failed: $e')));
    }
  }

  Future<void> _uploadPhoto() async {
    if (_formKey.currentState?.validate() != true ||
        (_selectedImage == null && (_pickedBytes == null || _pickedFile == null))) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete the form and select an image')));
      return;
    }

    if (_currentLat == null || _currentLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not fetched yet. Please wait.')));
      return;
    }

    setState(() => _isUploading = true);
    try {
      final userId = 'user123'; // Replace with actual authenticated userId if available
      final latitude = _currentLat!;
      final longitude = _currentLng!;
      final route = _routeController.text.isNotEmpty ? _routeController.text : null;
      final description = _descriptionController.text.isNotEmpty ? _descriptionController.text : null;

      final response = await (kIsWeb
          ? apiService.uploadCommunityPhotoWeb(
              userId: userId,
              latitude: latitude,
              longitude: longitude,
              route: route,
              description: description,
              fileBytes: _pickedBytes!,
              fileName: _pickedFile!.name,
            )
          : apiService.uploadCommunityPhoto(
              userId: userId,
              latitude: latitude,
              longitude: longitude,
              route: route,
              description: description,
              filePath: _selectedImage!.path,
            ));

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${response['message'] ?? 'Unknown error'}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  double? _currentLat;
  double? _currentLng;
  bool _fetchingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      setState(() {
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
        _fetchingLocation = false;
      });
    } catch (e) {
      setState(() => _fetchingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch location: $e')),
      );
    }
  }

  @override
  void dispose() {
    _routeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildImagePreview() {
    if (kIsWeb) {
      if (_pickedBytes != null) {
        return Image.memory(_pickedBytes!);
      } else {
        return const Placeholder(fallbackHeight: 200, fallbackWidth: double.infinity);
      }
    } else {
      if (_selectedImage != null) {
        return Image.file(
          _selectedImage!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        return const Placeholder(fallbackHeight: 200, fallbackWidth: double.infinity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Photo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImagePreview(),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Select Image'),
              ),
              const SizedBox(height: 20),
              if (_fetchingLocation)
                const Row(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(width: 12),
                    Text('Fetching location...'),
                  ],
                )
              else if (_currentLat != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location: ${_currentLat!.toStringAsFixed(4)}, ${_currentLng!.toStringAsFixed(4)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Text('Location not available', style: TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _routeController,
                decoration: const InputDecoration(
                  labelText: 'Route (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              _isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _uploadPhoto,
                      child: const Text('Upload Photo'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
