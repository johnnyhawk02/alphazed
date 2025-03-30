import sharp from 'sharp';
import { readdir } from 'fs/promises';
import { join } from 'path';

const imagesDir = new URL('../assets/images/words', import.meta.url).pathname;

async function convertPngToJpeg() {
  try {
    const files = await readdir(imagesDir);
    const pngFiles = files.filter(file => file.toLowerCase().endsWith('.png'));
    
    console.log(`Found ${pngFiles.length} PNG files to convert`);
    
    for (const file of pngFiles) {
      const inputPath = join(imagesDir, file);
      const outputPath = join(imagesDir, file.replace(/\.png$/i, '.jpeg'));
      
      console.log(`Converting ${file} to JPEG...`);
      
      await sharp(inputPath)
        .jpeg({
          quality: 90,
          mozjpeg: true
        })
        .toFile(outputPath);
        
      console.log(`Successfully converted ${file}`);
    }
    
    console.log('All PNG files have been converted to JPEG');
  } catch (error) {
    console.error('Error converting images:', error);
  }
}

convertPngToJpeg();