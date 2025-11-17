import express from "express";
import {
  endTrip,
  getAssignedOrderForDriver,
  getAvailableDrivers,
  getDriverDetails,
  getDriverLicenseImage,
  startTrip,
  updateDriverInfo,
  uploadDriverLicense,
} from "../../controller/driver/driverController.js";

import {
  verifyDriver,
  verifyToken,
  verifyTruckOwner,
} from "../../utils/verifyToken.js";
import upload from "../../middleware/profile_multer.js";

import uploadLicense from "../../middleware/license_multer.js";

const router = express.Router();

// Get driver details
router.get("/details", verifyToken, verifyDriver, getDriverDetails);

// Update driver information
router.patch(
  "/update",
  verifyToken,
  verifyDriver,
  upload.single("profileImage"),
  updateDriverInfo
);

//  Get Assigned Order that have been assigned by Truck Owner
router.get(
  "/assigned-order",
  verifyToken,
  verifyDriver,
  getAssignedOrderForDriver
);

// Get Available Drivers
router.get("/available", verifyToken, verifyTruckOwner, getAvailableDrivers);

// Driver start the trip
router.patch("/start-trip/:orderId", verifyToken, verifyDriver, startTrip);

// End the trip by driver
router.patch("/end-trip/:orderId", verifyToken, verifyDriver, endTrip);

//Upload License  Image
router.patch(
  "/upload-license",
  verifyToken,
  uploadLicense.single("licenseImage"),
  uploadDriverLicense
);

router.get("/license/:driverId", verifyToken, getDriverLicenseImage);

export default router;
