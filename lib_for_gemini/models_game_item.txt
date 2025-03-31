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
    if (count <= 0) return [];
    if (firstLetter.isEmpty) return [];
    
    final random = Random();
    final options = <String>[firstLetter];  // Start with correct letter
    final availableLetters = List<String>.from(allLetters)..remove(firstLetter);
    availableLetters.shuffle(random);
    
    // Add exactly 2 more random letters to make 3 total
    while (options.length < 3 && availableLetters.isNotEmpty) {
      options.add(availableLetters.removeAt(0));
    }
    
    // Ensure we always return exactly 3 letters
    if (options.length != 3) {
      print("Warning: Generated ${options.length} options instead of 3 for word: $word");
    }
    
    // Shuffle all options to randomize position
    options.shuffle(random);
    return options;
  }
}