import express from "express";
import {
  verifyToken,
  verifyTruckOwner,
  verifyAdminOrStaff,
} 
from "../../utils/verifyToken.js";
import upload from "../../middleware/multer.js";
import {
  getAllSubmittedVehicles,
  getAllVehicles,
  getAllVehiclesForTruckOwner,
  getApprovedVehicle,
  getRejectedVehicle,
  getVehicleById,
  getVehicleByIdentity,
  getVehicleCounts,
  getVehiclesByTruckOwner,
  registerVehicle,
  rejectVehicle,
  updateVehicleStatus,
} from "../../controller/vehicles/vehicle.js";

const router = express.Router();

// TruckOwner: Register a vehicle
router.post(
  "/register",
  verifyToken,
  verifyTruckOwner,
  upload.array("documents", 5),
  registerVehicle
);

// Admin: Update vehicle status(Approve Vehicle)
router.patch(
  "/status/:vehicleId",
  verifyToken,
  verifyAdminOrStaff,
  updateVehicleStatus
);

// Get all vehicles
router.get("/all-vehicles", verifyToken, getVehiclesByTruckOwner);

// Admin and TruckOwner: Get all vehicles
router.get("/all-vehicles", verifyToken, getAllVehicles);

// TruckOwner: Get all vehicles
router.get(
  "/get-all-trucks",
  verifyToken,
  verifyTruckOwner,
  getAllVehiclesForTruckOwner
);

// Admin and Staff: Get vehicle details by vehicleIdentity
router.get(
  "/search/:vehicleIdentity",
  verifyToken,
  verifyAdminOrStaff,
  getVehicleByIdentity
);

// Admin & Staff: Get all vehicles with status "Submitted"
router.get(
  "/submitted-vehicles",
  verifyToken,
  verifyAdminOrStaff,
  getAllSubmittedVehicles
);

// Admin & Staff: Get all vehicles with status "Aproved"
router.get(
  "/approved-vehicles",
  verifyToken,
  verifyAdminOrStaff,
  getApprovedVehicle
);

// Admin & Staff: Get all vehicles with status "Reject"
router.get(
  "/rejected-vehicles",
  verifyToken,
  verifyAdminOrStaff,
  getRejectedVehicle
);

// Get Vehicle by ID
router.get("/get/:vehicleId", verifyToken, getVehicleById);

// Reject Vehicle by ID and Send SMS
router.patch(
  "/reject/:vehicleId",
  verifyToken,
  verifyAdminOrStaff,
  rejectVehicle
);

// Admin & Staff: Count all vehicle
router.get(
  "/vehicle-counts",
  verifyToken,
  verifyAdminOrStaff,
  getVehicleCounts
);

export default router;
