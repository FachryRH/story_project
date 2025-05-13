import 'package:flutter/material.dart';
import 'package:story_project/data/repositories/auth_repository.dart';
import 'package:story_project/data/repositories/story_repository.dart';
import 'package:story_project/domain/models/story.dart';

enum StoryState {
  initial,
  loading,
  loaded,
  error,
}

class StoryProvider extends ChangeNotifier {
  StoryRepository _storyRepository;
  AuthRepository _authRepository;

  StoryState _state = StoryState.initial;
  String? _errorMessage;
  List<Story> _stories = [];
  Story? _selectedStory;

  StoryProvider(this._storyRepository, this._authRepository);

  void update(StoryRepository storyRepository, AuthRepository authRepository) {
    _storyRepository = storyRepository;
    _authRepository = authRepository;
  }

  StoryState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Story> get stories => _stories;
  Story? get selectedStory => _selectedStory;

  Future<void> getStories() async {
    _state = StoryState.loading;
    notifyListeners();

    try {
      final token = await _authRepository.getToken();
      if (token != null) {
        _stories = await _storyRepository.getStories(token);
        _state = StoryState.loaded;
      } else {
        _state = StoryState.error;
        _errorMessage = 'Authentication token not found';
      }
    } catch (e) {
      _state = StoryState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> getStoryDetail(String id) async {
    _state = StoryState.loading;
    notifyListeners();

    try {
      final token = await _authRepository.getToken();
      if (token != null) {
        _selectedStory = await _storyRepository.getStoryDetail(token, id);
        _state = StoryState.loaded;
      } else {
        _state = StoryState.error;
        _errorMessage = 'Authentication token not found';
      }
    } catch (e) {
      _state = StoryState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> addStory(
    String description,
    List<int> photoBytes,
    String fileName, {
    double? lat,
    double? lon,
  }) async {
    _state = StoryState.loading;
    notifyListeners();

    try {
      final token = await _authRepository.getToken();
      if (token != null) {
        await _storyRepository.addStory(
          token,
          description,
          photoBytes,
          fileName,
          lat: lat,
          lon: lon,
        );
        await getStories(); // Refresh stories after adding
      } else {
        _state = StoryState.error;
        _errorMessage = 'Authentication token not found';
        notifyListeners();
      }
    } catch (e) {
      _state = StoryState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
} 