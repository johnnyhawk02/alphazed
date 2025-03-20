import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import '../config/game_config.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';

class GameScreen extends StatefulWidget {
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alphabet Learning Game',
          style: GoogleFonts.aBeeZee(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer2<GameState, AudioService>(
        builder: (context, gameState, audioService, _) {
          if (gameState.currentItem == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ImageDropTarget(
                      key: ValueKey(gameState.currentItem!.imagePath),
                      item: gameState.currentItem!,
                      onLetterAccepted: (letter) async {
                        if (letter == gameState.currentItem!.firstLetter) {
                          await audioService.playCongratulations();
                          if (mounted && context.mounted) {
                            gameState.nextImage();
                          }
                        } else {
                          if (mounted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Try Again!')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: GameConfig.letterSpacing),
              Expanded(
                flex: 2,
                child: Center(
                  child: Wrap(
                    spacing: GameConfig.letterSpacing,
                    runSpacing: GameConfig.letterSpacing,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      gameState.currentOptions.length,
                      (index) => LetterButton(
                        key: ValueKey('letter_${gameState.currentOptions[index]}_$index'),
                        letter: gameState.currentOptions[index],
                        onTap: () => audioService.playLetter(
                          gameState.currentOptions[index],
                        ),
                        visible: index < gameState.visibleLetterCount &&
                            !gameState.isQuestionPlaying,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: GameConfig.letterSpacing / 2),
            ],
          );
        },
      ),
    );
  }
}