import multer from 'multer';
import path from 'path';
import fs from 'fs';

// Set up Multer storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'public/drivers/'); 
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// File type validation (allow all image formats)
const fileFilter = (req, file, cb) => {
  const imageTypes = /^image\//; 
  if (imageTypes.test(file.mimetype)) {
    return cb(null, true);
  } else {
    cb(new Error('Only image files are allowed.'));
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 } // Increase size limit if needed
});

export default upload;
