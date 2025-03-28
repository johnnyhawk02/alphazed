import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/icon_generator_screen.dart';
import 'screens/loading_screen.dart';
import 'models/game_state.dart';
import 'services/audio_service.dart';
import 'package:provider/provider.dart';

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
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
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
      ],
      child: MaterialApp(
        title: 'AlphaZed',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CC9F0)),
          useMaterial3: true,
          // Disable back button in AppBar
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle.light,
            backgroundColor: Colors.transparent,
            elevation: 0,
            // Remove shadow and back button
            shadowColor: Colors.transparent,
            // This suppresses automatic back button
            iconTheme: IconThemeData(
              opacity: 0.0,
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
          if (settings.name == '/icon_generator') {
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (_, __, ___) => const IconGeneratorScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          }
          return null;
        },
        home: const LoadingScreen(),
        // Define routes that don't show back button
        routes: {
          '/icon_generator': (context) => const IconGeneratorScreen(),
        },
      ),
    );
  }
}
