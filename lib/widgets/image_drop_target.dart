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

class _ImageDropTargetState extends State<ImageDropTarget> with SingleTickerProviderStateMixin {
  bool isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: GameConfig.dropAnimationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAccept: (data) {
        setState(() => isHovering = true);
        _controller.forward();
        return data != null;
      },
      onLeave: (_) {
        setState(() => isHovering = false);
        _controller.reverse();
      },
      onAccept: (data) {
        setState(() => isHovering = false);
        _controller.reverse();
        widget.onLetterAccepted(data);
      },
      builder: (context, candidateData, rejectedData) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: GameConfig.dropAnimationDuration,
            decoration: GameConfig.getCardDecoration(isHighlighted: isHovering),
            child: Center(
              child: AspectRatio(
                aspectRatio: 4/3,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: GameConfig.fadeAnimationDuration,
                        opacity: isHovering ? 0.7 : 1.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius),
                          child: Image.asset(
                            widget.item.imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    if (isHovering)
                      Positioned.fill(
                        child: Center(
                          child: Icon(
                            Icons.add_circle_outline,
                            size: 60,
                            color: GameConfig.primaryButtonColor,
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(GameConfig.defaultBorderRadius),
                          ),
                        ),
                        padding: EdgeInsets.all(GameConfig.defaultPadding),
                        child: Text(
                          widget.item.word,
                          style: GameConfig.wordTextStyle.copyWith(
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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