import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'models/game_state.dart';
import 'config/game_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioService>.value(
          value: AudioService(),
        ),
        ChangeNotifierProvider<GameState>(
          create: (_) => GameState(audioService: AudioService())..loadGameItems(),
        ),
      ],
      child: MaterialApp(
        title: 'AlphaZed',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: GameConfig.primaryButtonColor,
          scaffoldBackgroundColor: GameConfig.defaultBackgroundColor,
          colorScheme: ColorScheme.light(
            primary: GameConfig.primaryButtonColor,
            secondary: GameConfig.secondaryButtonColor,
            surface: GameConfig.defaultBackgroundColor,
          ),
          textTheme: TextTheme(
            titleLarge: GameConfig.titleTextStyle,
            titleMedium: GameConfig.wordTextStyle,
            bodyLarge: GameConfig.bodyTextStyle,
            bodyMedium: GameConfig.bodyTextStyle,
          ).apply(
            displayColor: GameConfig.textColor,
            bodyColor: GameConfig.textColor,
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
