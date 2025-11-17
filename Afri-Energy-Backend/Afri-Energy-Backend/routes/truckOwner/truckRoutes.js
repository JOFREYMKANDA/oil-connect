import express from "express";
import {
  addDriver,
  assignDriverToOrder,
  deleteDriver,
  editDriver,
  getAllDrivers,
  getAvailableDrivers,
} from "../../controller/truckOwner/truckController.js";
import { verifyToken, verifyTruckOwner } from "../../utils/verifyToken.js";

const router = express.Router();

// Add Driver (TruckOwner Only)
router.post("/add-driver", verifyToken, verifyTruckOwner, addDriver);

// Assign driver to an approved order
router.post(
  "/assign-driver",
  verifyToken,
  verifyTruckOwner,
  assignDriverToOrder
);

// View all drivers
router.get("/all-drivers", verifyToken, verifyTruckOwner, getAllDrivers);

// Delete Driver
router.delete("/delete/:driverId", verifyToken, verifyTruckOwner, deleteDriver);

// Edit Driver Information
router.patch("/edit/:driverId", verifyToken, verifyTruckOwner, editDriver);

// Get all available drivers
router.get(
  "/available-driver",
  verifyToken,
  verifyTruckOwner,
  getAvailableDrivers
);

export default router;
