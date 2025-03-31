import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/loading_screen.dart';
import 'models/game_state.dart';
import 'services/audio_service.dart';
import 'services/theme_provider.dart'; // Add Theme Provider
import 'package:provider/provider.dart';
import 'config/game_config.dart'; // Import GameConfig

// This ensures the app displays immediately
Future<void> precacheAssets(BuildContext context) async {
  // Preload key images to avoid initial load delays
  try {
    await precacheImage(const AssetImage('assets/icons/app_logo.png'), context);
    await precacheImage(const AssetImage('assets/icons/splash_icon.png'), context);
  } catch (e) {
    // Ignore errors, we'll continue anyway
    debugPrint('Error precaching assets: $e');
  }
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI to be compatible with splash screen
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: GameConfig.systemNavigationBarColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Create assets directory if it doesn't exist
  try {
    final assetsDir = Directory('${Directory.current.path}/assets');
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
  } catch (e) {
    print('Could not create assets directory: $e');
  }
  
  // Set preferred orientation to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioService>(
          create: (context) => AudioService(),
          dispose: (context, service) => service.dispose(),
        ),
        ChangeNotifierProxyProvider<AudioService, GameState>(
          create: (context) => GameState(
            audioService: Provider.of<AudioService>(context, listen: false),
          ),
          update: (context, audioService, previousGameState) => 
            previousGameState ?? GameState(audioService: audioService),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'AlphaZed',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: themeProvider.backgroundColor,
              canvasColor: themeProvider.backgroundColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: GameConfig.primaryButtonColor,
                background: themeProvider.backgroundColor,
                surface: themeProvider.backgroundColor,
              ),
              cardColor: themeProvider.backgroundColor,
              useMaterial3: true,
              appBarTheme: AppBarTheme(
                systemOverlayStyle: SystemUiOverlayStyle.light,
                backgroundColor: GameConfig.appBarBackgroundColor,
                elevation: 0,
                shadowColor: Colors.transparent,
                iconTheme: const IconThemeData(
                  opacity: 1.0, // Make app bar icons visible
                ),
              ),
            ),
            builder: (context, child) {
              // Preload assets as soon as the app starts
              precacheAssets(context);
              return child!;
            },
            // Custom page route to disable back button animations
            onGenerateRoute: (RouteSettings settings) {
              return null;
            },
            home: const LoadingScreen(),
            // Define routes that don't show back button
            routes: {
            },
          );
        },
      ),
    );
  }
}
