import GpsData from "../../models/gps/GpsData.js";
import Message from "../../models/message/Message.js";
import User from "../../models/User.js";
import Vehicle from "../../models/vehicles/Vehicle.js";
import { createError } from "../../utils/error.js";
import { sendSMS } from "../../utils/otp.js";
import moment from "moment";
import { generateVehicleIdentity } from "../../utils/vehicleIdGenerator.js";

// TruckOwner: Register Vehicle
export const registerVehicle = async (req, res, next) => {
  try {
    const {
      vehicleType,
      plateNumber,
      vehicleColor,
      vehicleModelYear,
      // fuelType,
      tankCapacity,
      latitude,
      longitude,
      numberOfCompartments,
      compartmentCapacities,
      // vehicleRegister,
    } = req.body;

    let parsedPlateNumber;
    try {
      parsedPlateNumber =
        typeof plateNumber === "string" ? JSON.parse(plateNumber) : plateNumber;
      if (!parsedPlateNumber?.trailerPlate) {
        return next(
          createError(
            400,
            'Trailer plate number is required in format: {"trailerPlate":"ABC123"}'
          )
        );
      }
    } catch (err) {
      return next(
        createError(400, "Invalid plate number format. Must be valid JSON")
      );
    }

    const existingPlate = await Vehicle.findOne({
      $or: [
        { "plateNumber.trailerPlate": parsedPlateNumber.trailerPlate },
        { "plateNumber.headPlate": parsedPlateNumber.headPlate || "" },
      ],
    });

    if (existingPlate) {
      const duplicateType =
        existingPlate.plateNumber.trailerPlate ===
        parsedPlateNumber.trailerPlate
          ? "trailer"
          : "head";
      return next(
        createError(
          409,
          `Vehicle with this ${duplicateType} plate already exists`
        )
      );
    }

    const uploadedDocuments =
      req.files?.map((file) => ({
        name: file.originalname,
        filePath: file.path,
      })) || [];

    let parsedCapacities;
    try {
      parsedCapacities = JSON.parse(compartmentCapacities);
      if (
        !Array.isArray(parsedCapacities) ||
        parsedCapacities.length !== Number(numberOfCompartments)
      ) {
        throw new Error();
      }
    } catch (err) {
      return next(
        createError(
          400,
          `Provide ${numberOfCompartments} valid compartment capacities as an array`
        )
      );
    }

    const totalCapacity = parsedCapacities.reduce(
      (sum, cap) => sum + Number(cap),
      0
    );
    if (totalCapacity > tankCapacity) {
      return next(
        createError(
          400,
          `Total compartments (${totalCapacity}Litres) exceed tank capacity (${tankCapacity}Litres)`
        )
      );
    }

    const vehicleIdentity = await generateVehicleIdentity(
      parsedPlateNumber.trailerPlate,
      tankCapacity,
      numberOfCompartments
    );

    // 8. Create new vehicle
    const newVehicle = new Vehicle({
      vehicleType,
      plateNumber: {
        headPlate: parsedPlateNumber.headPlate || null,
        trailerPlate: parsedPlateNumber.trailerPlate,
        specialPlate: parsedPlateNumber.specialPlate || null,
      },
      vehicleColor,
      vehicleModelYear,
      // fuelType, 
      tankCapacity,
      latitude: !isNaN(latitude) ? parseFloat(latitude) : null,
      longitude: !isNaN(longitude) ? parseFloat(longitude) : null,
      numberOfCompartments,
      compartmentCapacities: parsedCapacities.map((cap, i) => ({
        id: String.fromCharCode(65 + i), // A, B, C, etc.
        capacity: Number(cap),
      })),
      documents: uploadedDocuments,
      vehicleIdentity, 
      truckOwner: req.user.id,
      status: "Submitted",
      createdAt: moment().toDate(),
    });

    const savedVehicle = await newVehicle.save();

    res.status(201).json({
      success: true,
      message: "Vehicle registration submitted for approval",

    });
  } catch (err) {
    console.error("Registration error:", err);
    next(createError(500, "Registration failed. Please try again."));
  }
};

// Admin: Update Vehicle Status (Approve Vehicle) and Assign GPS
export const updateVehicleStatus = async (req, res, next) => {
  const { status, gpsImei } = req.body;

  try {
    if (!["Approved", "Rejected"].includes(status)) {
      return next(
        createError(400, "Invalid status. Must be 'Approved' or 'Rejected'.")
      );
    }

    const vehicle = await Vehicle.findById(req.params.vehicleId);
    if (!vehicle) {
      return next(createError(404, "Vehicle not found"));
    }

    if (status === "Approved") {
      if (!gpsImei) {
        return next(createError(400, "gpsImei is required for approval"));
      }

      // Set the GPS IMEI
      vehicle.gpsImei = gpsImei;

      // Generate vehicleIdentity
      const { trailerPlate } = vehicle.plateNumber;
      const { tankCapacity, numberOfCompartments } = vehicle;
      const vehicleIdentity = `${trailerPlate}${tankCapacity}${numberOfCompartments}`;
      vehicle.vehicleIdentity = vehicleIdentity;

      // Only assign GPS status once
      const gpsAlreadyInstalled = await GpsData.findOne({
        imei: gpsImei,
        status: "INSTALLED",
      });
      if (!gpsAlreadyInstalled) {
        await GpsData.updateMany(
          { imei: gpsImei },
          { status: "INSTALLED", vehicleIdentity }
        );
      }
    }

    vehicle.status = status;
    await vehicle.save();

    res.status(200).json({
      message: `Vehicle status updated to '${status}' successfully.`,
      vehicleId: vehicle._id,
      status: vehicle.status,
      gpsImei: vehicle.gpsImei,
      vehicleIdentity: vehicle.vehicleIdentity,
    });
  } catch (err) {
    next(err);
  }
};

//View Vehicles
export const getVehiclesByTruckOwner = async (req, res, next) => {
  const { ownerId } = req.params || {};
  const { page = 1, limit = 10 } = req.query;

  try {
    let query = {};

    // Admin can view all vehicles or filter by ownerId
    if (req.user.role === "Admin") {
      if (ownerId) {
        query.owner = ownerId;
      }
    } else if (req.user.role === "TruckOwner") {
      // TruckOwner can only view their vehicles
      query.owner = req.user.id;
    } else {
      return next(createError(403, "You are not authorized to view vehicles"));
    }

    // Pagination
    const skip = (page - 1) * limit;

    // Fetch vehicles based on query
    const vehicles = await Vehicle.find(query).skip(skip).limit(Number(limit));

    const totalVehicles = await Vehicle.countDocuments(query);

    if (!vehicles || vehicles.length === 0) {
      return res
        .status(404)
        .json({ message: "No vehicles found for the specified criteria" });
    }

    res.status(200).json({
      vehicles,
      pagination: {
        total: totalVehicles,
        page: Number(page),
        limit: Number(limit),
        pages: Math.ceil(totalVehicles / limit),
      },
    });
  } catch (err) {
    next(err);
  }
};

//Admin and TRuckOwner get all vehicles
export const getAllVehicles = async (req, res, next) => {
  try {
    const userRole = req.user.role;

    if (userRole !== "Admin" && userRole !== "TruckOwner") {
      return res.status(403).json({
        message: "You are not authorized to access this resource.",
      });
    }

    const vehicles = await Vehicle.find({})
      .select("-createdAt -updatedAt -documents -owner")
      .sort({ createdAt: -1 });

    if (!vehicles.length) {
      return res.status(404).json({ message: "No vehicles found." });
    }

    res.status(200).json({
      message: "Vehicles retrieved successfully.",
      vehicles,
    });
  } catch (err) {
    next(err);
  }
};

//TruckOwner get all its vehicles
export const getAllVehiclesForTruckOwner = async (req, res, next) => {
  try {
    const vehicles = await Vehicle.find({ truckOwner: req.user.id }).select(
      "-createdAt -updatedAt -documents -vehicleRegister -compartmentCapacities -numberOfCompartments -longitude -latitude -__v"
    );

    if (!vehicles.length) {
      return res
        .status(404)
        .json({ message: "No vehicles found for this TruckOwner." });
    }

    res.status(200).json({
      message: "Vehicles retrieved successfully.",
      vehicles,
    });
  } catch (err) {
    console.error("Error retrieving vehicles:", err);
    next(err);
  }
};

export const getVehicleByIdentity = async (req, res, next) => {
  const { vehicleIdentity } = req.params;

  try {
    // Validate input
    if (!vehicleIdentity) {
      return next(createError(400, "Vehicle identity is required"));
    }

    // Search for vehicle by vehicleIdentity
    const vehicle = await Vehicle.findOne({ vehicleIdentity }).select(
      "-documents -__v -createdAt -updatedAt"
    );

    if (!vehicle) {
      return next(
        createError(404, "Vehicle not found with the given identity")
      );
    }

    res.status(200).json({
      message: "Vehicle details retrieved successfully",
      vehicle,
    });
  } catch (err) {
    console.error("Error retrieving vehicle details:", err);
    next(err);
  }
};

export const getAllSubmittedVehicles = async (req, res, next) => {
  try {
    const submittedVehicles = await Vehicle.find({ status: "Submitted" })
      .select(" -__v -updatedAt")
      .populate("owner", "firstname lastname email phoneNumber")
      .sort({ createdAt: -1 });

    if (!submittedVehicles.length) {
      return res.status(404).json({ message: "No submitted vehicles found." });
    }

    res.status(200).json({
      message: "Submitted vehicles retrieved successfully.",
      vehicles: submittedVehicles,
    });
  } catch (err) {
    console.error("Error retrieving submitted vehicles:", err);
    next(err);
  }
};

export const getApprovedVehicle = async (req, res, next) => {
  try {
    const approvedVehicles = await Vehicle.find({ status: "Approved" })
      .select(" -__v -updatedAt")
      .populate("owner", "firstname lastname email phoneNumber")
      .sort({ createdAt: -1 });

    if (!approvedVehicles.length) {
      return res.status(404).json({ message: "No approved vehicles found." });
    }

    res.status(200).json({
      message: "Approved vehicles retrieved successfully.",
      vehicles: approvedVehicles,
    });
  } catch (err) {
    console.error("Error retrieving approved vehicles:", err);
    next(err);
  }
};

export const getRejectedVehicle = async (req, res, next) => {
  try {
    const rejectedVehicles = await Vehicle.find({ status: "Rejected" })
      .select(" -__v -updatedAt")
      .populate("owner", "firstname lastname email phoneNumber")
      .sort({ createdAt: -1 });

    if (!rejectedVehicles.length) {
      return res.status(404).json({ message: "No rejected vehicles found." });
    }

    res.status(200).json({
      message: "Rejected vehicles retrieved successfully.",
      vehicles: rejectedVehicles,
    });
  } catch (err) {
    console.error("Error retrieving rejected vehicles:", err);
    next(err);
  }
};

export const getVehicleById = async (req, res, next) => {
  try {
    const { vehicleId } = req.params;

    // Find the vehicle by ID
    const vehicle = await Vehicle.findById(vehicleId)
      .select("-createdAt -updatedAt")
      .populate("owner", "firstname lastname email phoneNumber")
      .sort({ createdAt: -1 });

    if (!vehicle) {
      return res.status(404).json({ message: "Vehicle not found" });
    }

    res.status(200).json({
      message: "Vehicle retrieved successfully",
      vehicle,
    });
  } catch (err) {
    next(err);
  }
};

export const getVehicleCounts = async (req, res, next) => {
  try {
    const submittedCount = await Vehicle.countDocuments({
      status: "Submitted",
    });
    const approvedCount = await Vehicle.countDocuments({ status: "Approved" });
    const rejectedCount = await Vehicle.countDocuments({ status: "Rejected" });

    res.status(200).json({
      message: "Vehicle counts retrieved successfully.",
      counts: {
        submitted: submittedCount,
        approved: approvedCount,
        rejected: rejectedCount,
      },
    });
  } catch (err) {
    console.error("Error retrieving vehicle counts:", err);
    next(err);
  }
};

export const rejectVehicle = async (req, res, next) => {
  try {
    const { vehicleId } = req.params;
    const { message } = req.body;

    if (!message || !message.trim()) {
      return res
        .status(400)
        .json({ message: "Rejection message is required." });
    }

    const vehicle = await Vehicle.findById(vehicleId);
    if (!vehicle) {
      return res.status(404).json({ message: "Vehicle not found" });
    }

    const owner = await User.findById(vehicle.owner);
    if (!owner) {
      return res.status(404).json({ message: "Owner not found" });
    }

    vehicle.status = "Rejected";
    await vehicle.save();

    const trimmedMessage = message.trim();

    const fullMessage = `Dear ${owner.firstname} ${owner.lastname},\n\nYour vehicle with plate ${vehicle.plateNumber.trailerPlate} has been rejected.\n\nReason:\n${trimmedMessage}\n\nFor more information, contact our support team.`;

    //  Send SMS if phone number exists
    if (owner.phoneNumber) {
      await sendSMS(owner.phoneNumber, fullMessage);
    }

    //  Save full rejection message to Message model
    await new Message({
      truckOwnerId: owner._id,
      message: fullMessage,
      status: "unread",
    }).save();

    res.status(200).json({
      message: "Vehicle rejected, message saved and SMS notification sent.",
      vehicleId: vehicle._id,
      status: vehicle.status,
    });
  } catch (err) {
    console.error("Error rejecting vehicle:", err);
    next(err);
  }
};
