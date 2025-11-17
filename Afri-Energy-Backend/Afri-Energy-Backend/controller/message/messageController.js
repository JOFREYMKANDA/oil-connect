import Message from "../../models/message/Message.js";
import Vehicle from "../../models/vehicles/Vehicle.js";
import mongoose from "mongoose";

import {
  checkCustomerConnection,
  sendMessageToCustomer,
} from "../../utils/websocket.js";

export const sendLiveMessage = async (req, res, next) => {
  const { vehicleId } = req.params;
  const { message } = req.body;

  if (!message) {
    return res.status(400).json({ message: "Message is required." });
  }

  try {
    // Find the vehicle and its associated truck owner
    const vehicle = await Vehicle.findById(vehicleId).populate("owner");
    if (!vehicle) {
      return res.status(404).json({ message: "Vehicle not found." });
    }

    const truckOwnerId = vehicle.owner?._id;
    if (!truckOwnerId) {
      return res
        .status(404)
        .json({ message: "Truck owner not found for this vehicle." });
    }

    try {
      // Attempt to send the message
      sendMessageToTruckOwner(truckOwnerId.toString(), message);
      res
        .status(200)
        .json({ message: "Message sent successfully to the truck owner." });
    } catch (err) {
      // Store undelivered message
      const newMessage = new Message({
        truckOwnerId,
        message,
        status: "unread",
      });
      await newMessage.save();

      res.status(200).json({
        message: "Message sent successfully to the truck owner.",
      });
    }
  } catch (err) {
    next(err);
  }
};

//Admin & Truckowner send live message to customer
export const sendLiveMessageToCustomer = async (req, res, next) => {
  const { customerId, message } = req.body;

  if (!customerId || !message) {
    return res
      .status(400)
      .json({ message: "Customer ID and message are required." });
  }

  try {
    // Check if the customer is connected
    const isCustomerOnline = checkCustomerConnection(customerId);

    if (isCustomerOnline) {
      // Send the message via WebSocket
      sendMessageToCustomer(customerId, message);
    } else {
      console.log(`Customer ${customerId} is not online. Saving message.`);

      const newMessage = new Message({
        customerId,
        message,
        status: "unread",
      });

      await newMessage.save();
    }

    res.status(200).json({ message: "Message sent or saved successfully." });
  } catch (err) {
    console.error("Error sending message to customer:", err);
    next(err);
  }
};

//Recieve Message
export const getOfflineMessages = async (req, res, next) => {
  try {
    const truckOwnerId = req.user.id;

    const offlineMessages = await Message.find({
      truckOwnerId,
      status: "read",
    });

    if (!offlineMessages.length) {
      return res.status(404).json({ message: "No offline messages found." });
    }

    // Mark the messages as read
    await Message.updateMany(
      { truckOwnerId, status: "read" },
      { $set: { status: "read" } }
    );

    res.status(200).json({
      message: "Messages delivered successfully .",
      offlineMessages,
    });
  } catch (err) {
    next(err);
  }
};

//Get Message History
export const getMessageHistory = async (req, res, next) => {
  try {
    const truckOwnerId = req.user.id;

    // Fetch all messages
    const messageHistory = await Message.find({ truckOwnerId }).sort({
      createdAt: -1,
    });

    if (!messageHistory.length) {
      return res.status(404).json({ message: "No message history found." });
    }

    //  Mark all unread messages as read
    await Message.updateMany(
      { truckOwnerId, status: "unread" },
      { $set: { status: "unread" } }
    );

    res.status(200).json({
      message: "Message history retrieved successfully.",
      messageHistory,
    });
  } catch (err) {
    next(err);
  }
};

export const deleteMessage = async (req, res, next) => {
  const { messageId } = req.params;

  try {
    // Find the message
    const message = await Message.findById(messageId);

    if (!message) {
      return res.status(404).json({ message: "Message not found." });
    }

    if (
      req.user.role !== "Admin" &&
      message.truckOwnerId.toString() !== req.user.id
    ) {
      return res
        .status(403)
        .json({ message: "You are not authorized to delete this message." });
    }

    // Delete the message
    await Message.findByIdAndDelete(messageId);

    res.status(200).json({ message: "Message deleted successfully." });
  } catch (err) {
    next(err);
  }
};

//Customer Recieve message
export const getMessagesForCustomer = async (req, res, next) => {
  try {
    const customerId = req.user.id;

    const customerMessages = await Message.find({
      customerId,
    }).sort({ createdAt: -1 });

    if (!customerMessages.length) {
      return res.status(404).json({ message: "No messages found." });
    }

    // Mark messages as read
    await Message.updateMany(
      { customerId, status: "unread" },
      { $set: { status: "read" } }
    );

    res.status(200).json({
      message: "Messages delivered successfully .",
      customerMessages,
    });
  } catch (err) {
    next(err);
  }
};

export const getMessagesForDriver = async (req, res, next) => {
  try {
    const driverId = req.user.id;

    const driverMessages = await Message.find({ driverId }).sort({
      createdAt: -1,
    });

    if (!driverMessages.length) {
      return res.status(404).json({ message: "No messages found." });
    }

    await Message.updateMany(
      { driverId, status: "unread" },
      { $set: { status: "read" } }
    );

    res.status(200).json({
      message: "Driver messages delivered successfully .",
      messages: driverMessages,
    });
  } catch (err) {
    next(err);
  }
};

//Staff get message
export const getMessagesForStaff = async (req, res, next) => {
  try {
    const staffId = req.user.id;

    // Find messages for the staff
    const staffMessages = await Message.find({ staffId })
      .sort({ createdAt: -1 })
      .select("-__v");

    if (!staffMessages.length) {
      return res
        .status(404)
        .json({ message: "No messages found for the staff." });
    }

    await Message.updateMany(
      { staffId, status: "unread" },
      { $set: { status: "read" } }
    );

    res.status(200).json({
      message: "Messages retrieved successfully.",
      staffMessages,
    });
  } catch (err) {
    next(err);
  }
};

export const countAllMessages = async (req, res, next) => {
  try {
    const truckOwnerId = req.user.id;

    const unreadCount = await Message.countDocuments({
      truckOwnerId,
      status: "unread",
    });

    res.status(200).json({
      success: true,
      totalMessages: unreadCount,
    });
  } catch (err) {
    console.error("Error counting unread messages:", err);
    next(err);
  }
};

export const readMessageById = async (req, res, next) => {
  try {
    const { messageId } = req.params;
    const truckOwnerId = req.user.id; // Authenticated truck owner

    const message = await Message.findOne({
      _id: messageId,
      truckOwnerId,
    });

    if (!message) {
      return res.status(404).json({ message: "Message not found." });
    }

    // Update status to 'read' if still unread
    if (message.status === "unread") {
      message.status = "read";
      await message.save();
    }

    res.status(200).json({
      success: true,
      message: "Message retrieved successfully.",
      data: message,
    });
  } catch (err) {
    console.error("Error reading message:", err);
    next(err);
  }
};
