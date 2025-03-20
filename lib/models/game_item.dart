import 'dart:math';

class GameItem {
  /// The full path to the image asset
  final String imagePath;
  
  /// The word associated with the image (extracted from filename)
  final String word;
  
  /// The first letter of the word (used for correct answer)
  final String firstLetter;

  GameItem({
    required this.imagePath,
    required this.word,
    required this.firstLetter,
  });

  /// Factory constructor that creates a GameItem from an image path
  factory GameItem.fromImagePath(String imagePath) {
    // Extract the word from the image path (filename without extension)
    final filename = imagePath.split('/').last;
    final word = filename.split('.').first.toLowerCase();
    
    // Get the first letter (lowercase)
    final firstLetter = word.isNotEmpty ? word[0].toLowerCase() : '';
    
    return GameItem(
      imagePath: imagePath,
      word: word,
      firstLetter: firstLetter,
    );
  }
  
  /// Returns a list of letter options for this item (1 correct, others random)
  List<String> generateOptions(List<String> allLetters, {int count = 3}) {
    final options = <String>[firstLetter];
    final random = Random();
    
    while (options.length < count) {
      final randomLetter = allLetters[random.nextInt(allLetters.length)];
      if (!options.contains(randomLetter)) {
        options.add(randomLetter);
      }
    }
    
    // Shuffle the options to randomize their order
    options.shuffle();
    return options;
  }
}