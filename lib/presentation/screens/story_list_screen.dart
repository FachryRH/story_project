import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:story_project/domain/models/story.dart';
import 'package:story_project/presentation/providers/auth_provider.dart';
import 'package:story_project/presentation/providers/locale_provider.dart';
import 'package:story_project/presentation/providers/story_provider.dart';
import 'package:story_project/presentation/widgets/empty_view.dart';
import 'package:story_project/presentation/widgets/error_view.dart';
import 'package:story_project/presentation/widgets/loading_indicator.dart';

class StoryListScreen extends StatefulWidget {
  const StoryListScreen({super.key});

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<StoryProvider>().getStories();
    });
  }

  void _refresh() {
    context.read<StoryProvider>().getStories();
  }

  void _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      context.goNamed('login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stories),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
            onPressed: _logout,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.language),
            tooltip: 'Language',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: const Text('English'),
              ),
              PopupMenuItem(
                value: 'id',
                child: const Text('Bahasa Indonesia'),
              ),
            ],
            onSelected: (value) {
              final locale = Locale(value);
              context.read<LocaleProvider>().setLocale(locale);
            },
          ),
        ],
      ),
      body: Consumer<StoryProvider>(
        builder: (context, storyProvider, child) {
          if (storyProvider.state == StoryState.loading) {
            return const LoadingIndicator();
          }

          if (storyProvider.state == StoryState.error) {
            return ErrorView(
              message: storyProvider.errorMessage ?? 'Unknown error',
              onRetry: _refresh,
            );
          }

          if (storyProvider.stories.isEmpty) {
            return EmptyView(onRetry: _refresh);
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              itemCount: storyProvider.stories.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
                final story = storyProvider.stories[index];
                return _buildStoryItem(story);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed('add_story'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStoryItem(Story story) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () => context.goNamed('story_detail', pathParameters: {'id': story.id}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: story.photoUrl,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
} 