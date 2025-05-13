import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:story_project/presentation/providers/story_provider.dart';
import 'package:story_project/presentation/widgets/error_view.dart';
import 'package:story_project/presentation/widgets/loading_indicator.dart';

class StoryDetailScreen extends StatefulWidget {
  final String id;

  const StoryDetailScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<StoryProvider>().getStoryDetail(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storyDetail),
      ),
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

          final story = storyProvider.selectedStory;
          if (story == null) {
            return Center(
              child: Text('Story not found'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'story_image_${story.id}',
                  child: CachedNetworkImage(
                    imageUrl: story.photoUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error,
                      size: 48,
                    ),
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
                              story.name.isNotEmpty ? story.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              story.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(story.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        story.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (story.lat != null && story.lon != null) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Location: ${story.lat!.toStringAsFixed(2)}, ${story.lon!.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ],
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

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 