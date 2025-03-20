import 'package:flutter/material.dart';
import '../models/game_item.dart';
import '../config/game_config.dart';

class ImageDropTarget extends StatefulWidget {
  final GameItem item;
  final Function(String) onLetterAccepted;

  const ImageDropTarget({
    Key? key,
    required this.item,
    required this.onLetterAccepted,
  }) : super(key: key);

  @override
  State<ImageDropTarget> createState() => _ImageDropTargetState();
}

class _ImageDropTargetState extends State<ImageDropTarget> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAccept: (data) {
        setState(() => isHovering = true);
        return data != null;
      },
      onLeave: (_) => setState(() => isHovering = false),
      onAccept: (data) {
        setState(() => isHovering = false);
        widget.onLetterAccepted(data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: GameConfig.dropAnimationDuration,
          decoration: GameConfig.getCardDecoration(isHighlighted: isHovering),
          child: Center(
            child: AspectRatio(
              aspectRatio: 4/3,
              child: Padding(
                padding: EdgeInsets.all(GameConfig.defaultPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Image.asset(
                        widget.item.imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: GameConfig.defaultPadding),
                    Text(
                      widget.item.word,
                      style: GameConfig.wordTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}