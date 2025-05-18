import 'package:story_project/data/api/auth_service.dart';
import 'package:story_project/data/preferences/auth_preferences.dart';
import 'package:story_project/domain/models/user.dart';

class AuthRepository {
  final AuthService _authService;
  final AuthPreferences _authPreferences;

  AuthRepository(this._authService, this._authPreferences);

  Future<bool> isLoggedIn() async {
    return await _authPreferences.isLoggedIn();
  }

  Future<User?> getUser() async {
    return await _authPreferences.getUser();
  }

  Future<String?> getToken() async {
    return await _authPreferences.getToken();
  }

  Future<User> login(String email, String password) async {
    final user = await _authService.login(email, password);
    await _authPreferences.saveUser(user);
    await _authPreferences.saveToken(user.token);
    await _authPreferences.setLoggedIn(true);
    return user;
  }

  Future<void> register(String name, String email, String password) async {
    await _authService.register(name, email, password);
  }

  Future<void> logout() async {
    await _authPreferences.clearAuth();
  }
}
