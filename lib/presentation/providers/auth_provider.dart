import 'package:flutter/material.dart';
import 'package:story_project/data/repositories/auth_repository.dart';
import 'package:story_project/domain/models/user.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthRepository _authRepository;

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  User? _user;

  AuthProvider(this._authRepository) {
    checkAuthStatus();
  }

  void update(AuthRepository authRepository) {
    _authRepository = authRepository;
  }

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  User? get user => _user;

  Future<void> checkAuthStatus() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        _user = await _authRepository.getUser();
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email, password);
      _state = AuthState.authenticated;
      notifyListeners();
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.register(name, email, password);
      _state = AuthState.unauthenticated;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _authRepository.logout();
      _user = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
} 