import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:story_project/data/api/auth_service.dart';
import 'package:story_project/data/api/story_service.dart';
import 'package:story_project/data/preferences/auth_preferences.dart';
import 'package:story_project/data/repositories/auth_repository.dart';
import 'package:story_project/data/repositories/story_repository.dart';
import 'package:story_project/l10n/l10n.dart';
import 'package:story_project/presentation/providers/auth_provider.dart';
import 'package:story_project/presentation/providers/locale_provider.dart';
import 'package:story_project/presentation/providers/story_provider.dart';
import 'package:story_project/utils/routes/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (context) => AuthService(),
        ),
        Provider(
          create: (context) => StoryService(),
        ),
        Provider(
          create: (context) => AuthPreferences(),
        ),
        ProxyProvider2<AuthService, AuthPreferences, AuthRepository>(
          update: (context, authService, authPreferences, previous) => 
              AuthRepository(authService, authPreferences),
        ),
        ProxyProvider<StoryService, StoryRepository>(
          update: (context, storyService, previous) => 
              StoryRepository(storyService),
        ),
        ChangeNotifierProvider(
          create: (context) => LocaleProvider(),
        ),
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthRepository>()),
          update: (context, authRepository, previous) => 
              previous!..update(authRepository),
        ),
        ChangeNotifierProxyProvider2<AuthRepository, StoryRepository, StoryProvider>(
          create: (context) => StoryProvider(
            context.read<StoryRepository>(),
            context.read<AuthRepository>(),
          ),
          update: (context, authRepository, storyRepository, previous) => 
              previous!..update(storyRepository, authRepository),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          final appRoutes = AppRoutes(context.read<AuthRepository>());
          
          return MaterialApp.router(
            title: 'Story App',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: L10n.all,
            locale: localeProvider.locale,
            routerConfig: appRoutes.router,
          );
        },
      ),
    );
  }
}
