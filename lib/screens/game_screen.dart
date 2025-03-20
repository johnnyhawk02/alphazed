import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import '../config/game_config.dart';
import '../services/audio_service.dart';

class GameScreen extends StatefulWidget {
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Alphabet Learning Game',
              style: GameConfig.titleTextStyle,
            ),
          ),
          body: Consumer2<GameState, AudioService>(
            builder: (context, gameState, audioService, _) {
              if (gameState.currentItem == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return SafeArea(
                child: orientation == Orientation.portrait ? buildPortraitLayout(gameState, audioService) : buildLandscapeLayout(gameState, audioService),
              );
            },
          ),
        );
      }
    );
  }

  Widget buildPortraitLayout(GameState gameState, AudioService audioService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: GameConfig.defaultPadding),
              child: buildImageDropTarget(gameState, audioService),
            ),
          ),
        ),
        SizedBox(height: GameConfig.letterSpacing),
        Expanded(
          flex: 2,
          child: buildLetterGrid(gameState, audioService),
        ),
        SizedBox(height: GameConfig.letterSpacing / 2),
      ],
    );
  }

  Widget buildLandscapeLayout(GameState gameState, AudioService audioService) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(GameConfig.defaultPadding),
            child: buildImageDropTarget(gameState, audioService),
          ),
        ),
        Expanded(
          child: buildLetterGrid(gameState, audioService),
        ),
      ],
    );
  }

  Widget buildImageDropTarget(GameState gameState, AudioService audioService) {
    return ImageDropTarget(
      key: ValueKey(gameState.currentItem!.imagePath),
      item: gameState.currentItem!,
      onLetterAccepted: (letter) async {
        if (letter == gameState.currentItem!.firstLetter) {
          await audioService.playCongratulations();
          if (mounted && context.mounted) {
            gameState.nextImage();
          }
        } else {
          await audioService.playIncorrect();
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Try Again!', style: GameConfig.bodyTextStyle),
              ),
            );
          }
        }
      },
    );
  }

  Widget buildLetterGrid(GameState gameState, AudioService audioService) {
    return Center(
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
    );
  }
}