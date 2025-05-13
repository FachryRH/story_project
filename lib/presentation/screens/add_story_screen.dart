import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:story_project/presentation/providers/story_provider.dart';
import 'package:story_project/presentation/widgets/loading_indicator.dart';
import 'package:geolocator/geolocator.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({super.key});

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  File? _image;
  bool _isUploading = false;
  double? _lat;
  double? _lon;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = position.latitude;
        _lon = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.gallery),
                onTap: () {
                  context.pop();
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(l10n.camera),
                onTap: () {
                  context.pop();
                  _getImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadStory() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.photoRequired),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      try {
        final bytes = await _image!.readAsBytes();
        final fileName = _image!.path.split('/').last;

        await context.read<StoryProvider>().addStory(
              _descriptionController.text,
              bytes,
              fileName,
              lat: _lat,
              lon: _lon,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.uploadSuccess),
              backgroundColor: Colors.green,
            ),
          );
          context.goNamed('home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.uploadError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addStory),
      ),
      body: _isUploading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.file(
                                  _image!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add photo',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.descriptionRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _lat != null && _lon != null
                                ? 'Location: ${_lat!.toStringAsFixed(2)}, ${_lon!.toStringAsFixed(2)}'
                                : 'No location selected',
                            style: TextStyle(
                              color: _lat != null ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _getCurrentLocation,
                          tooltip: 'Get current location',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _uploadStory,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(l10n.upload),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}