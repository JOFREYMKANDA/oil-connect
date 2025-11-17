import { createError } from "../../utils/error.js";
import Driver from "../../models/drivers/Driver.js";
import Order from "../../models/orders/Order.js";
import User from "../../models/User.js";
import Vehicle from "../../models/vehicles/Vehicle.js";
import {
  sendMessageToCustomer,
  sendMessageToDriver,
} from "../../utils/websocket.js";

// Add Driver
export const addDriver = async (req, res, next) => {
  const {
    firstname,
    lastname,
    phoneNumber,
    email,
    licenseNumber,
    licenseExpireDate,
  } = req.body;

  try {
    const existingDriver = await Driver.findOne({ phoneNumber });
    if (existingDriver) {
      return next(createError(400, "Phone number already registered as a driver."));
    }

    const existingUser = await User.findOne({ phoneNumber });
    if (existingUser) {
      return next(createError(400, "Phone number already registered as a user."));
    }

    const existingLicense = await Driver.findOne({ licenseNumber });
    if (existingLicense) {
      return next(createError(400, "License number already registered."));
    }

    // Validate license expiration date
    const now = new Date();
    now.setUTCHours(0, 0, 0, 0); 
    if (new Date(licenseExpireDate) <= now) {
      return next(
        createError(400, "License expiration date must be a valid future date.")
      );
    }

    // Validate license number format (exactly 10 digits)
    if (!/^\d{10}$/.test(licenseNumber)) {
      return next(createError(400, "License number must be exactly 10 digits."));
    }

    // Ensure the logged-in user (TruckOwner) exists
    if (!req.user || !req.user.id) {
      return next(createError(403, "You are not authorized to add a driver."));
    }

    // Create the new driver
    const newDriver = new Driver({
      firstname,
      lastname,
      email,
      phoneNumber,
      licenseNumber,
      licenseExpireDate,
      role: "Driver",
      truckOwnerId: req.user.id, 
    });

    const savedDriver = await newDriver.save();

    res.status(201).json({
      message: "Driver registered successfully.",
      driver: {
        id: savedDriver.id,
        firstname: savedDriver.firstname,
        lastname: savedDriver.lastname,
        phoneNumber: savedDriver.phoneNumber,
        email: savedDriver.email,
        licenseNumber: savedDriver.licenseNumber,
        licenseExpireDate: savedDriver.licenseExpireDate,
      },
    });
  } catch (err) {
    console.error("Error adding driver:", err);
    next(err);
  }
};


//Assigned driver
export const assignDriverToOrder = async (req, res, next) => {
  const { driverId, orderId, vehicleId } = req.body;

  try {
    const order = await Order.findById(orderId).populate("customerId");
    if (!order) {
      return res.status(404).json({ message: "Order not found." });
    }

    if (order.status !== "Approved") {
      return res
        .status(400)
        .json({ message: "Order must be approved before assigning a driver." });
    }

    const driver = await Driver.findById(driverId);
    if (!driver) {
      return res.status(404).json({ message: "Driver not found." });
    }

    if (driver.status !== "available") {
      return res
        .status(400)
        .json({ message: "Driver is not available for assignment." });
    }

    const vehicle = await Vehicle.findById(vehicleId);
    if (!vehicle) {
      return res.status(404).json({ message: "Vehicle not found." });
    }

    if (vehicle.status !== "Approved") {
      return res
        .status(400)
        .json({ message: "Vehicle must be approved for assignment." });
    }

    // Assign driver and vehicle
    driver.status = "busy";
    driver.assignedOrder = orderId;
    await driver.save();

    vehicle.status = "Busy";
    await vehicle.save();

    order.driverId = driver._id;
    order.vehicleId = vehicle._id;
    order.status = "Assigned";
    await order.save();

    // Notify the driver
    const driverMessage = `Dear ${driver.firstname} ${driver.lastname}, 
    You have been assigned to oil tanker:
    Vehicle: ${vehicle.vehicleType} (${vehicle.plateNumber.headPlate}).
    Route: From depot (${order.depot}) to destination (${order.region}, ${order.district}, Latitude: ${order.latitude}, Longitude: ${order.longitude}).`;
    try {
      await sendMessageToDriver(driver._id.toString(), driverMessage);
    } catch (err) {
      console.error("Failed to send notification to driver:", err.message);
    }

    // Notify the customer
    const customer = order.customerId;
    const customerMessage = `Dear ${customer.firstname}, your order (ID: ${order._id}) has been assigned to:
    Driver: ${driver.firstname} ${driver.lastname}, Contact: ${driver.phoneNumber}.
    Vehicle: ${vehicle.vehicleType} (${vehicle.plateNumber.headPlate}).`;
    try {
      await sendMessageToCustomer(customer._id.toString(), customerMessage);
    } catch (err) {
      console.error("Failed to send notification to customer:", err.message);
    }

    res.status(200).json({
      message: "Driver and vehicle assigned to the order successfully.",
      driver: {
        firstname: driver.firstname,
        lastname: driver.lastname,
        phoneNumber: driver.phoneNumber,
        status: driver.status,
      },
      vehicle: {
        vehicleType: vehicle.vehicleType,
        plateNumber: vehicle.plateNumber.headPlate,
        status: vehicle.status,
      },
      orderId: order._id,
    });
  } catch (err) {
    next(err);
  }
};


export const getAllDrivers = async (req, res, next) => {
  try {
    const truckOwnerId = req.user.id;

    const drivers = await Driver.find({ truckOwnerId });

    if (!drivers.length) {
      return res
        .status(404)
        .json({ message: "No drivers found for this TruckOwner." });
    }

    res.status(200).json({
      message: "Drivers retrieved successfully.",
      drivers,
    });
  } catch (err) {
    console.error("Error fetching drivers:", err);
    next(err);
  }
};


export const getAvailableDrivers = async (req, res, next) => {
  try {
    const availableDrivers = await Driver.find({ status: "available" })
      .select("-password -__v -createdAt -updatedAt");

    if (!availableDrivers || availableDrivers.length === 0) {
      return res.status(404).json({ message: "No available drivers found." });
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

export const deleteDriver = async (req, res, next) => {
  const { driverId } = req.params;

  try {
    // Ensure the driver exists
    const driver = await Driver.findById(driverId);
    if (!driver) {
      return next(createError(404, "Driver not found"));
    }

    if (driver.truckOwnerId.toString() !== req.user.id) {
      return next(
        createError(403, "You are not authorized to delete this driver")
      );
    }

    // Delete the driver
    await Driver.findByIdAndDelete(driverId);

    res.status(200).json({
      message: "Driver deleted successfully",
    });
  } catch (err) {
    console.error("Error deleting driver:", err);
    next(err);
  }
};


//Update Driver information
export const editDriver = async (req, res, next) => {
  const { driverId } = req.params;
  const {
    firstname,
    lastname,
    phoneNumber,
    email,
    licenseNumber,
    licenseExpireDate,
  } = req.body;

  try {
    // Ensure the driver exists
    const driver = await Driver.findById(driverId);
    if (!driver) {
      return next(createError(404, "Driver not found"));
    }

    // Check if the driver belongs to the logged-in TruckOwner
    if (driver.truckOwnerId.toString() !== req.user.id) {
      return next(
        createError(403, "You are not authorized to edit this driver")
      );
    }

    // Validate license expiration date
    if (licenseExpireDate) {
      const now = new Date();
      now.setUTCHours(0, 0, 0, 0);
      if (new Date(licenseExpireDate) <= now) {
        return next(
          createError(
            400,
            "License expiration date must be a valid future date"
          )
        );
      }
    }

    // Validate license number
    if (licenseNumber && !/^\d{10}$/.test(licenseNumber)) {
      return next(createError(400, "License number must be exactly 10 digits"));
    }

    // Update driver information
    const updatedDriver = await Driver.findByIdAndUpdate(
      driverId,
      {
        $set: {
          firstname: firstname || driver.firstname,
          lastname: lastname || driver.lastname,
          phoneNumber: phoneNumber || driver.phoneNumber,
          email: email || driver.email,
          licenseNumber: licenseNumber || driver.licenseNumber,
          licenseExpireDate: licenseExpireDate || driver.licenseExpireDate,
        },
      },
      { new: true }
    );

    res.status(200).json({
      message: "Driver information updated successfully",
      driver: updatedDriver,
    });
  } catch (err) {
    console.error("Error updating driver information:", err);
    next(err);
  }
};
