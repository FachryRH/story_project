import 'package:story_project/data/api/story_service.dart';
import 'package:story_project/domain/models/story.dart';

class StoryRepository {
  final StoryService _storyService;

  StoryRepository(this._storyService);

  Future<List<Story>> getStories(String token, {int? page, int? size}) async {
    return await _storyService.getStories(token, page: page, size: size);
  }

  Future<Story> getStoryDetail(String token, String id) async {
    return await _storyService.getStoryDetail(token, id);
  }

  Future<void> addStory(
    String token,
    String description,
    List<int> photoBytes,
    String fileName, {
    double? lat,
    double? lon,
  }) async {
    await _storyService.addStory(
      token,
      description,
      photoBytes,
      fileName,
      lat: lat,
      lon: lon,
    );
  }
} 