import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/game_screen.dart';
import 'services/audio_service.dart';
import 'models/game_state.dart';
import 'config/game_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait and set system UI settings
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AudioService audioService = AudioService();

  MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioService>.value(
          value: audioService,
        ),
        ChangeNotifierProvider<GameState>(
          create: (_) => GameState(audioService: audioService)..loadGameItems(),
        ),
      ],
      child: MaterialApp(
        title: 'Alphabet Learning Game',
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
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: GameConfig.backgroundGradient,
            ),
            child: SafeArea(
              child: GameScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
