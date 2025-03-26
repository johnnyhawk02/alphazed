import textToSpeech from '@google-cloud/text-to-speech';
import { promises as fs } from 'fs';
import path from 'path';
import dotenv from 'dotenv';

dotenv.config();

const client = new textToSpeech.TextToSpeechClient();

const synthesizeSpeech = async (text, useSSML = false) => {
  const request = {
    input: useSSML ? { ssml: text } : { text },
    voice: {
      languageCode: 'en-GB',
      name: 'en-GB-Chirp3-HD-Zephyr',
    },
    audioConfig: { audioEncoding: 'MP3' },
  };

  const [response] = await client.synthesizeSpeech(request);
  return response.audioContent;
};

// Enhanced utility functions to reduce duplicate code
async function directoryExists(path) {
  try {
    await fs.access(path);
    return true;
  } catch {
    return false;
  }
}

async function ensureDirectoryExists(dirPath) {
  if (!(await directoryExists(dirPath))) {
    await fs.mkdir(dirPath, { recursive: true });
    console.log(`Created directory: ${dirPath}`);
  }
}

async function generateAudioFile(text, outputPath, useSSML = false) {
  try {
    const audioContent = await synthesizeSpeech(text, useSSML);
    await fs.writeFile(outputPath, audioContent, 'binary');
    console.log(`Generated audio file: ${outputPath}`);
  } catch (error) {
    console.error(`Error generating audio for "${text}":`, error);
  }
}

// Process a batch of audio files with the same handling pattern
async function processBatchAudio(directory, items, namePrefix = "", delayMs = 1000) {
  await ensureDirectoryExists(directory);
  
  for (let i = 0; i < items.length; i++) {
    const outputPath = path.join(directory, `${namePrefix}${i + 1}.mp3`);
    
    if (!(await directoryExists(outputPath))) {
      console.log(`Processing: ${namePrefix}${i + 1} - "${items[i]}"`);
      await generateAudioFile(items[i], outputPath);
      await new Promise(resolve => setTimeout(resolve, delayMs));
    } else {
      console.log(`Skipping ${namePrefix}${i + 1}.mp3 - already exists`);
    }
  }
}

// Process variations of questions for each word
async function processQuestionVariations(questionDir, baseName, variations, delayMs = 1000) {
  for (let i = 0; i < variations.length; i++) {
    const questionText = variations[i].replace('$word', baseName);
    const outputPath = path.join(questionDir, `${baseName}_question_${i + 1}.mp3`);

    if (!(await directoryExists(outputPath))) {
      console.log(`Processing: Question variation ${i + 1} for ${baseName}`);
      await generateAudioFile(questionText, outputPath);
      await new Promise(resolve => setTimeout(resolve, delayMs));
    } else {
      console.log(`Skipping ${baseName}_question_${i + 1}.mp3 - already exists`);
    }
  }
}

async function generateAllAudio() {
  try {
    const imagesDir = path.join(process.cwd(), 'assets/images');
    const audioDir = new URL('../assets/audio', import.meta.url).pathname;
    
    // Define subdirectories
    const wordsDir = path.join(audioDir, 'words');
    const otherDir = path.join(audioDir, 'other');
    const congratsDir = path.join(audioDir, 'congrats');
    const supportDir = path.join(audioDir, 'support');
    const questionDir = path.join(audioDir, 'questions');
    const lettersDir = path.join(audioDir, 'letters');
    
    // Ensure directories exist
    await ensureDirectoryExists(audioDir);
    await ensureDirectoryExists(wordsDir);
    await ensureDirectoryExists(otherDir);
    
    // Process word audio files
    const files = await fs.readdir(imagesDir);
    const processedNames = new Set();

    for (const file of files) {
      // Get the base name without extension and remove any numbers or special characters
      const baseName = file.toLowerCase()
        .replace(/\(\d+\)/, '') // Remove (1), (2), etc.
        .replace(/\.[^/.]+$/, '') // Remove file extension
        .trim();

      // Skip if we've already processed this name
      if (processedNames.has(baseName)) {
        continue;
      }

      processedNames.add(baseName);

      const outputPath = path.join(wordsDir, `${baseName}.mp3`);
      
      // Skip if audio file already exists
      if (await directoryExists(outputPath)) {
        console.log(`Skipping ${baseName} - audio file already exists`);
        continue;
      }

      console.log(`Processing: ${baseName}`);
      await generateAudioFile(baseName, outputPath);

      // Add a small delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    // Generate the "the word is" prompt
    console.log("Generating 'the word is' prompt...");
    const wordIsPath = path.join(otherDir, `the_word_is.mp3`);
    
    if (!(await directoryExists(wordIsPath))) {
      console.log(`Processing: "the word is" prompt`);
      await generateAudioFile("the word is", wordIsPath);
    } else {
      console.log(`Skipping "the word is" - already exists`);
    }

    // Generate congratulatory messages
    console.log("Generating congratulatory messages...");
    const congratulatoryMessages = [
      "Fantastic job!",
      "You're amazing!",
      "Super smart!",
      "Brilliant work!",
      "You're a star!",
      "That's perfect!",
      "Way to go!",
      "You got it!",
      "You're so clever!",
      "Great thinking!",
      "Wonderful!",
      "Super duper!",
      "You're learning so well!",
      "Excellent work!",
      "You're doing great!",
      "Keep shining!",
      "That's beautiful!",
      "You're incredible!",
      "What a superstar!",
      "You make learning fun!"
    ];
    
    await processBatchAudio(congratsDir, congratulatoryMessages, "congrats_");

    // Generate supportive messages
    console.log("Generating supportive messages...");
    const supportiveMessages = [
      "That's not quite right. Let's try again!",
      "Almost there! Try once more.",
      "You can do it! Try another letter.",
      "Not that one, but you're learning!",
      "Keep trying, you'll get it!",
      "Let's have another go!",
      "Don't give up, try again!",
      "Not quite. Which letter do you think it is?",
      "That's a good try! Let's try another letter.",
      "You're getting closer! Try again.",
      "Oops! Try a different letter.",
      "That's not it, but you're doing great!",
      "Practice makes perfect! Try again.",
      "Everyone learns by trying. Let's try again!",
      "That's tricky! Have another go.",
      "You're being so brave trying! Let's try again.",
      "Not that one. Can you find the right letter?",
      "Keep going! You'll get it next time.",
      "Learning takes practice. Try again!",
      "I know you can do this! Try another letter."
    ];
    
    await processBatchAudio(supportDir, supportiveMessages, "support_");

    // Add variations for "Which letter does $word begin with?"
    console.log("Generating 'which letter does $word begin with?' prompts...");
    
    const questionVariations = [
      "Which letter does $word begin with?",
      "Can you tell me the first letter of $word?",
      "What letter starts the word $word?",
      "Do you know the first letter of $word?",
      "What is the starting letter of $word?"
    ];

    // Process each word for question variations
    await ensureDirectoryExists(questionDir);
    for (const file of files) {
      const baseName = file.toLowerCase()
        .replace(/\(\d+\)/, '')
        .replace(/\.[^/.]+$/, '')
        .trim();
        
      if (!processedNames.has(baseName)) continue;
      
      await processQuestionVariations(questionDir, baseName, questionVariations);
    }

    // Generate letter sounds
    console.log("Generating letter sounds...");
    await ensureDirectoryExists(lettersDir);

    // Mapping of letters to their phonetic letter names
    const letterNames = {
      'a': 'A.',  // Using clearer phonetic spelling to distinguish from 'eye'
      'b': 'B.',
      'c': 'C.',
      'd': 'D.',
      'e': 'E.',
      'f': 'F.',
      'g': 'G.',
      'h': 'H.',
      'i': 'I.',
      'j': 'J.',
      'k': 'K.',
      'l': 'L.',
      'm': 'M.',
      'n': 'N.',
      'o': 'O.',
      'p': 'P.',
      'q': 'Q.',
      'r': 'R.',
      's': 'S.',
      't': 'T.',
      'u': 'U.',
      'v': 'V.',
      'w': 'W.',
      'x': 'X.',
      'y': 'Y.',
      'z': 'Zed'  // Using British/Commonwealth pronunciation for Z
    };

    const alphabet = 'abcdefghijklmnopqrstuvwxyz'.split('');
    for (const letter of alphabet) {
      const outputPath = path.join(lettersDir, `${letter}_.mp3`); // Add underscore to letter file names

      if (!(await directoryExists(outputPath))) {
        // Use the letter name instead of just the letter
        const letterName = letterNames[letter];
        const useSSML = letterName.startsWith('<speak>');
        console.log(`Processing letter: ${letter} (${letterName})`);
        await generateAudioFile(letterName, outputPath, useSSML);
        await new Promise(resolve => setTimeout(resolve, 1000));
      } else {
        console.log(`Skipping letter ${letter} - already exists`);
      }
    }

    console.log('Audio generation completed!');
  } catch (error) {
    console.error('Error processing files:', error);
  }
}

generateAllAudio();