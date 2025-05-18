import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:story_project/presentation/providers/story_provider.dart';
import 'package:story_project/presentation/widgets/error_view.dart';
import 'package:story_project/presentation/widgets/loading_indicator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class StoryDetailScreen extends StatefulWidget {
  final String id;

  const StoryDetailScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final Set<Marker> _markers = {};
  String? _address;
  bool _isLoadingAddress = false;
  bool _locationDataProcessed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<StoryProvider>().getStoryDetail(widget.id);
    });
  }

  @override
  void didUpdateWidget(covariant StoryDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      // Story ID has changed, reset location-specific state
      _locationDataProcessed = false;
      _markers.clear();
      _address = null; // Or some initial loading state for address
      _isLoadingAddress = false; // Reset loading state for address as well
      // Fetch details for the new story
      Future.microtask(() {
        context.read<StoryProvider>().getStoryDetail(widget.id);
      });
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lon) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (mounted && placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address =
              '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = 'Address not available';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _setMarker(double lat, double lon) {
    if (!mounted) return;
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('storyLocation'),
          position: LatLng(lat, lon),
          infoWindow: InfoWindow(
            title: 'Story Location',
            snippet: _address ?? 'Loading address...',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storyDetail)),
      body: Consumer<StoryProvider>(
        builder: (context, storyProvider, child) {
          if (storyProvider.state == StoryState.loading) {
            return const LoadingIndicator();
          }

          if (storyProvider.state == StoryState.error) {
            return ErrorView(
              message: storyProvider.errorMessage ?? 'Unknown error',
              onRetry: () => storyProvider.getStoryDetail(widget.id),
            );
          }

          final storyFromProvider = storyProvider.selectedStory;

          // Ensure the story from provider is not null and matches the current widget's ID
          if (storyFromProvider == null || storyFromProvider.id != widget.id) {
            // If not, it means we're waiting for the correct story to load or provider to update.
            // This can happen during navigation or if the provider's state updates.
            // initState or didUpdateWidget should have already requested the correct story.
            return const LoadingIndicator();
          }

          // Now we are sure storyFromProvider is the correct story for this screen instance.
          // Let's use a clearer variable name for the rest of the scope.
          final currentStory = storyFromProvider;

          if (currentStory.lat != null &&
              currentStory.lon != null &&
              !_locationDataProcessed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _setMarker(currentStory.lat!, currentStory.lon!);
                _getAddressFromLatLng(currentStory.lat!, currentStory.lon!);
                _locationDataProcessed = true;
              }
            });
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'story_image_${currentStory.id}',
                  child: CachedNetworkImage(
                    imageUrl: currentStory.photoUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (context, url, error) =>
                            const Icon(Icons.error, size: 48),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              currentStory.name.isNotEmpty
                                  ? currentStory.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentStory.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(currentStory.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        currentStory.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (currentStory.lat != null &&
                          currentStory.lon != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child:
                                        _isLoadingAddress
                                            ? const Text("Loading address...")
                                            : Text(
                                              _address ??
                                                  "Address not available",
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 200,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(
                                        currentStory.lat!,
                                        currentStory.lon!,
                                      ),
                                      zoom: 14,
                                    ),
                                    markers: _markers,
                                    zoomControlsEnabled: false,
                                    mapToolbarEnabled: false,
                                    onTap: (_) {
                                      _showFullMap(
                                        currentStory.lat!,
                                        currentStory.lon!,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFullMap(double lat, double lon) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _address ?? "Location",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat, lon),
                      zoom: 16,
                    ),
                    markers: _markers,
                    zoomControlsEnabled: true,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
