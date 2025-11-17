import express from "express";
import { verifyToken, verifyTruckOwner } from "../../utils/verifyToken.js";
import {
  acceptOrder,
  assignAvailableDriverToOrder,
  getCustomerOrders,
  getCustomerOrdersByTruckOwner,
  getOrderByOrderId,
  getRequestedOrder,
  getTruckOwnerOrders,
  placeOrder,
  registerStation,
  searchOrderById,
} from "../../controller/orders/orderController.js";

const router = express.Router();

// Register a station (Customer Only)
router.post("/register-station", verifyToken, registerStation);

// Place an order For private customer
router.post("/place-order", verifyToken, placeOrder);

// Get all orders for a customer
router.get("/my-orders", verifyToken, getCustomerOrders);

// TruckOwner: View orders for a given customer
router.get(
  "/customer-orders/:customerId",
  verifyToken,
  verifyTruckOwner,
  getCustomerOrdersByTruckOwner
);

// TruckOwner: Get customers and vehicles with matching orders
router.get(
  "/view-all-orders",
  verifyToken,
  verifyTruckOwner,
  getRequestedOrder
);

// TruckOwner: Accepted Order and Notify Customer
router.patch(
  "/accept-order/:orderId",
  verifyToken,
  verifyTruckOwner,
  acceptOrder
);

// Search order by ID
router.get("/search/:orderId", verifyToken, searchOrderById);

// Get Order information by order ID
router.get("/getOrderId/:orderId", verifyToken, getOrderByOrderId);

// Assigned Order to a Driver
router.patch(
  "/assign-driver/:orderId/:driverId",
  verifyToken,
  verifyTruckOwner,
  assignAvailableDriverToOrder
);

// Get Accepted Order
router.get("/all-orders", verifyToken, verifyTruckOwner, getTruckOwnerOrders);

export default router;
