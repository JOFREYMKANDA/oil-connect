import express from "express";
import {
  countAllMessages,
  deleteMessage,
  getMessageHistory,
  getMessagesForCustomer,
  getMessagesForDriver,
  getMessagesForStaff,
  getOfflineMessages,
  readMessageById,
  sendLiveMessage,
  sendLiveMessageToCustomer,
} from "../../controller/message/messageController.js";

import {
  verifyToken,
  verifyTruckOwner,
  verifyAdminOrStaff,
} from "../../utils/verifyToken.js";

const router = express.Router();

// Admin: Send live message to Truck Owner based on vehicle
router.post(
  "/send/:vehicleId",
  verifyToken,
  verifyAdminOrStaff,
  sendLiveMessage
);

// TruckOwner: Get offline messages
router.get(
  "/recieve-messages",
  verifyToken,
  verifyTruckOwner,
  getOfflineMessages
);

// TruckOwner: Get message history
router.get("/history", verifyToken, verifyTruckOwner, getMessageHistory);

// TruckOwner: Send live message to a Customer
router.post("/send-customer", verifyToken, sendLiveMessageToCustomer);

// Customer: Get messages
router.get("/customer-messages", verifyToken, getMessagesForCustomer);

// Driver: View messages
router.get("/driver-messages", verifyToken, getMessagesForDriver);

// Endpoint for staff to get their messages
router.get(
  "/staff-messages",
  verifyToken,
  verifyAdminOrStaff,
  getMessagesForStaff
);

// TruckOwner/Admin: Delete a message
router.delete(
  "/delete/:messageId",
  verifyToken,
  verifyTruckOwner,
  deleteMessage
);

// Count unread messages for truck owner
router.get("/count-all", verifyToken, verifyTruckOwner, countAllMessages);

//Read message by ID
router.get("/read/:messageId", verifyToken, verifyTruckOwner, readMessageById);

export default router;
