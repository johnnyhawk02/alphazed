import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_item.dart';

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
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isHovering ? Colors.green.shade100 : Colors.white,
            border: Border.all(
              color: isHovering ? Colors.green : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: AspectRatio(
              aspectRatio: 4/3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Image.asset(
                        widget.item.imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.item.word,
                      style: GoogleFonts.aBeeZee(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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