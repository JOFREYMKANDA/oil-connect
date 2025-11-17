import express from "express";
import {
  verifyAdmin,
  verifyAdminOrStaff,
  verifyToken,
} from "../../utils/verifyToken.js";
import {
  addStaff,
  approveDriverLicense,
  deleteStation,
  downloadDriverLicense,
  getAllAcceptedOrders,
  getAllAssignedOrders,
  getAllCustomersWithOrders,
  getAllDepotsWithCompanies,
  getAllDriversSorted,
  getAllOrders,
  getAllPendingOrders,
  getAllStations,
  getAllTruckOwners,
  getAssignedOrderById,
  getCounts,
  getCustomerWithOrdersById,
  getDepotById,
  getDriverAssignedOrders,
  getDriverById,
  getSharedOrderById,
  history,
} from "../../controller/admin/adminController.js";

const router = express.Router();

// Add Staff (Admin Only)
router.post("/add-staff", verifyToken, verifyAdmin, addStaff);

router.get(
  "/pending-orders",
  verifyToken,
  verifyAdminOrStaff,
  getAllPendingOrders
);

router.get(
  "/accepted-orders",
  verifyToken,
  verifyAdminOrStaff,
  getAllAcceptedOrders
);

router.get(
  "/assigned-orders",
  verifyToken,
  verifyAdminOrStaff,
  getAllAssignedOrders
);

router.get(
  "/all-depots",
  verifyToken,
  verifyAdminOrStaff,
  getAllDepotsWithCompanies
);

// Get Depot by ID
router.get("/get-depot/:depotId", getDepotById);

router.get(
  "/customer-details",
  verifyToken,
  verifyAdminOrStaff,
  getAllCustomersWithOrders
);

router.get(
  "/customer-details/:customerId",
  verifyToken,
  verifyAdminOrStaff,
  getCustomerWithOrdersById
);

router.get("/all-orders", verifyToken, verifyAdminOrStaff, getAllOrders);

router.get("/counts", verifyToken, verifyAdminOrStaff, getCounts);

//Get History
router.get("/history", verifyToken, verifyAdminOrStaff, history);

// GET all driver assigned orders and truck owner assigned orders
router.get(
  "/driver-assigned",
  verifyToken,
  verifyAdminOrStaff,
  getDriverAssignedOrders
);

// GET all driver assigned orders by ID
router.get(
  "/assigned/:orderId",
  verifyToken,
  verifyAdminOrStaff,
  getAssignedOrderById
);

// Get shared order by orderId
router.get("/sharedOrder/:orderId", verifyToken, getSharedOrderById);

//Approve Driver licenses
router.patch("/approve-licenses/:driverId", verifyToken, approveDriverLicense);

//All Drivers
router.get("/all-drivers", verifyToken, getAllDriversSorted);

router.get("/drivers/:driverId", verifyToken, getDriverById);

router.get(
  "/drivers/download-license/:driverId",
  verifyToken,
  downloadDriverLicense
);

// Get all Depot
router.get(
  "/get-all-stations",
  verifyToken,
  verifyAdminOrStaff,
  getAllStations
);

// Get all truck owners
router.get("/get-truck-owners", verifyToken, getAllTruckOwners);

router.delete(
  "/delete/:stationId",
  verifyToken,
  verifyAdminOrStaff,
  deleteStation
);

export default router;
