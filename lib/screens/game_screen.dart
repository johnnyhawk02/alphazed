import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/audio_service.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AudioService _audioService = AudioService();
  List<String> images = [];
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
    _loadImageList().then((_) {
      if (images.isNotEmpty) {
        images.shuffle(random);
        _playQuestionAndRevealLetters();
      }
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadImageList() async {
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
      
      setState(() {
        images = imageFiles;
      });
    } catch (e) {
      print('Error loading image list: $e');
      
      // Fallback to some default images if loading fails
      setState(() {
        images = [
          'assets/images/apple.jpeg',
          'assets/images/ball.jpeg',
          'assets/images/cat.jpeg',
          // ...add a few more defaults
        ];
      });
    }
  }

  Future<void> _playQuestionAndRevealLetters() async {
    setState(() {
      isQuestionPlaying = true;
      visibleLetterCount = 0;
      
      // Generate new options for the current image
      String correctWord = _getWordFromImage(images[currentIndex]);
      currentOptions = _generateOptions(correctWord[0].toUpperCase());
    });
    
    try {
      // Play only the question audio first
      String wordName = _getWordFromImage(images[currentIndex]);
      
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
  
  void _revealLettersSequentially() {
    setState(() {
      isQuestionPlaying = false;
    });
    
    // Reveal each letter with a delay and play its sound
    for (int i = 0; i < currentOptions.length; i++) {
      Future.delayed(Duration(milliseconds: 800 * (i + 1)), () {
        if (mounted) {
          // Play the letter sound when revealing the letter
          String letter = currentOptions[i];
          
          setState(() {
            visibleLetterCount = i + 1;
          });
          
          _audioService.playLetter(letter);
        }
      });
    }
  }

  List<String> _generateOptions(String correctLetter) {
    List<String> options = [correctLetter];
    Random random = Random();
    while (options.length < 3) {
      String randomLetter = allLetters[random.nextInt(allLetters.length)];
      if (!options.contains(randomLetter)) {
        options.add(randomLetter);
      }
    }
    options.shuffle();
    return options;
  }

  void _nextImage() {
    setState(() {
      currentIndex = (currentIndex + 1) % images.length;
      questionVariation = random.nextInt(5) + 1; // Random question 1-5
    });
    
    // Play question and then reveal letters
    _playQuestionAndRevealLetters();
  }

  String _getWordFromImage(String imagePath) {
    return path.basenameWithoutExtension(imagePath).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    String currentImage = images.isEmpty ? '' : images[currentIndex];
    String correctWord = currentImage.isEmpty ? '' : _getWordFromImage(currentImage);
    
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
              child: currentImage.isEmpty
                  ? CircularProgressIndicator() // Show loading indicator while images load
                  : DragTarget<String>(
                      onWillAccept: (data) {
                        return data != null;
                      },
                      onAccept: (data) {
                        if (data == correctWord[0].toUpperCase()) {
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
                                  currentImage,
                                  height: 300,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  correctWord,
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
                  if (index >= visibleLetterCount && !isQuestionPlaying) {
                    // Show empty space for letters not yet revealed
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