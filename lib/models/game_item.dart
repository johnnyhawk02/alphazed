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
    if (count != 3) {
      // This logic currently assumes exactly 3 options for permutation check
      // Add handling for other counts if needed, or throw an error.
      print("Warning: generateOptions blocklist check currently only supports count=3");
      // Fallback to old logic for non-3 counts (or implement permutation for variable count)
      return _generateOptionsSimple(allLetters, count);
    }
    if (firstLetter.isEmpty) return []; // Handle items with no first letter

    final random = Random();
    List<String> options;

    do {
      // Generate a candidate set of letters
      options = <String>[firstLetter]; // Start with the correct letter
      final availableLetters = List<String>.from(allLetters)..remove(firstLetter);
      availableLetters.shuffle(random);
      
      int availableIndex = 0;
      while (options.length < count && availableIndex < availableLetters.length) {
        options.add(availableLetters[availableIndex]);
        availableIndex++;
      }
      
      // If we didn't get enough letters (shouldn't happen with 26 letters available)
      if (options.length < count) {
         print("Warning: Could not generate enough unique letters.");
         return options..shuffle(random); // Return what we have
      }

      // Check ALL permutations of the generated set
      bool isAnyPermutationBlocked = false;
      List<String> p = options; // Use shorter name for permutations
      List<String> permutations = [
        "${p[0]}${p[1]}${p[2]}",
        "${p[0]}${p[2]}${p[1]}",
        "${p[1]}${p[0]}${p[2]}",
        "${p[1]}${p[2]}${p[0]}",
        "${p[2]}${p[0]}${p[1]}",
        "${p[2]}${p[1]}${p[0]}",
      ];

      for (String perm in permutations) {
        if (_blockedWords.contains(perm.toLowerCase())) {
          isAnyPermutationBlocked = true;
          break; // Found a blocked permutation, no need to check others
        }
      }
      
      // If any permutation was blocked, regenerate the options
      if (isAnyPermutationBlocked) {
        continue; 
      } else {
        // All permutations are safe, break the loop
        break; 
      }

    } while (true); // Loop until a safe set (all permutations checked) is found
    
    // Shuffle the final, safe options to randomize their order for display
    options.shuffle(random);
    return options;
  }

  // Helper for the old logic (or for counts other than 3)
  List<String> _generateOptionsSimple(List<String> allLetters, int count) {
     if (count <= 0) return [];
     if (firstLetter.isEmpty) return [];
     final random = Random();
     final options = <String>[firstLetter];
     final availableLetters = List<String>.from(allLetters)..remove(firstLetter);
     availableLetters.shuffle(random);
     int availableIndex = 0;
     while (options.length < count && availableIndex < availableLetters.length) {
       options.add(availableLetters[availableIndex]);
       availableIndex++;
     }
     options.shuffle(random);
     return options;
  }
}