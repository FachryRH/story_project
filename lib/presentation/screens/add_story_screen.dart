import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:story_project/presentation/providers/story_provider.dart';
import 'package:story_project/presentation/widgets/loading_indicator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:story_project/config/flavor_config.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({super.key});

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  File? _image;
  bool _isUploading = false;
  double? _lat;
  double? _lon;
  String? _address;
  late TabController _tabController;
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _tabController.dispose();
    _mapController?.dispose();
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
        _updateMarker(LatLng(_lat!, _lon!));
        _getAddressFromLatLng(_lat!, _lon!);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(_lat!, _lon!), 15),
      );
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

  Future<void> _getAddressFromLatLng(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address =
              '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Address not available';
      });
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

  void _updateMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId("selectedLocation"),
          position: position,
          infoWindow: InfoWindow(
            title: "Selected Location",
            snippet: _address ?? "Loading address...",
          ),
        ),
      );
      _lat = position.latitude;
      _lon = position.longitude;
    });
    _getAddressFromLatLng(position.latitude, position.longitude);
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
    final canAddLocation = FlavorConfig.instance.canAddLocation;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addStory)),
      body:
          _isUploading
              ? const LoadingIndicator()
              : Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (canAddLocation)
                      TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(icon: Icon(Icons.edit), text: l10n.details),
                          Tab(
                            icon: Icon(Icons.location_on),
                            text: l10n.location,
                          ),
                        ],
                      ),
                    Expanded(
                      child:
                          canAddLocation
                              ? TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildDetailsTab(l10n),
                                  _buildMapTab(l10n),
                                ],
                              )
                              : _buildDetailsTab(l10n),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _uploadStory,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(l10n.upload),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
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
              child:
                  _image != null
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
                            l10n.tapToAddPhoto,
                            style: TextStyle(color: Colors.grey[600]),
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
          if (!FlavorConfig.instance.canAddLocation) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.upgradeForLocation,
                      style: TextStyle(color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapTab(AppLocalizations l10n) {
    const CameraPosition initialPosition = CameraPosition(
      target: LatLng(-6.2, 106.8), // Jakarta
      zoom: 11.0,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _address ?? l10n.noLocationSelected,
                  style: TextStyle(
                    color: _address != null ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _getCurrentLocation,
                tooltip: l10n.getCurrentLocation,
              ),
            ],
          ),
        ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: initialPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: (LatLng position) {
              _updateMarker(position);
            },
          ),
        ),
      ],
    );
  }
}
