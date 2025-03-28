// Import necessary modules
import textToSpeech from '@google-cloud/text-to-speech';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url'; // To handle __dirname equivalent in ES modules
import dotenv from 'dotenv';
import { execSync } from 'child_process';

// Load environment variables from .env file
dotenv.config();

// --- Configuration ---
// *** USING RECOMMENDED SSML-COMPATIBLE VOICE ***
const GOOGLE_TTS_VOICE_NAME = 'en-GB-Neural2-A'; // High quality, supports SSML
// Other options: 'en-GB-Wavenet-A', 'en-GB-Standard-A', etc. (and B/C/D/F variants)
const GOOGLE_TTS_LANGUAGE_CODE = 'en-GB';
const AUDIO_ENCODING_FOR_SYNTHESIS = 'LINEAR16'; // WAV format for intermediate processing
const FINAL_AUDIO_FORMAT = 'mp3'; // Final output format
const FFMPEG_SILENCE_THRESHOLD = '-50dB'; // Adjust based on TTS output silence level
const API_CALL_DELAY_MS = 500; // Delay between Google TTS API calls (adjust if rate limited)

// Initialize Google Cloud Text-to-Speech client
const client = new textToSpeech.TextToSpeechClient();

// --- Utility Functions ---

/**
 * Clears the audio asset caches by removing all files in the temp directory.
 * @returns {Promise<boolean>} - True if cache was successfully cleared, false otherwise.
 */
async function clearAssetCaches() {
  try {
    const tempDir = await ensureTempDirectory();
    const files = await fs.readdir(tempDir);
    
    console.log(`Clearing asset cache: Found ${files.length} temporary files to remove...`);
    
    let deletedCount = 0;
    for (const file of files) {
      const filePath = path.join(tempDir, file);
      try {
        await fs.unlink(filePath);
        deletedCount++;
      } catch (error) {
        console.error(`Failed to delete temporary file ${filePath}:`, error.message);
      }
    }
    
    console.log(`Asset cache cleared: Removed ${deletedCount}/${files.length} temporary files.`);
    return true;
  } catch (error) {
    console.error('Error clearing asset caches:', error);
    return false;
  }
}

/**
 * Checks if a directory exists.
 * @param {string} dirPath - The path to the directory.
 * @returns {Promise<boolean>} - True if the directory exists, false otherwise.
 */
async function directoryExists(dirPath) {
  try {
    await fs.access(dirPath);
    return true;
  } catch {
    return false;
  }
}

/**
 * Ensures a directory exists, creating it recursively if necessary.
 * @param {string} dirPath - The path to the directory.
 */
async function ensureDirectoryExists(dirPath) {
  if (!(await directoryExists(dirPath))) {
    try {
      await fs.mkdir(dirPath, { recursive: true });
      console.log(`Created directory: ${dirPath}`);
    } catch (error) {
      console.error(`Failed to create directory ${dirPath}:`, error);
      throw error; // Re-throw error to stop execution if directory creation fails
    }
  }
}

/**
 * Ensures the temporary directory for audio processing exists.
 * @returns {Promise<string>} - The path to the temporary directory.
 */
async function ensureTempDirectory() {
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  const tempDir = path.join(__dirname, '..', 'assets', 'audio', 'temp'); // Adjust relative path if needed
  await ensureDirectoryExists(tempDir);
  return tempDir;
}

/**
 * Synthesizes speech using Google Cloud TTS.
 * @param {string} text - The text or SSML to synthesize.
 * @param {boolean} [useSSML=false] - Whether the input text is SSML.
 * @returns {Promise<Buffer|null>} - The audio content buffer, or null on error.
 */
const synthesizeSpeech = async (text, useSSML = false) => {
  const request = {
    input: useSSML ? { ssml: text } : { text },
    voice: {
      languageCode: GOOGLE_TTS_LANGUAGE_CODE,
      name: GOOGLE_TTS_VOICE_NAME,
    },
    audioConfig: { audioEncoding: AUDIO_ENCODING_FOR_SYNTHESIS }, // Using WAV
  };

  try {
    console.log(`Requesting TTS for: ${useSSML ? 'SSML' : text.substring(0, 50) + (text.length > 50 ? '...' : '')}`); // Log request
    const [response] = await client.synthesizeSpeech(request);
    console.log(`TTS synthesis successful for: ${useSSML ? 'SSML' : text.substring(0, 50) + (text.length > 50 ? '...' : '')}`);
    return response.audioContent;
  } catch (error) {
      console.error(`Google TTS API error for input "${useSSML ? 'SSML Input' : text.substring(0, 50) + (text.length > 50 ? '...' : '')}":`, error.message || error);
      if (error.details) console.error("Error details:", error.details);
      return null; // Indicate failure
  }
};

/**
 * Processes raw WAV audio: trims leading silence and converts to MP3 using FFmpeg.
 * @param {string} wavFile - Path to the input WAV file.
 * @param {string} outputMP3 - Path for the final output MP3 file.
 * @param {string} tempDir - Path to the temporary directory.
 * @returns {Promise<boolean>} - True on success, false on failure.
 */
async function processAudio(wavFile, outputMP3, tempDir) {
  try {
    const filename = path.basename(wavFile, '.wav');
    const tempTrimmedWav = path.join(tempDir, `${filename}_trimmed.wav`);

    await ensureDirectoryExists(path.dirname(outputMP3));

    console.log(`Trimming silence from ${path.basename(wavFile)}...`);
    const trimCommand = `ffmpeg -y -i "${wavFile}" -af silenceremove=start_periods=1:start_threshold=${FFMPEG_SILENCE_THRESHOLD} "${tempTrimmedWav}"`;
    execSync(trimCommand, { stdio: 'inherit' });

    console.log(`Converting ${path.basename(tempTrimmedWav)} to MP3: ${path.basename(outputMP3)}...`);
    // Consider adding bitrate like -ab 192k or -ab 320k for higher quality MP3
    const convertCommand = `ffmpeg -y -i "${tempTrimmedWav}" -ab 192k "${outputMP3}"`;
    execSync(convertCommand, { stdio: 'inherit' });

    try {
        await fs.unlink(tempTrimmedWav);
        await fs.unlink(wavFile);
    } catch (cleanupError) {
        console.warn(`Warning: Failed to clean up temporary files for ${wavFile}:`, cleanupError.message);
    }

    console.log(`Successfully processed: ${path.basename(outputMP3)}`);
    return true;
  } catch (error) {
    console.error(`Error processing audio file ${path.basename(wavFile)}:`, error);
    try {
        if (await directoryExists(wavFile)) await fs.unlink(wavFile);
        const tempTrimmedWav = path.join(tempDir, `${path.basename(wavFile, '.wav')}_trimmed.wav`);
        if (await directoryExists(tempTrimmedWav)) await fs.unlink(tempTrimmedWav);
    } catch (cleanupError) {
         console.warn(`Warning: Failed to clean up files after error for ${wavFile}:`, cleanupError.message);
    }
    return false;
  }
}

/**
 * Generates a single audio file: synthesizes to WAV, processes (trims/converts), saves as MP3.
 * @param {string} text - The text or SSML to synthesize.
 * @param {string} outputMP3Path - The final desired path for the MP3 file.
 * @param {boolean} [useSSML=false] - Whether the input text is SSML.
 * @returns {Promise<boolean>} - True on success, false on failure.
 */
async function generateAudioFile(text, outputMP3Path, useSSML = false) {
  let tempWavPath = '';
  try {
    const tempDir = await ensureTempDirectory();
    const baseOutputName = path.basename(outputMP3Path, `.${FINAL_AUDIO_FORMAT}`);
    tempWavPath = path.join(tempDir, `${baseOutputName}_raw.wav`);

    const audioContent = await synthesizeSpeech(text, useSSML);
    if (!audioContent) {
        console.error(`Skipping processing for "${useSSML ? 'SSML Input' : text.substring(0, 50) + (text.length > 50 ? '...' : '')}" due to TTS API error.`);
        return false;
    }
    await fs.writeFile(tempWavPath, audioContent, 'binary');
    console.log(`Generated intermediate WAV: ${path.basename(tempWavPath)}`);

    const success = await processAudio(tempWavPath, outputMP3Path, tempDir);
    return success;

  } catch (error) {
    console.error(`Error generating audio file ${path.basename(outputMP3Path)} for "${useSSML ? 'SSML Input' : text.substring(0, 50) + (text.length > 50 ? '...' : '')}":`, error);
     if (tempWavPath && await directoryExists(tempWavPath)) {
        try {
            await fs.unlink(tempWavPath);
        } catch (cleanupError) {
            console.warn(`Warning: Failed to clean up temporary WAV ${tempWavPath} after error:`, cleanupError.message);
        }
     }
    return false;
  }
}

/**
 * Processes a batch of text items into audio files with existence check and delay.
 * @param {string} directory - The output directory for the batch.
 * @param {string[]} items - Array of text or SSML strings.
 * @param {string} [namePrefix=""] - Prefix for the output filenames (e.g., "congrats_").
 * @param {number} [delayMs=API_CALL_DELAY_MS] - Delay between processing each item.
 * @param {boolean} [useSSML=false] - Whether items are SSML.
 */
async function processBatchAudio(directory, items, namePrefix = "", delayMs = API_CALL_DELAY_MS, useSSML = false) {
  await ensureDirectoryExists(directory);

  for (let i = 0; i < items.length; i++) {
    const itemText = items[i];
    const outputFilename = `${namePrefix}${i + 1}.${FINAL_AUDIO_FORMAT}`;
    const outputPath = path.join(directory, outputFilename);

    if (!(await directoryExists(outputPath))) {
      console.log(`Processing: ${outputFilename} - "${useSSML ? 'SSML Input' : itemText.substring(0,50)+'...'}"`);
      const success = await generateAudioFile(itemText, outputPath, useSSML);
      if(success) {
          await new Promise(resolve => setTimeout(resolve, delayMs));
      } else {
          console.warn(`Skipping delay for ${outputFilename} due to processing error.`);
      }
    } else {
      console.log(`Skipping ${outputFilename} - already exists`);
    }
  }
}

/**
 * Processes question variations for a given base word.
 * @param {string} questionDir - The output directory for question audio.
 * @param {string} baseName - The word to insert into the question templates.
 * @param {string[]} variations - Array of question templates (e.g., "Which letter does $word begin with?").
 * @param {number} [delayMs=API_CALL_DELAY_MS] - Delay between processing each variation.
 */
async function processQuestionVariations(questionDir, baseName, variations, delayMs = API_CALL_DELAY_MS) {
  for (let i = 0; i < variations.length; i++) {
    const questionText = variations[i].replace('$word', baseName);
    const outputFilename = `${baseName}_question_${i + 1}.${FINAL_AUDIO_FORMAT}`;
    const outputPath = path.join(questionDir, outputFilename);

    if (!(await directoryExists(outputPath))) {
      console.log(`Processing: Question variation ${i + 1} for ${baseName}`);
      const success = await generateAudioFile(questionText, outputPath, false); // Questions are plain text
      if(success) {
          await new Promise(resolve => setTimeout(resolve, delayMs));
      } else {
          console.warn(`Skipping delay for question ${outputFilename} due to processing error.`);
      }
    } else {
      console.log(`Skipping ${outputFilename} - already exists`);
    }
  }
}

// --- Main Orchestration Function ---

/**
 * Main function to generate all required audio files.
 */
async function generateAllAudio() {
  console.log("Starting audio generation process...");
  console.log(`Using TTS Voice: ${GOOGLE_TTS_VOICE_NAME}`);
  try {
    // --- Define Base Paths ---
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const baseAssetsDir = path.join(__dirname, '..', 'assets'); // Adjust if structure differs
    const imagesDir = path.join(baseAssetsDir, 'images');
    const audioDir = path.join(baseAssetsDir, 'audio');

    const wordsDir = path.join(audioDir, 'words');
    const otherDir = path.join(audioDir, 'other');
    const congratsDir = path.join(audioDir, 'congrats');
    const supportDir = path.join(audioDir, 'support');
    const questionDir = path.join(audioDir, 'questions');
    const lettersDir = path.join(audioDir, 'letters');

    console.log("Ensuring output directories exist...");
    await ensureDirectoryExists(audioDir);
    await ensureDirectoryExists(wordsDir);
    await ensureDirectoryExists(otherDir);
    await ensureDirectoryExists(congratsDir);
    await ensureDirectoryExists(supportDir);
    await ensureDirectoryExists(questionDir);
    await ensureDirectoryExists(lettersDir);
    await ensureTempDirectory();
    console.log("Directories checked/created.");

    // --- Process Word Audio Files from Image Names ---
    console.log("\nProcessing word audio files based on images...");
    let files = [];
    try {
        files = await fs.readdir(imagesDir);
    } catch (err) {
        console.error(`Error reading images directory ${imagesDir}: ${err.message}. Please ensure it exists.`);
        throw err; // Stop execution if images directory is missing
    }

    const processedWordNames = new Set();
    const wordsSuccessfullyProcessed = new Set();

    for (const file of files) {
      if (!/\.(jpe?g|png|gif|webp)$/i.test(file)) {
          // console.log(`Skipping non-image file: ${file}`); // Optional logging
          continue;
      }

      const baseName = file.toLowerCase()
        .replace(/\(\d+\)/, '')
        .replace(/\.[^/.]+$/, '')
        .trim();

      if (!baseName || processedWordNames.has(baseName)) {
        continue;
      }
      processedWordNames.add(baseName);

      const outputPath = path.join(wordsDir, `${baseName}.${FINAL_AUDIO_FORMAT}`);

      if (await directoryExists(outputPath)) {
        console.log(`Skipping ${baseName} - audio file already exists`);
        wordsSuccessfullyProcessed.add(baseName);
      } else {
        console.log(`Processing word: ${baseName}`);
        // Words are plain text, useSSML = false
        const success = await generateAudioFile(baseName, outputPath, false);
        if (success) {
            wordsSuccessfullyProcessed.add(baseName);
            await new Promise(resolve => setTimeout(resolve, API_CALL_DELAY_MS));
        }
      }
    }
    console.log(`Finished processing ${processedWordNames.size} unique words from images.`);


    // --- Generate "the word is" prompt ---
    console.log("\nGenerating 'the word is' prompt...");
    const wordIsPath = path.join(otherDir, `the_word_is.${FINAL_AUDIO_FORMAT}`);
    if (!(await directoryExists(wordIsPath))) {
      // Plain text, useSSML = false
      await generateAudioFile("the word is", wordIsPath, false);
      await new Promise(resolve => setTimeout(resolve, API_CALL_DELAY_MS));
    } else {
      console.log(`Skipping "the word is" - already exists`);
    }

    // --- Generate Congratulatory Messages ---
    console.log("\nGenerating congratulatory messages...");
    const congratulatoryMessages = [
        "Fantastic job!", "You're amazing!", "Super smart!", "Brilliant work!", "You're a star!",
        "That's perfect!", "Way to go!", "You got it!", "You're so clever!", "Great thinking!",
        "Wonderful!", "Super duper!", "You're learning so well!", "Excellent work!", "You're doing great!",
        "Keep shining!", "That's beautiful!", "You're incredible!", "What a superstar!", "You make learning fun!"
    ];
    // Plain text, useSSML = false
    await processBatchAudio(congratsDir, congratulatoryMessages, "congrats_", API_CALL_DELAY_MS, false);

    // --- Generate Supportive Messages ---
    console.log("\nGenerating supportive messages...");
    const supportiveMessages = [
        "That's not quite right. Let's try again!", "Almost there! Try once more.", "You can do it! Try another letter.",
        "Not that one, but you're learning!", "Keep trying, you'll get it!", "Let's have another go!",
        "Don't give up, try again!", "Not quite. Which letter do you think it is?", "That's a good try! Let's try another letter.",
        "You're getting closer! Try again.", "Oops! Try a different letter.", "That's not it, but you're doing great!",
        "Practice makes perfect! Try again.", "Everyone learns by trying. Let's try again!", "That's tricky! Have another go.",
        "You're being so brave trying! Let's try again.", "Not that one. Can you find the right letter?",
        "Keep going! You'll get it next time.", "Learning takes practice. Try again!", "I know you can do this! Try another letter."
    ];
    // Plain text, useSSML = false
    await processBatchAudio(supportDir, supportiveMessages, "support_", API_CALL_DELAY_MS, false);

    // --- Generate Question Variations for Each Successfully Processed Word ---
    console.log("\nGenerating 'which letter does $word begin with?' prompts...");
    const questionVariations = [
      "Which letter does $word begin with?",
      "Can you tell me the first letter of $word?",
      "What letter starts the word $word?",
      "Do you know the first letter of $word?",
      "What is the starting letter of $word?"
    ];
    console.log(`Generating questions for ${wordsSuccessfullyProcessed.size} words...`);
    for (const baseName of wordsSuccessfullyProcessed) {
        // Plain text questions, useSSML = false (handled within processQuestionVariations)
        await processQuestionVariations(questionDir, baseName, questionVariations);
    }

    // --- Generate Letter Sounds using SSML ---
    // *** THIS SECTION NOW USES SSML ***
    console.log("\nGenerating letter sounds using SSML...");
    const alphabet = 'abcdefghijklmnopqrstuvwxyz'.split('');
    const letterSSMLMap = {};

    for (const letter of alphabet) {
        // SSML to pronounce the letter name correctly
        letterSSMLMap[letter] = `<speak><say-as interpret-as="characters">${letter.toUpperCase()}</say-as></speak>`;
    }
    // Note: en-GB voices *should* handle 'Z' as 'Zed' correctly with interpret-as="characters".
    // If not, uncomment and use this override:
    // letterSSMLMap['z'] = '<speak>Zed</speak>';

    for (let i = 0; i < alphabet.length; i++) {
        const letter = alphabet[i];
        const ssmlText = letterSSMLMap[letter];
        const outputFilename = `${letter}_.${FINAL_AUDIO_FORMAT}`; // e.g., a_.mp3
        const outputPath = path.join(lettersDir, outputFilename);

        if (!(await directoryExists(outputPath))) {
          console.log(`Processing: ${outputFilename} using SSML`);
          // *** Pass SSML text and set useSSML = true ***
          const success = await generateAudioFile(ssmlText, outputPath, true);
          if(success) {
              await new Promise(resolve => setTimeout(resolve, API_CALL_DELAY_MS));
          } else {
               console.warn(`Skipping delay for ${outputFilename} due to processing error.`);
          }
        } else {
          console.log(`Skipping ${outputFilename} - already exists`);
        }
    }


    console.log('\n------------------------------------');
    console.log('Audio generation process completed!');
    console.log('------------------------------------');

  } catch (error) {
    console.error('\n------------------------------------');
    console.error('FATAL ERROR during audio generation process:', error);
    console.error('------------------------------------');
    process.exitCode = 1; // Indicate failure in case of uncaught error
  }
}

// --- Execute the Main Function ---
generateAllAudio();