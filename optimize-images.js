const imagemin = require('imagemin');
const imageminPngquant = require('imagemin-pngquant');
const imageminWebp = require('imagemin-webp');
const fs = require('fs');
const path = require('path');

// Process PNG files
(async () => {
    console.log('Optimizing PNG images...');
    const files = await imagemin(['images/*.png'], {
        destination: 'images/optimized/',
        plugins: [
            imageminPngquant({
                quality: [0.6, 0.8]
            })
        ]
    });
    
    console.log('PNG optimization complete:', files.length, 'files processed');
})();

// Convert to WebP
(async () => {
    console.log('Converting images to WebP...');
    const files = await imagemin(['images/*.png', 'images/*.jpg', 'images/*.jpeg'], {
        destination: 'images/webp/',
        plugins: [
            imageminWebp({quality: 75})
        ]
    });
    
    console.log('WebP conversion complete:', files.length, 'files processed');
})();
