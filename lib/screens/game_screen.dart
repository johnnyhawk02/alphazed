import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import 'base_game_screen.dart';

class LetterPictureMatch extends BaseGameScreen {
  const LetterPictureMatch({super.key}) : super(title: 'Picture Matching');

  @override
  BaseGameScreenState<LetterPictureMatch> createState() => _LetterPictureMatchState();
}

class _LetterPictureMatchState extends BaseGameScreenState<LetterPictureMatch> {
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
              child: buildImageDropTarget(gameState, audioService),
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
            child: buildImageDropTarget(gameState, audioService),
          ),
        ),
        SizedBox(width: GameConfig.letterSpacing),
        Expanded(
          child: buildLetterGrid(gameState, audioService),
        ),
      ],
    );
  }

  Widget buildImageDropTarget(GameState gameState, AudioService audioService) {
    return Hero(
      tag: 'game_image_${gameState.currentItem!.imagePath}',
      child: ImageDropTarget(
        key: ValueKey(gameState.currentItem!.imagePath),
        item: gameState.currentItem!,
        onLetterAccepted: (letter) async {
          if (letter.toLowerCase() != gameState.currentItem!.firstLetter.toLowerCase()) {
            playWrongAnimation();
            await audioService.playIncorrect();
          }
        },
      ),
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