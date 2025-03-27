import { readdirSync, readFileSync, statSync, writeFileSync } from 'fs';
import { join, extname } from 'path';
import { imageSize } from 'image-size';

const staticDir = './static/wallpapers';
const outputFile = './static/files.json';

function getFiles(dir) {
  return readdirSync(dir)
    .filter(file => !file.startsWith('.'))
    .map(file => {
      const filePath = join(dir, file);
      const stats = statSync(filePath);
      const sizeInMB = (stats.size / (1024 * 1024)).toFixed(2); // Taille en MB

      let dimensions = { width: 0, height: 0 };
      if (['.jpg', '.png', '.gif'].includes(extname(file).toLowerCase())) {
        const buffer = readFileSync(filePath);
        dimensions = imageSize(buffer);
      }

      return {
        filename: file,
        size: sizeInMB,
        width: dimensions.width || 0,
        height: dimensions.height || 0
      };
    });
}

const files = getFiles(staticDir);
writeFileSync(outputFile, JSON.stringify(files, null, 2));

console.log(`✅ Liste des fichiers générée dans ${outputFile}`);
