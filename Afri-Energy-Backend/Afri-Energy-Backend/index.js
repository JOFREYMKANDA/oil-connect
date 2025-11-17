import express from "express";
import dotenv from "dotenv";
import mongoose from "mongoose";
import http from "http";
import cors from "cors";
import cookieParser from "cookie-parser";
import path from "path";
import { fileURLToPath } from "url";
import { Server } from "socket.io";
import net from "net";

// Routes & Controller
import authRouter from "./routes/auth.js";
import usersRouter from "./routes/users.js";
import adminRouter from "./routes/admin/adminRoutes.js";
import staffRouter from "./routes/staff/staffRoutes.js";
import trucksRouter from "./routes/truckOwner/truckRoutes.js";
import vehiclesRouter from "./routes/vehicles/vehicle.js";
import driversRouter from "./routes/driver/driverRoutes.js";
import documentRoutes from "./routes/documents/documentsRoutes.js";
import messageRoutes from "./routes/message/messageRoutes.js";
import customerRoutes from "./routes/customer/customerRoute.js";
import ordersRoutes from "./routes/orders/orderRoutes.js";
import harusiRoutes from "./routes/harusi/harusiRoutes.js";
import gpsRoutes from "./routes/gps/gpsRoutes.js";
import { handleGpsData } from "./controller/gps/gpsController.js";
import { createDefaultAdmin } from "./controller/auth.js";

// Swagger
import swaggerUi from "swagger-ui-express";
import swaggerJsdoc from "swagger-jsdoc";
import swaggerDefinition from "./swaggerDocs.js";

// Environment setup
dotenv.config();
const app = express();
const api = process.env.API_URL;
const PORT = process.env.PORT || 4000;

// File Paths
const __filename = fileURLToPath(import.meta.url);
export const __dirname = path.dirname(__filename);
export const BASE_URL = process.env.BASE_URL;

// Middleware
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
    allowedHeaders: ["Content-Type", "Authorization", "No-Auth"],
    credentials: true,
  })
);
app.use(express.json());
app.use(cookieParser());

// MongoDB Connection
mongoose
  .connect(process.env.CONNECTION_STRING, {
    dbName: "Africom_Energy_Db",
    useNewUrlParser: true,
    useUnifiedTopology: true,
    serverSelectionTimeoutMS: 30000,
    socketTimeoutMS: 60000,
  })
  .then(async () => {
    console.log(" MongoDB connected");
    await createDefaultAdmin();
  })
  .catch((error) => console.error(" MongoDB error:", error));

mongoose.connection.on("disconnected", () => {
  console.log(" MongoDB disconnected");
});

// Static File Routes
app.use(
  "/api/v1/public/uploads",
  express.static(path.join(__dirname, "public", "uploads"))
);
app.use(
  "/api/v1/public/licenses",
  express.static(path.join(__dirname, "public", "licenses"))
);
app.use(
  "/api/v1/public/drivers",
  express.static(path.join(__dirname, "public", "drivers"))
);
app.use(
  "/api/v1/public/documents",
  express.static(path.join(__dirname, "public", "documents"))
);

// API Routes
app.use(`${api}/auth`, authRouter);
app.use(`${api}/users`, usersRouter);
app.use(`${api}/admin`, adminRouter);
app.use(`${api}/staff`, staffRouter);
app.use(`${api}/trucks`, trucksRouter);
app.use(`${api}/drivers`, driversRouter);
app.use(`${api}/vehicles`, vehiclesRouter);
app.use(`${api}/messages`, messageRoutes);
app.use(`${api}/orders`, ordersRoutes);
app.use(`${api}/customer`, customerRoutes);
app.use(`${api}/documents`, documentRoutes);
app.use(`${api}/harusi`, harusiRoutes);
app.use(`${api}/gps`, gpsRoutes);

// Error Handler
app.use((err, req, res, next) => {
  const errorStatus = err.status || 500;
  const errorMessage = err.message || "Something went wrong!";
  res.status(errorStatus).json({
    success: false,
    status: errorStatus,
    message: errorMessage,
    stack: err.stack,
  });
});

// WebSocket server
const httpServer = http.createServer();
const io = new Server(httpServer, {
  cors: { origin: "*", methods: ["GET", "POST", "DELETE", "PATCH"] },
});

httpServer.listen(7000, () =>
  console.log(" WebSocket running at ws://161.35.225.205:7000")
);

//  TCP Server for GPS
const tcpServer = net.createServer((socket) => {
  console.log("Device connected:", socket.remoteAddress);
  socket.on("data", async (data) => {
    await handleGpsData(data, socket, io);
  });
  socket.on("end", () => console.log("Device disconnected"));
  socket.on("error", (err) => console.error(" TCP Error:", err));
});

tcpServer.listen(process.env.SOCKET_PORT, "0.0.0.0", () =>
  console.log(`TCP server listening on port ${process.env.SOCKET_PORT}`)
);

// The TruckOwner, Customer and Driver joins a WebSocket room
io.on("connection", (socket) => {
  const truckOwnerId = socket.handshake.headers["x-truckowner-id"];
  const driverId = socket.handshake.headers["x-driver-id"];
  const customerId = socket.handshake.headers["x-customer-id"]; 

  if (truckOwnerId) {
    socket.join(`truckowner:${truckOwnerId}`);
    console.log("Truck owner joined:", `truckowner:${truckOwnerId}`);
  }

  if (driverId) {
    socket.join(`driver:${driverId}`);
    console.log("Driver joined:", `driver:${driverId}`);
  }

  if (customerId) {
    socket.join(`customer:${customerId}`);
    console.log("Customer joined:", `customer:${customerId}`);
  }

  socket.on("disconnect", () => {
    console.log("Client disconnected");
  });
});

app.get('/', (req, res) => {
  res.send('Hello from Node.js on DigitalOcean!');
});

//  Start HTTP API Server

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});


//  Swagger Docs
const swaggerOptions = {
  definition: swaggerDefinition,
  apis: [],
};
const swaggerDocs = swaggerJsdoc(swaggerOptions);
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocs));

