import express from "express";
import {
  getAllGpsData,
  getConfiguredGps,
} from "../../controller/gps/gpsController.js";

const router = express.Router();

// All GPS data
router.get("/all-gps", getAllGpsData);

router.get("/configured", getConfiguredGps);

export default router;
