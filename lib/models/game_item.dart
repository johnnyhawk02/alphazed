import 'dart:math';

class GameItem {
  /// The full path to the image asset
  final String imagePath;

  /// The word associated with the image (extracted from filename)
  final String word;

  /// The first letter of the word (used for correct answer)
  final String firstLetter;

  // Simple blocklist - add more words as needed
  static final Set<String> _blockedWords = {
    'sex',
    'nob',
    'bum',
    'cok',
    'cum',
    'fuc',
    'fuk',
    'ass',
    'dic',
    'tit',
    'poo',
    'pee',
    'fag',
    'cnt',
    'gay',
    'god',
    'hoe',
    'jew',
    'jiz',
    'kik',
    'lez',
    'nip',
    'pis',
    'pot',
    'pus',
    'sac',
    'sht',
    'vag',
    'nig',
    'wog',
    'bad',
    'dam',
    'die',
    'fat',
    'gun',
    'hit',
    'hot',
    'kid',
    'mad',
    'rag',
    'rot',
    'sad',
    // Add other 3-letter words to block here
    // e.g., 'ass', 'fuk', 'dic', ... (consider common misspellings too if necessary)
  };

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
    // Always ensure we return exactly 3 options
    const int FIXED_COUNT = 3;
    
    // Handle edge cases
    if (firstLetter.isEmpty) {
      print("Warning: Item '$word' has no first letter");
      return List.filled(FIXED_COUNT, "?");
    }
    
    final random = Random();
    final options = <String>[firstLetter];  // Start with correct letter
    
    // Make a copy of all letters and remove the correct one
    final availableLetters = List<String>.from(allLetters)..remove(firstLetter);
    availableLetters.shuffle(random);
    
    // Add exactly 2 more random letters
    while (options.length < FIXED_COUNT && availableLetters.isNotEmpty) {
      options.add(availableLetters.removeAt(0));
    }
    
    // If we somehow don't have enough letters (shouldn't happen with 26 letters available),
    // add placeholder letters to ensure we have exactly 3
    while (options.length < FIXED_COUNT) {
      final placeholderLetter = String.fromCharCode(97 + options.length % 26); // a, b, c, etc.
      if (!options.contains(placeholderLetter)) {
        options.add(placeholderLetter);
      } else {
        options.add('?');
      }
      print("Warning: Added placeholder letter to options for word: $word");
    }
    
    // Log the final options before shuffle for debugging
    print("Generated options for '$word': $options (before shuffle)");
    
    // Shuffle all options to randomize position
    options.shuffle(random);
    return options;
  }
}