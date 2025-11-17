import dotenv from "dotenv";
import Driver from "../../models/drivers/Driver.js";
import Order from "../../models/orders/Order.js";
import { createError } from "../../utils/error.js";
import moment from "moment";
import path from "path";
import fs from "fs";
import { __dirname } from "../../index.js";
import { sendSMS } from "../../utils/otp.js";

dotenv.config();

//Get all information
export const getDriverDetails = async (req, res, next) => {
  try {
    if (req.user.role !== "Driver") {
      return next(
        createError(403, "Access denied. Only drivers can have access.")
      );
    }

    const driver = await Driver.findById(req.user.id).select("-password");

    if (!driver) {
      return next(createError(404, "Driver not found."));
    }

    res.status(200).json(driver);
  } catch (err) {
    next(err);
  }
};

//Update profile
export const updateDriverInfo = async (req, res, next) => {
  try {
    const { workingPosition, region, district } = req.body;
    const driver = await Driver.findById(req.user.id);

    if (!driver) {
      return res.status(404).json({ message: "Driver not found." });
    }

    // Check if driver has an assigned order with status "onDelivery"
    if (driver.assignedOrder) {
      const order = await Order.findById(driver.assignedOrder);
      if (order && order.status === "onDelivery") {
        return res.status(400).json({
          message:
            "Cannot update any information while the order is on delivery.",
        });
      }
    }

    if (workingPosition) driver.workingPosition = workingPosition;
    if (region) driver.region = region;
    if (district) driver.district = district;

    // Handle profile image upload
    if (req.file) {
      driver.profileImage = req.file.path;
    }

    await driver.save();

    res.status(200).json({
      message: "Driver information updated successfully.",
      driver: {
        id: driver._id,
        firstname: driver.firstname,
        lastname: driver.lastname,
        phoneNumber: driver.phoneNumber,
        email: driver.email,
        profileImage: driver.profileImage,
        workingPosition: driver.workingPosition,
        region: driver.region,
        district: driver.district,
      },
    });
  } catch (err) {
    next(err);
  }
};

export const getAssignedOrderForDriver = async (req, res, next) => {
  try {
    const driverId = req.user.id;

    const driverOrders = await Order.find({
      driverId,
      status: { $in: ["Assigned", "onDelivery", "Completed"] },
    })
      .populate({
        path: "truckOwnerId",
        select: "firstname lastname phoneNumber email",
        model: "User",
      })
      .populate("customerId", "firstname lastname phoneNumber email")
      .populate("stations", "stationName region district latitude longitude")
      .populate("companies", "name latitude longitude") 
      .sort({ createdAt: -1 });

    if (!driverOrders.length) {
      return res.status(404).json({
        message: "No orders found for this driver.",
      });
    }

    res.status(200).json({
      message: "Orders retrieved successfully.",
      orders: driverOrders,
    });
  } catch (err) {
    console.error("Error retrieving driver orders:", err);
    next(err);
  }
};


export const getAvailableDrivers = async (req, res, next) => {
  try {
    const truckOwnerId = req.user.id;

    const availableDrivers = await Driver.find({
      status: "available",
      truckOwnerId: truckOwnerId,
    })
      .select("-__v -createdAt -updatedAt")
      .lean();

    if (!availableDrivers || availableDrivers.length === 0) {
      return res
        .status(404)
        .json({ message: "No available drivers found for this truck owner." });
    }

    res.status(200).json({
      message: "Available drivers retrieved successfully.",
      drivers: availableDrivers,
    });
  } catch (err) {
    console.error("Error fetching available drivers:", err);
    next(err);
  }
};

export const startTrip = async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const { orderId } = req.params;

    // Find the order with driver and customer populated
    const order = await Order.findOne({ _id: orderId, driverId }).populate(
      "customerId",
      "firstname lastname phoneNumber"
    );

    if (!order) {
      return res
        .status(404)
        .json({ message: "Order not found or not assigned to you." });
    }

    if (order.status !== "Assigned") {
      return res
        .status(400)
        .json({ message: "Order is not in a state to start the trip." });
    }

    // Update status
    order.status = "onDelivery";
    order.tripStartedAt = moment().format("YYYY-MM-DD HH:mm:ss");
    await order.save();

    // Send SMS to customer
    const customer = order.customerId;
    const message = `Dear ${customer.firstname}, your delivery trip for order ${order.orderId} has started. You will be notified upon arrival.`;

    try {
      await sendSMS(customer.phoneNumber, message);
    } catch (err) {
      console.error("Failed to send SMS to customer:", err.message);
    }

    res.status(200).json({
      message: "Trip started successfully. Customer notified.",
      order,
    });
  } catch (err) {
    next(err);
  }
};

export const endTrip = async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const { orderId } = req.params;

    const order = await Order.findOne({ _id: orderId, driverId });
    if (!order) {
      return res
        .status(404)
        .json({ message: "Order not found or not assigned to you." });
    }

    if (order.status !== "onDelivery") {
      return res
        .status(400)
        .json({ message: "Order is not in a state to be completed." });
    }

    order.status = "Completed";
    order.tripEndedAt = moment(new Date()).format("YYYY-MM-DD HH:mm:ss");
    await order.save();

    const driver = await Driver.findById(driverId);
    if (!driver) {
      return res.status(404).json({ message: "Driver not found." });
    }
    driver.status = "available";
    driver.assignedOrder = null;
    await driver.save();

    res.status(200).json({
      message:
        "Trip ended successfully. Order marked as Completed and driver is now available.",
      order,
      driver,
    });
  } catch (err) {
    next(err);
  }
};

export const uploadDriverLicense = async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const driver = await Driver.findById(driverId);

    if (!driver) {
      return res.status(404).json({ message: "Driver not found" });
    }

    if (driver.status !== "unverified") {
      return res.status(403).json({
        message: "Only unverified drivers are allowed to upload license image",
      });
    }

    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" });
    }

    // Delete old license if it exists
    if (driver.licenseImage) {
      const oldRelative = driver.licenseImage.replace(process.env.BASE_URL, "");
      const oldPath = path.join(
        __dirname,
        "public",
        oldRelative.replace(/^\/?api\/v1\/public\//, "")
      );
      if (fs.existsSync(oldPath)) {
        fs.unlinkSync(oldPath);
      }
    }

    const relativePath = `licenses/${req.file.filename}`;

    //  Normalize base URL to avoid double `/api/v1`
    let baseUrl = process.env.BASE_URL;
    baseUrl = baseUrl.replace(/\/+$/, ""); // trim trailing slash
    baseUrl = baseUrl.replace(/\/api\/v1$/, ""); // remove if already included

    const fullUrl = `${baseUrl}/api/v1/public/${relativePath}`;

    //  Save full public URL in DB
    driver.licenseImage = fullUrl;
    driver.lastUpdatedAt = new Date();
    await driver.save();

    res.status(200).json({
      message: "License image uploaded successfully",
    });
  } catch (err) {
    console.error("Upload error:", err);
    next(err);
  }
};

export const getDriverLicenseImage = async (req, res, next) => {
  try {
    const { driverId } = req.params;
    const driver = await Driver.findById(driverId);

    if (!driver) {
      return res.status(404).json({ message: "Driver not found." });
    }

    if (!driver.licenseImage) {
      return res
        .status(404)
        .json({ message: "License image not uploaded yet." });
    }

    res.status(200).json({
      success: true,
      licenseImage: driver.licenseImage,
    });
  } catch (err) {
    console.error("Error fetching license image:", err);
    next(err);
  }
};
