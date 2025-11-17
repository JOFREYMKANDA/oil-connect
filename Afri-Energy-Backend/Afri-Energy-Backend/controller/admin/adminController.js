import bcrypt from "bcryptjs";
import { createError } from "../../utils/error.js";
import User from "../../models/User.js";
import Order from "../../models/orders/Order.js";
import Depot from "../../models/deport/Depot.js";
import Vehicle from "../../models/vehicles/Vehicle.js";
import moment from "moment";
import Driver from "../../models/drivers/Driver.js";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import { sendSMS } from "../../utils/otp.js";
import Station from "../../models/customer/Station.js";

// Setup __dirname for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Add Staff (Admin Only)
export const addStaff = async (req, res, next) => {
  const { firstname, lastname, phoneNumber, email, password, role } = req.body;

  try {
    // Verify that only admins can add staff
    if (req.user.role !== "Admin") {
      return next(createError(403, "You are not authorized to add staff"));
    }

    const existingUser = await User.findOne({ phoneNumber });
    if (existingUser) {
      return next(createError(400, "Phone number already registered"));
    }

    if (email) {
      const existingEmail = await User.findOne({ email });
      if (existingEmail) {
        return next(createError(400, "Email already registered"));
      }
    }

    // Hash the password
    const salt = bcrypt.genSaltSync(10);
    const hashedPassword = bcrypt.hashSync(password, salt);

    // Create the staff user
    const newStaff = new User({
      firstname,
      lastname,
      phoneNumber,
      email,
      password: hashedPassword,
      role: role || "Staff", // Default role is 'Staff'
    });

    await newStaff.save();

    res.status(201).json({
      message: "Staff member added successfully",
      staffId: newStaff.id,
    });
  } catch (err) {
    next(err);
  }
};

export const getAllPendingOrders = async (req, res, next) => {
  try {
    const pendingOrders = await Order.find({ status: "Pending" })
      .select("-__v")
      .populate("customerId", "firstname lastname phoneNumber email")
      .populate("stations", "stationName region district")
      .sort({ createdAt: -1 });

    if (!pendingOrders.length) {
      return res.status(404).json({ message: "No pending orders found." });
    }

    res.status(200).json({
      message: "Pending orders retrieved successfully.",
      orders: pendingOrders,
    });
  } catch (err) {
    console.error("Error retrieving pending orders:", err);
    next(err);
  }
};

export const getAllAcceptedOrders = async (req, res, next) => {
  try {
    const pendingOrders = await Order.find({ status: "Accepted" })
      .select("-__v")
      .populate("customerId", "firstname lastname phoneNumber email")
      .populate("stations", "stationName region district")
      .sort({ createdAt: -1 });

    if (!pendingOrders.length) {
      return res.status(404).json({ message: "No pending orders found." });
    }

    res.status(200).json({
      message: "Pending orders retrieved successfully.",
      orders: pendingOrders,
    });
  } catch (err) {
    console.error("Error retrieving pending orders:", err);
    next(err);
  }
};

export const getAllAssignedOrders = async (req, res, next) => {
  try {
    const assignedOrders = await Order.find({ status: "Assigned" })
      .select("-__v")
      .populate("customerId", "firstname lastname phoneNumber email")
      .populate("stations", "stationName region district")
      .sort({ createdAt: -1 });

    if (!assignedOrders.length) {
      return res.status(404).json({ message: "No assigned orders found." });
    }

    res.status(200).json({
      message: "Pending orders retrieved successfully.",
      orders: assignedOrders,
    });
  } catch (err) {
    console.error("Error retrieving assigned orders:", err);
    next(err);
  }
};

export const getDepotById = async (req, res, next) => {
  try {
    const { depotId } = req.params;

    const depot = await Depot.findById(depotId);

    if (!depot) {
      return res.status(404).json({ message: "Depot not found." });
    }

    const formattedDepot = {
      ...depot.toObject(),
      createdAt: moment(depot.createdAt).format("YYYY-MM-DD"),
      updatedAt: moment(depot.updatedAt).format("YYYY-MM-DD"),
    };

    res.status(200).json({
      message: "Depot retrieved successfully.",
      depot: formattedDepot,
    });
  } catch (err) {
    console.error("Error retrieving depot:", err);
    next(err);
  }
};

export const getAllDepotsWithCompanies = async (req, res, next) => {
  try {
    const depots = await Depot.find().select("-__v");

    if (!depots.length) {
      return res.status(404).json({ message: "No depots found." });
    }

    res.status(200).json({
      message: "Depots and associated companies retrieved successfully.",
      depots,
    });
  } catch (err) {
    console.error("Error retrieving depots and companies:", err);
    next(err);
  }
};

export const getAllCustomersWithOrders = async (req, res, next) => {
  try {
    // Find all customers who have placed an order
    const customersWithOrders = await User.aggregate([
      {
        $match: { role: "Customer" }, // Only fetch customers
      },
      {
        $lookup: {
          from: "orders",
          localField: "_id",
          foreignField: "customerId",
          as: "orders",
        },
      },
      {
        $project: {
          _id: 1,
          firstname: 1,
          lastname: 1,
          phoneNumber: 1,
          email: 1,
          region: 1,
          district: 1,
          orders: {
            _id: 1,
            fuelType: 1,
            capacity: 1,
            routeWay: 1,
            status: 1,
            depot: 1,
            source: 1,
            createdAt: 1,
          },
        },
      },
    ]);

    if (!customersWithOrders.length) {
      return res
        .status(404)
        .json({ message: "No customers with orders found." });
    }

    res.status(200).json({
      message: "Customers with orders retrieved successfully.",
      customers: customersWithOrders,
    });
  } catch (err) {
    console.error("Error retrieving customers with orders:", err);
    next(err);
  }
};

export const getCustomerWithOrdersById = async (req, res, next) => {
  try {
    const { customerId } = req.params;

    // Find the customer by ID
    const customer = await User.findOne({
      _id: customerId,
      role: "Customer",
    }).lean();
    if (!customer) {
      return res.status(404).json({ message: "Customer not found." });
    }

    const orders = await Order.find({ customerId })
      .populate("companies", "name")
      .select(
        "fuelType capacity routeWay status depot source createdAt companies"
      )
      .sort({ createdAt: -1 })
      .lean();

    res.status(200).json({
      message: "Customer and their orders retrieved successfully.",
      customer: {
        _id: customer._id,
        firstname: customer.firstname,
        lastname: customer.lastname,
        phoneNumber: customer.phoneNumber,
        email: customer.email,
        createdAt: customer.createdAt,
        region: customer.region,
        district: customer.district,
        orders: orders.length > 0 ? orders : "No orders found",
      },
    });
  } catch (err) {
    console.error("Error retrieving customer with orders:", err);
    next(err);
  }
};

export const getAllOrders = async (req, res, next) => {
  try {
    const orders = await Order.find()
      .populate("customerId", "firstname lastname email phoneNumber")
      .populate()
      .sort({ tripStartedAt: -1 });

    if (!orders.length) {
      return res.status(404).json({
        message: "No orders found.",
      });
    }

    res.status(200).json({
      message: "All orders retrieved successfully.",
      orders,
    });
  } catch (err) {
    next(err);
  }
};

//Counts
export const getCounts = async (req, res, next) => {
  try {
    const truckOwnerCount = await User.countDocuments({ role: "TruckOwner" });
    const driverCount = await Driver.countDocuments({ role: "Driver" });
    const customerCount = await User.countDocuments({ role: "Customer" });

    // Count all Orders
    const orderCount = await Order.countDocuments();

    res.status(200).json({
      message: "Counts retrieved successfully.",
      counts: {
        truckOwners: truckOwnerCount,
        drivers: driverCount,
        customers: customerCount,
        totalOrders: orderCount,
      },
    });
  } catch (err) {
    console.error("Error fetching counts:", err);
    next(err);
  }
};

export const history = async (req, res, next) => {
  try {
    const pendingVehicles = await Vehicle.find({ status: "Submitted" }).select(
      "-documents -createdAt -updatedAt"
    );

    const completedOrders = await Order.find({ status: "Completed" })
      .populate("customerId", "firstname lastname phoneNumber email")
      .populate("companies", "name")
      .select("-createdAt -updatedAt -__v")
      .sort({ createdAt: -1 });

    res.status(200).json({
      message: "Data retrieved successfully.",
      vehicles: pendingVehicles,
      orders: completedOrders,
    });
  } catch (err) {
    console.error("Error fetching vehicles and orders:", err);
    next(err);
  }
};

export const getDriverAssignedOrders = async (req, res, next) => {
  try {
    const orders = await Order.find({ status: "Assigned" })
      .populate("customerId", "firstname lastname phoneNumber email")
      .populate({
        path: "driverId",
        select: "firstname lastname phoneNumber email status truckOwnerId",
        populate: {
          path: "truckOwnerId",
          select: "firstname lastname email phoneNumber",
        },
      })
      .populate(
        "stations",
        "stationName region district latitude longitude address"
      )
      .sort({ createdAt: -1 });

    // For each order, generate orderId if not already set
    for (const order of orders) {
      if (!order.orderId) {
        const customerId = order.customerId._id.toString();
        const date = moment(order.createdAt).format("YYYYMMDD");
        const orderCount = await Order.countDocuments({
          customerId: order.customerId._id,
          createdAt: { $lte: order.createdAt },
        });
        order.orderId = `OD${date}${customerId.slice(-2)}${orderCount}`;
        await order.save();
      }
    }

    if (!orders.length) {
      return res.status(404).json({ message: "No assigned orders found." });
    }

    res.status(200).json({
      message: "Assigned orders with generated orderId retrieved successfully.",
      orders,
    });
  } catch (err) {
    console.error("Error retrieving assigned orders:", err);
    next(err);
  }
};

export const getAssignedOrderById = async (req, res, next) => {
  try {
    const { orderId } = req.params;

    // Retrieve the order with detailed population
    const order = await Order.findById(orderId)
      .populate("customerId", "firstname lastname phoneNumber email")
      .populate({
        path: "driverId",
        select: "firstname lastname phoneNumber email status truckOwnerId",
        populate: {
          path: "truckOwnerId",
          select: "firstname lastname email phoneNumber",
        },
      })
      .populate(
        "stations",
        "stationName region district latitude longitude address"
      )
      .populate("companies", "name")
      .sort({ createdAt: -1 })
      .lean();

    if (!order) {
      return res.status(404).json({ message: "Order not found." });
    }

    if (order.status !== "Assigned") {
      return res.status(400).json({ message: "Order is not assigned." });
    }
    if (!order.driverId || order.driverId.status !== "busy") {
      return res
        .status(400)
        .json({ message: "No busy driver is assigned to this order." });
    }

    // If orderId field is not set, generate one using the provided method
    if (!order.orderId) {
      const customerIdStr = order.customerId._id.toString();
      const date = moment(order.createdAt).format("YYYYMMDD");
      const orderCount = await Order.countDocuments({
        customerId: order.customerId._id,
        createdAt: { $lte: order.createdAt },
      });
      const generatedOrderId = `OD${date}${customerIdStr.slice(-2)}${
        orderCount + 1
      }`;

      await Order.findByIdAndUpdate(orderId, { orderId: generatedOrderId });
      order.orderId = generatedOrderId;
    }

    res.status(200).json({
      message: "Assigned order retrieved successfully.",
      order,
    });
  } catch (err) {
    console.error("Error retrieving assigned order:", err);
    next(err);
  }
};

export const getSharedOrderById = async (req, res, next) => {
  try {
    const { orderId } = req.params;

    //  Find the shared order by ID
    const order = await Order.findOne({ orderId })
      .populate("stations", "stationName region")
      .populate("companies.name")
      .populate("customerId", "firstname lastname phoneNumber");

    if (!order) {
      return res.status(404).json({ message: "Order not found." });
    }

    //  Fetch compartments if available
    const vehicle = await Vehicle.findById(order.vehicle).select(
      "compartmentCapacities numberOfCompartments"
    );

    const compartments = vehicle
      ? vehicle.compartmentCapacities.map((comp, index) => ({
          label: String.fromCharCode(65 + index),
          capacity: comp.capacity,
        }))
      : [];

    //  Prepare order details
    const orderDetails = {
      orderId: order.orderId,
      status: order.status,
      fuelType: order.fuelType,
      capacity: order.capacity,
      source: order.source,
      depot: order.depot,
      stations: order.stations,
      companies: order.companies,
      vehicle: order.vehicle,
      compartments,
    };

    return res
      .status(200)
      .json({ message: "Order found", order: orderDetails });
  } catch (err) {
    console.error("Error fetching shared order:", err);
    next(err);
  }
};

export const approveDriverLicense = async (req, res, next) => {
  try {
    const { driverId } = req.params;

    // Ensure only Admin or Staff can approve
    if (!["Admin", "Staff"].includes(req.user.role)) {
      return res.status(403).json({ message: "Unauthorized access" });
    }

    const driver = await Driver.findById(driverId);
    if (!driver) {
      return res.status(404).json({ message: "Driver not found" });
    }

    if (driver.status !== "unverified") {
      return res.status(400).json({ message: "Driver is already verified." });
    }

    driver.status = "available";
    driver.lastUpdatedAt = new Date();
    await driver.save();

    if (driver.phoneNumber) {
      const message = `Dear ${driver.firstname}, your driver license has been verified and your status is now AVAILABLE. Thank you for your patience!`;
      try {
        await sendSMS(driver.phoneNumber, message);
      } catch (smsError) {
        console.warn(" SMS failed:", smsError.message);
      }
    }

    res.status(200).json({
      message: "Driver license approved successfully.",
    });
  } catch (err) {
    console.error("Error approving driver license:", err);
    next(err);
  }
};

export const getAllDriversSorted = async (req, res, next) => {
  try {
    const drivers = await Driver.find().select("-__v -assignedOrder").sort({
      status: 1, // "unverified" will come before "available", "busy", "completed"
      createdAt: -1,
    });

    if (!drivers.length) {
      return res.status(404).json({ message: "No drivers found." });
    }

    res.status(200).json({
      message: "Drivers retrieved successfully.",
      total: drivers.length,
      drivers,
    });
  } catch (err) {
    console.error("Error retrieving drivers:", err);
    next(err);
  }
};

export const getDriverById = async (req, res, next) => {
  try {
    const { driverId } = req.params;

    const driver = await Driver.findById(driverId).select(
      "-__v -assignedOrder"
    );

    if (!driver) {
      return res.status(404).json({
        message: "Driver not found.",
      });
    }

    res.status(200).json({
      message: "Driver retrieved successfully.",
      driver,
    });
  } catch (err) {
    console.error("Error fetching driver:", err);
    next(err);
  }
};

export const downloadDriverLicense = async (req, res, next) => {
  try {
    const { driverId } = req.params;

    const driver = await Driver.findById(driverId);
    if (!driver) {
      return res.status(404).json({ message: "Driver not found" });
    }

    if (!driver.licenseImage) {
      return res
        .status(404)
        .json({ message: "No license image found for this driver" });
    }

    // Use only the filename, strip any path if it exists
    const fileName = path.basename(driver.licenseImage);
    const licensePath = path.join(__dirname, "../../public/licenses", fileName);

    if (!fs.existsSync(licensePath)) {
      return res
        .status(404)
        .json({ message: "License file does not exist on the server" });
    }

    res.download(licensePath, fileName, (err) => {
      if (err) {
        return res
          .status(500)
          .json({ message: "Failed to download license image" });
      }
    });
  } catch (err) {
    next(err);
  }
};

export const getAllStations = async (req, res, next) => {
  try {
    const stations = await Station.find()
      .populate("customerId", "firstname lastname phoneNumber email") // Optional: show customer info
      .sort({ createdAt: -1 });

    res.status(200).json({
      message: "All stations retrieved successfully.",
      count: stations.length,
      stations,
    });
  } catch (err) {
    console.error("Error fetching stations:", err);
    next(err);
  }
};


export const getAllTruckOwners = async (req, res, next) => {
  try {
    const truckOwners = await User.find({ role: "TruckOwner" }).select(
      "-password -otp -otpExpiresAt -__v"
    );

    res.status(200).json({
      message: "Truck owners retrieved successfully.",
      count: truckOwners.length,
      truckOwners,
    });
  } catch (err) {
    console.error("Error fetching truck owners:", err);
    next(err);
  }
};

export const deleteStation = async (req, res, next) => {
  try {
    const stationId = req.params.id;

    const deleted = await Station.findByIdAndDelete(stationId);

    if (!deleted) {
      return res.status(404).json({ message: "Station not found." });
    }

    res.status(200).json({ message: "Station deleted successfully." });
  } catch (err) {
    console.error("Error deleting station:", err);
    next(err);
  }
};