import 'package:flutter/material.dart';
import 'package:story_project/data/repositories/auth_repository.dart';
import 'package:story_project/data/repositories/story_repository.dart';
import 'package:story_project/domain/models/story.dart';

enum StoryState { initial, loading, loadingMore, loaded, error }

class StoryProvider extends ChangeNotifier {
  StoryRepository _storyRepository;
  AuthRepository _authRepository;

  StoryState _state = StoryState.initial;
  String? _errorMessage;
  List<Story> _stories = [];
  Story? _selectedStory;

  int _page = 1;
  final int _size = 10;
  bool _hasMore = true;

  StoryProvider(this._storyRepository, this._authRepository);

  void update(StoryRepository storyRepository, AuthRepository authRepository) {
    _storyRepository = storyRepository;
    _authRepository = authRepository;
  }

  StoryState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Story> get stories => _stories;
  Story? get selectedStory => _selectedStory;
  bool get hasMore => _hasMore;

  Future<void> refreshStories() async {
    _page = 1;
    _hasMore = true;
    _stories = [];
    await getStories();
  }

  Future<void> getStories() async {
    if (_state == StoryState.loadingMore || (!_hasMore && _page > 1)) {
      return;
    }

    _state = _stories.isEmpty ? StoryState.loading : StoryState.loadingMore;
    notifyListeners();

    try {
      final token = await _authRepository.getToken();
      if (token != null) {
        final newStories = await _storyRepository.getStories(
          token,
          page: _page,
          size: _size,
        );

        if (newStories.isEmpty || newStories.length < _size) {
          _hasMore = false;
        }

        if (_page == 1) {
          _stories = newStories;
        } else {
          _stories.addAll(newStories);
        }

        _page++;
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
        await refreshStories();
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
