
import multer from "multer";
import path from "path";

// Set the storage engine
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "public/documents");
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(
      null,
      file.fieldname + "-" + uniqueSuffix + path.extname(file.originalname)
    );
  },
});

// File type validation (allow all files)
const fileFilter = (req, file, cb) => {
  // Allow all file types
  cb(null, true);
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: { fileSize: 20 * 1024 * 1024 }, // Limit file size to 20MB
});

export default upload;
