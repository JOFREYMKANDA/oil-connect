import express from "express";
import { verifyAdminOrStaff, verifyToken } from "../../utils/verifyToken.js";

import {
  deleteStation,
  getAllDepotsWithSources,
  getAllStationsForCustomer,
  getSharedOrders,
  getSharedOrdersAndCustomers,
  placeSharedOrder,
  processCustomerOrder,
  searchMatchingOrders,
} 
from "../../controller/customer/customerController.js";

const router = express.Router();

//Customer Place an order in shared orders
router.post("/place-shared-order", verifyToken, placeSharedOrder);

//Customer: Get all shared orders
router.get("/shared-orders", verifyToken, getSharedOrders);

// Customer: Get all stations
router.get("/all-stations", verifyToken, getAllStationsForCustomer);

// Get all depots with their sources
router.get("/all-depot", getAllDepotsWithSources);

//Filter order
router.get("/filter-shared-orders", verifyToken, getSharedOrdersAndCustomers);

//Search order
router.post("/search-shared-orders", verifyToken, searchMatchingOrders);

//Save matches order
router.post(
  "/process-order/:orderId/:customerId",
  verifyToken,
  processCustomerOrder
);

// Delete a station
router.delete(
  "/delete/:stationId",
  verifyToken,
  verifyAdminOrStaff,
  deleteStation
);

export default router;
