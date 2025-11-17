import WebSocket from "ws";
import { WebSocketServer } from "ws";
import Message from "../models/message/Message.js";

const websocketConnections = new Map(); 

export const setupWebSocketServer = (server) => {
  const wss = new WebSocketServer({ server });

  wss.on("connection", (ws, req) => {
    const truckOwnerId = req.url.split("?ownerId=")[1];

    if (!truckOwnerId) {
      ws.close(4000, "Truck owner ID is required.");
      return;
    }

    console.log(`WebSocket connected for truckOwnerId: ${truckOwnerId}`);
    websocketConnections.set(truckOwnerId, ws);

    ws.on("close", () => {
      console.log(`WebSocket disconnected for truckOwnerId: ${truckOwnerId}`);
      websocketConnections.delete(truckOwnerId);
    });
  });

  return wss;
};

// Trigger message to truck owner
export const sendMessageToTruckOwner = async (truckOwnerId, message) => {
  const ws = websocketConnections.get(truckOwnerId);

  if (!ws || ws.readyState !== WebSocket.OPEN) {
    console.log(`TruckOwner ${truckOwnerId} is not connected. Saving message.`);
    await Message.create({
      truckOwnerId,
      message,
      status: "unread",
    });
    return;
  }

  ws.send(JSON.stringify({ message }));
};

export const checkCustomerConnection = (customerId) => {
  return websocketConnections.has(customerId);
};

//Triggle message to customer
export const sendMessageToCustomer = async (customerId, message) => {
  const ws = websocketConnections.get(customerId);

  if (!ws || ws.readyState !== WebSocket.OPEN) {
    console.log(`Customer ${customerId} is not connected. Saving message.`);

    await Message.create({
      customerId,
      message,
      status: "unread",
    });
    return;
  }

  ws.send(JSON.stringify({ message }));
};

//Triggle message to driver
export const sendMessageToDriver = async (driverId, message) => {
  const ws = websocketConnections.get(driverId);
  if (!ws || ws.readyState !== WebSocket.OPEN) {
    console.log(`Driver ${driverId} is not connected. Saving message.`);
    await Message.create({
      driverId,
      message,
      status: "unread",
    });
    return;
  }
  ws.send(JSON.stringify({ message }));
};

// Trigger message to admin
export const sendMessageToAdmin = async (adminId, message) => {
  const ws = websocketConnections.get(adminId);

  if (!ws || ws.readyState !== WebSocket.OPEN) {
    console.log(`Admin ${adminId} is not connected. Saving message.`);
    await Message.create({
      adminId,
      message,
      status: "unread",
    });
    return;
  }

  ws.send(JSON.stringify({ message }));
};

// Trigger message to Staffs
export const sendMessageToStaff = async (staffId, message) => {
  const ws = websocketConnections.get(staffId);

  if (!ws || ws.readyState !== WebSocket.OPEN) {
    console.log(`Staff ${staffId} is not connected. Saving message.`);

    // Save the message in the database if staff is offline
    await Message.create({
      staffId,
      message,
      status: "unread",
    });
    return;
  }

  ws.send(JSON.stringify({ message }));
};
