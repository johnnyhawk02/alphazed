import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/audio_service.dart';
import '../models/game_item.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AudioService _audioService = AudioService();
  List<GameItem> gameItems = [];
  final List<String> allLetters = List.generate(26, (index) => String.fromCharCode(65 + index));
  int currentIndex = 0;
  int questionVariation = 1;
  Random random = Random();
  
  // For revealing letter circles
  bool isQuestionPlaying = false;
  int visibleLetterCount = 0;
  List<String> currentOptions = [];
  
  @override
  void initState() {
    super.initState();
    _loadGameItems().then((_) {
      if (gameItems.isNotEmpty) {
        gameItems.shuffle(random);
        _playQuestionAndRevealLetters();
      }
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadGameItems() async {
    try {
      // Get the manifest file which contains all the assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Filter for image files in the assets/images directory
      final imageFiles = manifestMap.keys
          .where((key) => key.startsWith('assets/images/') && 
                         (key.endsWith('.jpeg') || 
                          key.endsWith('.jpg') || 
                          key.endsWith('.png')))
          .toList();
      
      // Convert image paths to GameItem objects
      List<GameItem> items = imageFiles.map((path) => GameItem.fromImagePath(path)).toList();
      
      setState(() {
        gameItems = items;
      });
    } catch (e) {
      print('Error loading game items: $e');
      
      // Fallback to some default images if loading fails
      final defaults = [
        'assets/images/apple.jpeg',
        'assets/images/ball.jpeg',
        'assets/images/cat.jpeg',
      ];
      
      setState(() {
        gameItems = defaults.map((path) => GameItem.fromImagePath(path)).toList();
      });
    }
  }

  Future<void> _playQuestionAndRevealLetters() async {
    if (gameItems.isEmpty) return;
    
    setState(() {
      isQuestionPlaying = true;
      visibleLetterCount = 0;
      
      // Generate new options for the current item
      currentOptions = gameItems[currentIndex].generateOptions(allLetters);
    });
    
    try {
      // Play only the question audio first
      String wordName = gameItems[currentIndex].word;
      
      // Start the question audio and wait for completion
      await _audioService.playQuestion(wordName, questionVariation);
      await _audioService.waitForQuestionCompletion();
      
      // After question completes, start revealing letters
      _revealLettersSequentially();
    } catch (e) {
      print('Error playing audio or revealing letters: $e');
      // Make sure letters are revealed even if audio fails
      _revealLettersSequentially();
    }
  }
  
  void _revealLettersSequentially() async {
    setState(() {
      isQuestionPlaying = false;
    });

    // Reveal each letter with a 2-second delay and play its sound sequentially
    for (int i = 0; i < currentOptions.length; i++) {
      // Wait for 2 seconds before revealing the next letter
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        String letter = currentOptions[i];
        String letterAudioPath = 'assets/audio/letters/${letter.toLowerCase()}.mp3';

        setState(() {
          visibleLetterCount = i + 1;
        });

        try {
          await _audioService.playLetter(letter);
        } catch (e) {
          print('Error playing letter audio: $e');
        }
      }
    }
  }

  void _nextImage() {
    setState(() {
      currentIndex = (currentIndex + 1) % gameItems.length;
      questionVariation = random.nextInt(5) + 1; // Random question 1-5
    });
    
    // Play question and then reveal letters
    _playQuestionAndRevealLetters();
  }

  @override
  Widget build(BuildContext context) {
    // Guard against empty game items list
    if (gameItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Alphabet Learning Game')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    GameItem currentItem = gameItems[currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Alphabet Learning Game'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: DragTarget<String>(
                onWillAccept: (data) => data != null,
                onAccept: (data) {
                  if (data == currentItem.firstLetter) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Correct!')),
                    );
                    _nextImage();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Try Again!')),
                    );
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            currentItem.imagePath,
                            height: 300,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 16),
                          Text(
                            currentItem.word,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            flex: 2,
            child: Center(
              child: Wrap(
                spacing: 30,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                children: List.generate(currentOptions.length, (index) {
                  // Show empty space for letters not yet revealed
                  if (index >= visibleLetterCount && !isQuestionPlaying) {
                    return SizedBox(width: 120, height: 120);
                  }
                  
                  String letter = currentOptions[index];
                  
                  // Show letter circle only if it's visible (revealed)
                  if (index < visibleLetterCount || isQuestionPlaying) {
                    return Draggable<String>(
                      data: letter,
                      feedback: Material(
                        color: Colors.transparent,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _audioService.playLetter(letter);
                        },
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: 500),
                          opacity: 1.0,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return SizedBox(width: 120, height: 120);
                  }
                }),
              ),
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}