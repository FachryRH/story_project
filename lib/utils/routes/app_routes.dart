import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:story_project/data/repositories/auth_repository.dart';
import 'package:story_project/presentation/screens/add_story_screen.dart';
import 'package:story_project/presentation/screens/login_screen.dart';
import 'package:story_project/presentation/screens/register_screen.dart';
import 'package:story_project/presentation/screens/story_detail_screen.dart';
import 'package:story_project/presentation/screens/story_list_screen.dart';

class AppRoutes {
  final AuthRepository authRepository;

  AppRoutes(this.authRepository);

  late final router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authRepository),
    initialLocation: '/',
    redirect: (context, state) async {
      final isLoggedIn = await authRepository.isLoggedIn();
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !loggingIn) {
        return '/login';
      }

      if (isLoggedIn && loggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const StoryListScreen(),
        routes: [
          GoRoute(
            path: 'story/:id',
            name: 'story_detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return StoryDetailScreen(id: id);
            },
          ),
          GoRoute(
            path: 'add-story',
            name: 'add_story',
            builder: (context, state) => const AddStoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
}

// Custom refreshable stream for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  final AuthRepository _authRepository;
  bool _isLoggedIn = false;

  GoRouterRefreshStream(this._authRepository) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    if (isLoggedIn != _isLoggedIn) {
      _isLoggedIn = isLoggedIn;
      notifyListeners();
    }
  }

  void refresh() async {
    await _checkAuth();
  }
}