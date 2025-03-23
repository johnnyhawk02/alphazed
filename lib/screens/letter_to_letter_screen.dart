import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../widgets/letter_button.dart';
import 'base_game_screen.dart';

class LetterToLetterMatch extends BaseGameScreen {
  const LetterToLetterMatch({super.key}) : super(title: 'Letter Matching');

  @override
  BaseGameScreenState<LetterToLetterMatch> createState() => _LetterToLetterMatchState();
}

class _LetterToLetterMatchState extends BaseGameScreenState<LetterToLetterMatch> {
  @override
  Widget buildPortraitLayout(GameState gameState, AudioService audioService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: Container(
              key: targetContainerKey,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
                boxShadow: [],
              ),
              child: buildLetterDropTarget(gameState, audioService),
            ),
          ),
        ),
        SizedBox(height: GameConfig.letterSpacing * 1.5),
        Expanded(
          flex: 2,
          child: buildLetterGrid(gameState, audioService),
        ),
        SizedBox(height: GameConfig.letterSpacing),
      ],
    );
  }

  @override
  Widget buildLandscapeLayout(GameState gameState, AudioService audioService) {
    return Row(
      children: [
        Expanded(
          child: Container(
            key: targetContainerKey,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
              boxShadow: [],
            ),
            child: buildLetterDropTarget(gameState, audioService),
          ),
        ),
        SizedBox(width: GameConfig.letterSpacing),
        Expanded(
          child: buildLetterGrid(gameState, audioService),
        ),
      ],
    );
  }

  Widget buildLetterDropTarget(GameState gameState, AudioService audioService) {
    final targetLetter = gameState.currentItem!.firstLetter.toUpperCase();
    
    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => true,
      onAcceptWithDetails: (data) async {
        final droppedLetter = data.data;
        if (droppedLetter.toLowerCase() != targetLetter.toLowerCase()) {
          playWrongAnimation();
          await audioService.playIncorrect();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius),
            border: Border.all(
              color: Colors.blue.shade300,
              width: 3,
            ),
          ),
          padding: const EdgeInsets.all(32.0),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              targetLetter,
              style: TextStyle(
                fontSize: 150,
                fontWeight: FontWeight.bold,
                color: GameConfig.primaryButtonColor,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildLetterGrid(GameState gameState, AudioService audioService) {
    return Center(
      child: Wrap(
        spacing: GameConfig.letterSpacing,
        runSpacing: GameConfig.letterSpacing,
        alignment: WrapAlignment.center,
        children: List.generate(
          gameState.currentOptions.length,
          (index) => AnimatedOpacity(
            duration: GameConfig.fadeAnimationDuration,
            opacity: index < gameState.visibleLetterCount && !gameState.isQuestionPlaying ? 1.0 : 0.0,
            child: LetterButton(
              key: ValueKey('letter_${gameState.currentOptions[index]}_$index'),
              letter: gameState.currentOptions[index],
              onTap: () => audioService.playLetter(gameState.currentOptions[index]),
              visible: index < gameState.visibleLetterCount && !gameState.isQuestionPlaying,
              onDragSuccess: (success) async {
                if (success && gameState.currentOptions[index].toLowerCase() == gameState.currentItem!.firstLetter.toLowerCase()) {
                  playCelebrationAnimation();
                  await Future.wait([
                    audioService.playAudio('assets/audio/other/bell.mp3'),
                    audioService.playCongratulations(),
                  ]);
                  
                  if (mounted && context.mounted) {
                    await mainController.reverse();
                    gameState.nextImage();
                    mainController.forward();
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}