import express from "express";
import {
  downloadDriverLicense,
  downloadFirstVehicleDocument,
  downloadVehicleDocument,
  downloadVehicleFile,
  generateVehiclePDF,
  getAllVehicleFiles,
} from "../../controller/documents/documentsController.js";
import { verifyToken } from "../../utils/verifyToken.js";
import { verifyTruckOwner } from "../../utils/verifyToken.js";

const router = express.Router();

// Query parameters: fileType and fileName
router.get("/download/:vehicleId", downloadVehicleFile);

// Returns all files (images and documents) associated with the vehicle.
router.get(
  "/get-images/:vehicleId",
  verifyToken,
  verifyTruckOwner,
  getAllVehicleFiles
);

// Download the docs for the vehicle
router.get("/vehicle/:vehicleId", verifyToken, generateVehiclePDF);

//Download the vehicle document
router.get("/vehicle-document/:orderId", verifyToken, downloadVehicleDocument);

//Download the driver license
router.get("/driver-license/:orderId", verifyToken, downloadDriverLicense);

//Download the vehicle Card
router.get("/vehicles/:vehicleId", verifyToken, downloadFirstVehicleDocument);

export default router;
