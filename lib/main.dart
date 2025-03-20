import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/game_screen.dart';
import 'services/audio_service.dart';
import 'models/game_state.dart';
import 'config/game_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AudioService audioService = AudioService();
  
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
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'ABeeZee',
          textTheme: TextTheme(
            titleLarge: GameConfig.titleTextStyle,
            titleMedium: GameConfig.wordTextStyle,
            bodyLarge: GameConfig.bodyTextStyle,
            bodyMedium: GameConfig.bodyTextStyle,
          ),
        ),
        home: GameScreen(),
      ),
    );
  }
}
