import Station from "../../models/customer/Station.js";
import Order from "../../models/orders/Order.js";
import User from "../../models/User.js";
import Vehicle from "../../models/vehicles/Vehicle.js";
import Driver from "../../models/drivers/Driver.js";
import mongoose from "mongoose";

import Depot from "../../models/deport/Depot.js";
import { sendSMS } from "../../utils/otp.js";
import Suggestion from "../../models/suggestion/Suggestion.js";
import { formatNumber } from "../../utils/formatNumber.js";
import { generateOrderId } from "../../utils/orderId.js";
import GpsData from "../../models/gps/GpsData.js";
import { haversineDistance } from "../../utils/haversine.js";

//Register Station
export const registerStation = async (req, res, next) => {
  const { stationName, label, region, district, latitude, longitude } =
    req.body;

  try {
    const station = new Station({
      customerId: req.user.id,
      stationName,
      label,
      region,
      district,
      latitude,
      longitude,
    });

    const savedStation = await station.save();

    res.status(201).json({
      message: "Station registered successfully.",
      station: savedStation,
    });
  } catch (err) {
    next(err);
  }
};

//Customer Place Order
export const placeOrder = async (req, res) => {
  const {
    fuelType,
    routeWay,
    capacity,
    deliveryTime,
    source,
    stationName,
    depot,
    companyName,
    price,
  } = req.body;

  try {
    if (routeWay === "private" && !deliveryTime) {
      return res
        .status(400)
        .json({ message: "Delivery time is required for private route." });
    }

    const customerId = req.user.id;

    const station = await Station.findOne({
      stationName: { $regex: `^${stationName}$`, $options: "i" },
      customerId,
    });

    if (!station || !station.latitude || !station.longitude) {
      return res
        .status(400)
        .json({ message: "Valid station with coordinates is required." });
    }

    const selectedDepot = await Depot.findOne({ depot });
    if (!selectedDepot || !selectedDepot.sources) {
      return res
        .status(404)
        .json({ message: `Depot ${depot} not found or has no sources.` });
    }

    const sourceDetails = selectedDepot.sources.find(
      (item) => item.name.toLowerCase() === source.toLowerCase()
    );
    if (!sourceDetails) {
      return res
        .status(400)
        .json({ message: `Invalid source for depot ${depot}.` });
    }

    const selectedCompany = sourceDetails.companies.find(
      (company) => company.name.toLowerCase() === companyName.toLowerCase()
    );
    if (!selectedCompany) {
      return res.status(400).json({
        message: `Company ${companyName} not available at ${source}.`,
      });
    }

    //  Get all approved vehicles with same fuel type
    const approvedVehicles = await Vehicle.find({
      status: "Approved",
      // fuelType,
    }).populate("truckOwner");

    //  Get latest GPS data for these vehicles
    const imeis = approvedVehicles.map((v) => v.gpsImei).filter(Boolean);
    const latestGpsData = await GpsData.aggregate([
      { $match: { imei: { $in: imeis }, status: "INSTALLED" } },
      { $sort: { timestamp: -1 } },
      {
        $group: {
          _id: "$imei",
          imei: { $first: "$imei" },
          latitude: { $first: "$latitude" },
          longitude: { $first: "$longitude" },
        },
      },
    ]);

    //  Filter vehicles within 20KM of depot
    const nearVehicles = latestGpsData
      .map((gps) => {
        const dist = haversineDistance(
          selectedCompany.latitude,
          selectedCompany.longitude,
          gps.latitude,
          gps.longitude
        );
        return { ...gps, distance: dist };
      })
      .filter((v) => v.distance <= 20);

    //  Send SMS to nearby vehicle owners
    for (const v of nearVehicles) {
      const vehicle = approvedVehicles.find((veh) => veh.gpsImei === v.imei);
      if (vehicle?.truckOwner?.phoneNumber) {
        const msg = `Nearby Order Alert!\nFuel: ${fuelType}\nDepot: ${depot}\nCompany: ${companyName}\nVehicle: ${vehicle.vehicleIdentity}`;
        try {
          await sendSMS(vehicle.truckOwner.phoneNumber, msg);
        } catch (err) {
          console.error(
            `Failed to send SMS to ${vehicle.truckOwner.phoneNumber}: ${err.message}`
          );
        }
      }
    }

    //  Find matching vehicle (unchanged logic)
    const matchingVehicle = approvedVehicles.find((vehicle) => {
      const usageRatio = capacity / vehicle.tankCapacity;
      return usageRatio >= 0.95 && usageRatio <= 1;
    });

    if (!matchingVehicle) {
      const nearbyVehicle = approvedVehicles
        .map((v) => ({
          vehicle: v,
          diff: Math.abs(v.tankCapacity * 0.95 - capacity),
        }))
        .sort((a, b) => a.diff - b.diff)[0];

      if (nearbyVehicle) {
        const suggestedCapacity = Math.round(
          nearbyVehicle.vehicle.tankCapacity * 0.95
        );
        const user = await User.findById(customerId).select(
          "firstname lastname phoneNumber"
        );

        const hintMessage = `Dear ${user.firstname} ${
          user.lastname
        },\n\nNo exact vehicle match was found for your ${formatNumber(
          capacity
        )} Liters ${fuelType} order.\n\nTo proceed faster, consider adjusting your capacity to around ${formatNumber(
          suggestedCapacity
        )} Liters to match a nearby truck with a tank capacity of ${formatNumber(
          nearbyVehicle.vehicle.tankCapacity
        )} Liters.`;

        return res.status(400).json({
          message: "No matching vehicle found.",
          suggestion: hintMessage,
        });
      }

      return res.status(400).json({
        message:
          "No matching or nearby vehicle found. Please adjust your capacity.",
      });
    }

    //  Create Order
    const orderId = await generateOrderId(customerId);
    const newOrder = new Order({
      orderId,
      customerId,
      fuelType,
      routeWay,
      capacity,
      deliveryTime: routeWay === "private" ? deliveryTime : null,
      source,
      latitude: sourceDetails.latitude,
      longitude: sourceDetails.longitude,
      stations: [station._id],
      depot,
      price,
      companies: [selectedCompany],
      vehicleId: matchingVehicle._id,
    });

    const savedOrder = await newOrder.save();

    await new Suggestion({
      orderId: savedOrder._id,
      vehicleId: matchingVehicle._id,
      status: "Suggested",
    }).save();

    //  Notify matched truck owner
    const truckOwner = matchingVehicle.truckOwner;
    if (truckOwner?.phoneNumber) {
      const msg = `New order match!\nOrder: ${orderId}\nFuel: ${fuelType}\nCapacity: ${formatNumber(
        capacity
      )} Liters\nVehicle: ${
        matchingVehicle.vehicleIdentity
      }\nTank: ${formatNumber(matchingVehicle.tankCapacity)} Liters`;
      try {
        await sendSMS(truckOwner.phoneNumber, msg);
      } catch (err) {
        console.error(`SMS failed: ${err.message}`);
      }
    }

    //  5 min fallback
    if (routeWay === "private") {
      setTimeout(async () => {
        const updatedOrder = await Order.findById(savedOrder._id);
        if (updatedOrder?.status === "Pending") {
          const staff = await User.findOne({ role: "Staff" });
          const tankOwner = await User.findOne({ role: "TankOwner" });

          if (staff) {
            await new Message({
              staffId: staff._id,
              message: `Order ${orderId} still pending after 5 minutes.`,
              status: "unread",
            }).save();
          }

          if (tankOwner) {
            await new Message({
              truckId: tankOwner._id,
              message: `Order ${orderId} is still unassigned.`,
              status: "unread",
            }).save();
          }
        }
      }, 5 * 60 * 1000);
    }

    return res.status(201).json({
      message: "Order placed successfully.",
      orderId: savedOrder.orderId,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({
      message: "An error occurred while placing the order.",
    });
  }
};

//Retrieve the petrol station owner details
export const getCustomerOrders = async (req, res, next) => {
  try {
    const orders = await Order.find({ customerId: req.user.id })
      .populate({
        path: "stations",
      })
      .sort({ createdAt: -1 });

    if (!orders.length) {
      return res.status(404).json({ message: "No orders found." });
    }

    res.status(200).json({
      message: "Orders retrieved successfully.",
      orders,
    });
  } catch (err) {
    console.error("Error fetching customer orders:", err);
    next(err);
  }
};

//View Order for a customer
export const getCustomerOrdersByTruckOwner = async (req, res, next) => {
  const { customerId } = req.params;

  try {
    // Verify the customer exists
    const customer = await User.findById(customerId);
    if (!customer) {
      return res.status(404).json({ message: "Customer not found." });
    }

    // Fetch orders for the given customer
    const orders = await Order.find({ customerId })
      .populate({
        path: "stations",
        select: "stationName region district -_id",
      })
      .sort({ createdAt: -1 });

    if (!orders.length) {
      return res
        .status(404)
        .json({ message: "No orders found for this customer." });
    }

    res.status(200).json({
      message: `Orders for customer: ${customer.firstname} ${customer.lastname}`,
      orders,
    });
  } catch (err) {
    next(err);
  }
};

//Truck owner view all order requested
export const getRequestedOrder = async (req, res, next) => {
  try {
    const truckOwnerId = req.user.id;

    const vehicles = await Vehicle.find({
      truckOwner: truckOwnerId,
      status: "Approved",
    }).select("tankCapacity vehicleIdentity _id");

    if (!vehicles.length) {
      return res.status(404).json({
        message: "No approved vehicles found.",
        privateOrders: [],
        sharedOrders: [],
      });
    }

    const vehicleIds = vehicles.map((v) => v._id);
    const privateOrders = [];
    const sharedGroups = new Map();

    const suggestions = await Suggestion.find({
      vehicleId: { $in: vehicleIds },
      status: "Suggested",
    }).populate({
      path: "orderId",
      populate: [
        {
          path: "customerId",
          select: "firstname lastname phoneNumber region district",
        },
        { path: "stations" },
        { path: "companies" },
      ],
    });

    // Process shared orders with status Pending or Requested
    for (const suggestion of suggestions) {
      const order = suggestion.orderId;
      if (
        !order ||
        order.routeWay !== "shared" ||
        !order.merged ||
        !order.sharedGroupId ||
        !["Pending", "Requested"].includes(order.status)
      )
        continue;

      const groupId = order.sharedGroupId;

      if (!sharedGroups.has(groupId)) {
        sharedGroups.set(groupId, {
          sharedGroupId: groupId,
          source: order.source,
          depot: order.depot,
          routeWay: "shared",
          capacity: 0,
          price: 0,
          status: order.status,
          orderId: order.orderId,
          customers: [],
          companyNames: [],
        });
      }

      const group = sharedGroups.get(groupId);
      group.capacity += order.capacity;
      group.price += order.price;

      const customerIdStr = order.customerId._id.toString();
      const existing = group.customers.find(
        (c) => c._id.toString() === customerIdStr
      );

      if (!existing) {
        group.customers.push({
          ...order.customerId.toObject(),
          capacity: order.capacity,
          price: order.price,
          stationDetails: order.stations || [],
        });
      }

      if (Array.isArray(order.companies)) {
        const names = order.companies.map((c) => c.name).filter(Boolean);
        group.companyNames.push(...names);
      }

      sharedGroups.set(groupId, group);
    }

    // Convert shared groups to array and calculate total capacity and price
    const sharedOrders = Array.from(sharedGroups.values()).map((group) => {
      const matchingVehicles = vehicles.filter(
        (v) =>
          v.tankCapacity >= group.capacity &&
          group.capacity >= v.tankCapacity * 0.5
      );

      const totalCapacity = group.customers.reduce(
        (sum, customer) => sum + customer.capacity,
        0
      );
      const totalPrice = group.customers.reduce(
        (sum, customer) => sum + (customer.price || 0),
        0
      );

      return {
        sharedGroupId: group.sharedGroupId,
        source: group.source,
        depot: group.depot,
        routeWay: "shared",
        capacity: totalCapacity,
        price: totalPrice,
        status: group.status,
        orderId: group.orderId,
        customers: group.customers,
        companyNames: [...new Set(group.companyNames)],
        matchingVehicles,
      };
    });

    // Fetch and filter private orders
    const pendingPrivateOrders = await Order.aggregate([
      {
        $match: {
          routeWay: "private",
          status: { $in: ["Pending", "Requested"] },
        },
      },
      {
        $lookup: {
          from: "users",
          localField: "customerId",
          foreignField: "_id",
          as: "customer",
        },
      },
      { $unwind: "$customer" },
      {
        $lookup: {
          from: "stations",
          localField: "stations",
          foreignField: "_id",
          as: "stationDetails",
        },
      },
    ]);

    for (const order of pendingPrivateOrders) {
      const matchingVehicles = vehicles.filter(
        (v) =>
          v.tankCapacity >= order.capacity &&
          order.capacity >= v.tankCapacity * 0.5
      );

      if (matchingVehicles.length) {
        const companyNames = (order.companies || [])
          .map((c) => c.name)
          .filter(Boolean);

        privateOrders.push({
          _id: order._id,
          orderId: order.orderId,
          source: order.source,
          depot: order.depot,
          capacity: order.capacity,
          price: order.price,
          routeWay: order.routeWay,
          status: order.status,
          customers: [order.customer],
          stationDetails: order.stationDetails,
          companyNames,
          matchingVehicles,
        });
      }
    }

    return res.status(200).json({
      message: "Filtered matching orders retrieved successfully.",
      privateOrders,
      sharedOrders,
    });
  } catch (err) {
    console.error("Error retrieving requested orders:", err);
    next(err);
  }
};

// Accept Order and Notify Customer
export const acceptOrder = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const truckOwnerId = req.user.id;

    let order;

    const isObjectId = mongoose.Types.ObjectId.isValid(orderId);

    if (isObjectId) {
      order = await Order.findById(orderId)
        .populate("customerId", "firstname lastname phoneNumber")
        .populate({
          path: "vehicleId",
          select:
            "vehicleIdentity truckOwner tankCapacity compartmentCapacities",
        });

      if (!order) return res.status(404).json({ message: "Order not found." });

      if (!order.vehicleId || !order.vehicleId.truckOwner) {
        return res
          .status(400)
          .json({ message: "Order has no vehicle assigned." });
      }

      const vehicleTruckOwnerId = String(order.vehicleId.truckOwner);
      if (vehicleTruckOwnerId !== String(truckOwnerId)) {
        return res
          .status(403)
          .json({ message: "You are not authorized to accept this order." });
      }

      if (
        order.routeWay === "shared" &&
        order.merged === true &&
        order.sharedGroupId
      ) {
        // Redirect to shared group logic
        return acceptSharedGroup(order.sharedGroupId, order.vehicleId, res);
      }

      //  PRIVATE ORDER
      if (order.status === "Accepted") {
        return res.status(400).json({ message: "Order is already Accepted." });
      }

      order.status = "Accepted";
      await order.save();

      const customer = order.customerId;
      const message = `Dear ${customer.firstname}, your order (ID: ${order.orderId}) has been Accepted. Thank you for your patience.`;

      try {
        await sendSMS(customer.phoneNumber, message);
      } catch (err) {
        console.error("Failed to send SMS to private customer:", err.message);
      }

      return res.status(200).json({
        message: "Private order accepted and customer notified.",
        orderId: order._id,
      });
    }

    //  Shared Order using sharedGroupId directly
    return acceptSharedGroup(orderId, null, res);
  } catch (err) {
    console.error("Error in acceptOrder:", err);
    next(err);
  }
};

//  Shared group handler function
const acceptSharedGroup = async (sharedGroupId, fallbackVehicle, res) => {
  const matchedOrders = await Order.find({
    sharedGroupId,
    routeWay: "shared",
    merged: true,
    status: { $ne: "Accepted" },
  })
    .populate("customerId", "firstname lastname phoneNumber")
    .populate("vehicleId")
    .lean();

  if (!matchedOrders.length) {
    return res
      .status(400)
      .json({ message: "No pending shared orders found for this group." });
  }

  const vehicle = fallbackVehicle || matchedOrders[0]?.vehicleId;

  if (!vehicle || !vehicle.compartmentCapacities || !vehicle.truckOwner) {
    return res
      .status(400)
      .json({ message: "Assigned vehicle missing or incomplete." });
  }

  // Accept all orders
  await Order.updateMany(
    { _id: { $in: matchedOrders.map((o) => o._id) } },
    { $set: { status: "Accepted", vehicleId: vehicle._id } }
  );

  const compartments = vehicle.compartmentCapacities;
  const totalCapacity = matchedOrders.reduce((acc, o) => acc + o.capacity, 0);

  const customers = matchedOrders.map((o) => ({
    id: o.customerId._id.toString(),
    capacity: o.capacity,
    name: `${o.customerId.firstname} ${o.customerId.lastname}`,
    phone: o.customerId.phoneNumber,
  }));

  customers.sort((a, b) => b.capacity - a.capacity);

  const assignments = {};
  let remaining = totalCapacity;
  let customerIndex = 0;

  for (let i = 0; i < compartments.length && remaining > 0; i++) {
    const comp = compartments[i];
    const label = comp.id || String.fromCharCode(65 + i);
    const cap = comp.capacity;

    const customer = customers[customerIndex];
    if (!customer || customer.capacity <= 0) continue;

    const alloc = Math.min(customer.capacity, cap);
    if (!assignments[customer.id]) assignments[customer.id] = [];
    assignments[customer.id].push({ label, capacity: alloc });

    customer.capacity -= alloc;
    remaining -= alloc;

    if (customer.capacity <= 0) customerIndex++;
  }

  await Promise.all(
    customers.map((c) => {
      const comps = assignments[c.id] || [];
      const msg = `Dear ${
        c.name
      },\n\nYour shared fuel order has been accepted.\nAssigned Compartments:\n${comps
        .map((comp) => `- ${comp.label}: ${comp.capacity}L`)
        .join("\n")}\n\nThank you for choosing our service.`;
      return sendSMS(c.phone, msg);
    })
  );

  return res.status(200).json({
    message: "Shared order group accepted and customers notified.",
    orderIds: matchedOrders.map((o) => o._id),
  });
};

export const searchOrderById = async (req, res, next) => {
  const { orderId } = req.params;

  try {
    // Fetch the order with customer and station details
    const order = await Order.findById(orderId)
      .populate("customerId", "firstname lastname phoneNumber")
      .populate("stations", "stationName region district");

    if (!order) {
      return res.status(404).json({ message: "Order not found." });
    }

    res.status(200).json({
      message: "Order retrieved successfully.",
      order,
    });
  } catch (err) {
    next(err);
  }
};

//Get Order information by generated order id
export const getOrderByOrderId = async (req, res, next) => {
  const { orderId } = req.params;

  try {
    // Find the order by the provided orderId
    const order = await Order.findOne({ orderId })
      .populate("stations", "stationName region district latitude longitude")
      .populate("customerId", "firstname lastname phoneNumber email")
      .populate("companies", "name contact")
      .select("-__v -updatedAt -createdAt -orderId");

    if (!order) {
      return res.status(404).json({ message: "Order not found." });
    }

    res.status(200).json({
      message: "Order retrieved successfully.",
      order,
    });
  } catch (err) {
    console.error("Error fetching order by orderId:", err);
    next(err);
  }
};

export const assignAvailableDriverToOrder = async (req, res, next) => {
  const { orderId, driverId } = req.params;

  try {
    const isObjectId = mongoose.Types.ObjectId.isValid(orderId);
    const driver = await Driver.findById(driverId);

    if (!driver) {
      return res.status(404).json({ message: "Driver not found." });
    }

    if (driver.status !== "available") {
      return res
        .status(400)
        .json({ message: "Driver is not available for assignment." });
    }

    //  PRIVATE ORDER
    if (isObjectId) {
      const order = await Order.findById(orderId)
        .populate("customerId", "firstname lastname phoneNumber email orderId")
        .populate("stations", "stationName region district latitude longitude");

      if (!order) {
        return res.status(404).json({ message: "Order not found." });
      }

      if (order.status !== "Accepted") {
        return res
          .status(400)
          .json({ message: "Order is not in accepted status." });
      }

      const suggestion = await Suggestion.findOne({
        orderId,
        status: "Suggested",
      }).populate("vehicleId");

      if (!suggestion || !suggestion.vehicleId) {
        return res
          .status(404)
          .json({ message: "No suggested vehicle found for this order." });
      }

      const vehicle = suggestion.vehicleId;

      if (vehicle.status === "Busy") {
        return res
          .status(400)
          .json({ message: "Suggested vehicle is already in use." });
      }

      order.driverId = driver._id;
      order.vehicleId = vehicle._id;
      order.status = "Assigned";
      await order.save();

      driver.status = "busy";
      driver.assignedOrder = order._id;
      await driver.save();

      vehicle.status = "Busy";
      await vehicle.save();

      suggestion.status = "Used";
      await suggestion.save();

      // Notify driver
      const station = order.stations?.[0];
      const stationText = station
        ? `From: ${order.depot} to ${station.stationName} (${station.region})`
        : `Depot: ${order.depot}`;
      const company = order.companies?.[0]?.name || "N/A";

      const driverMsg = `Dear ${driver.firstname} ${driver.lastname},
      
      You have been assigned to order ${order.orderId}.
      ${stationText}
      Destination: ${company}`;

      await sendSMS(driver.phoneNumber, driverMsg);

      // Notify customer
      const customer = order.customerId;
      const customerMsg = `Dear ${customer.firstname} ${customer.lastname},\n\nYour order ${order.orderId} has been assigned to a driver: ${driver.firstname} ${driver.lastname}, ${driver.phoneNumber}.`;
      await sendSMS(customer.phoneNumber, customerMsg);

      return res.status(200).json({
        message: "Driver and vehicle assigned successfully to private order.",
        order,
        driver,
        vehicle,
      });
    }

    // SHARED GROUP ORDER
    const sharedOrders = await Order.find({
      sharedGroupId: orderId,
      routeWay: "shared",
      merged: true,
      status: "Accepted",
    })
      .populate("customerId", "firstname lastname phoneNumber email orderId")
      .populate("vehicleId")
      .populate("stations", "stationName region district latitude longitude");

    if (!sharedOrders.length) {
      return res
        .status(404)
        .json({ message: "No accepted shared orders found for this group." });
    }

    const suggestion = await Suggestion.findOne({
      orderId: sharedOrders[0]._id,
      status: "Suggested",
    }).populate("vehicleId");

    if (!suggestion || !suggestion.vehicleId) {
      return res
        .status(404)
        .json({ message: "No suggested vehicle found for this shared group." });
    }

    const vehicle = suggestion.vehicleId;

    if (vehicle.status === "Busy") {
      return res
        .status(400)
        .json({ message: "Suggested vehicle is already in use." });
    }

    const updatedOrders = [];

    for (const order of sharedOrders) {
      order.driverId = driver._id;
      order.vehicleId = vehicle._id;
      order.status = "Assigned";
      await order.save();
      updatedOrders.push(order);

      // Notify customer
      const customer = order.customerId;
      const station = order.stations?.[0];
      const company = order.companies?.[0]?.name || "N/A";

      const stationText = station
        ? `Depot: ${order.depot}\nStation: ${station.stationName}\nRegion: ${station.region}`
        : `Depot: ${order.depot}`;

      const customerMsg =
        `Dear ${customer.firstname} ${customer.lastname},\n\n` +
        `Your order ${order.orderId} has been assigned a driver:\n` +
        `${driver.firstname} ${driver.lastname}, ${driver.phoneNumber}.\n\n` +
        `${stationText}\nDestination: ${company}`;

      await sendSMS(customer.phoneNumber, customerMsg);
    }

    // Update driver and vehicle
    driver.status = "busy";
    driver.assignedOrder = sharedOrders[0]._id;
    await driver.save();

    vehicle.status = "Busy";
    await vehicle.save();

    suggestion.status = "Used";
    await suggestion.save();

    // Notify driver with all customer info
    const customerInfoText = updatedOrders
      .map((o, index) => {
        const customer = o.customerId;
        const station = o.stations?.[0];
        const company = o.companies?.[0]?.name || "N/A";
        const stationText = station
          ? `From: ${o.depot} → ${station.stationName} (${station.region})`
          : `Depot: ${o.depot} ${company}`;
        return `${index + 1}. ${customer.firstname} ${customer.lastname} (${
          customer.phoneNumber
        })\n   ${stationText}\n `;
      })
      .join("\n");

    const driverMessage = `Dear ${driver.firstname} ${driver.lastname},\n\nYou have been assigned to a shared group order.\n\nCustomers:\n${customerInfoText}\n\nPlease check your dashboard for full delivery details.`;

    await sendSMS(driver.phoneNumber, driverMessage);

    return res.status(200).json({
      message: "Driver and vehicle assigned successfully to shared group.",
      sharedGroupId: orderId,
      driver,
      vehicle,
      orders: updatedOrders,
    });
  } catch (err) {
    console.error("Error assigning driver:", err);
    next(err);
  }
};

export const getTruckOwnerOrders = async (req, res, next) => {
  try {
    const truckOwnerId = mongoose.Types.ObjectId.isValid(req.user.id)
      ? new mongoose.Types.ObjectId(req.user.id)
      : req.user.id;

    const vehicles = await Vehicle.find({ truckOwner: truckOwnerId }).select(
      "_id"
    );

    if (!vehicles.length) {
      return res.status(404).json({
        message: "No vehicles registered for this truck owner.",
        privateOrders: [],
        sharedOrders: [],
      });
    }

    const vehicleIds = vehicles.map((v) => v._id);

    //  Fetch all relevant statuses
    const orders = await Order.find({
      vehicleId: { $in: vehicleIds },
      status: {
        $in: ["Accepted", "onDelivery", "Assigned", "Completed", "Canceled"],
      },
    })
      .populate("vehicleId", "vehicleIdentity tankCapacity status")
      .populate("customerId", "firstname lastname phoneNumber email")
      .populate("driverId", "firstname lastname phoneNumber email status")
      .populate("stations")
      .populate("")
      .sort({ createdAt: -1 })
      .select("-__v -updatedAt -createdAt");

    if (!orders.length) {
      return res.status(404).json({
        message: "No relevant orders found for this truck owner.",
        privateOrders: [],
        sharedOrders: [],
      });
    }

    const privateOrders = orders.filter((o) => o.routeWay === "private");
    const sharedOrders = orders.filter(
      (o) => o.routeWay === "shared" && o.merged === true
    );

    return res.status(200).json({
      message: "Orders retrieved successfully.",
      privateOrders,
      sharedOrders,
    });
  } catch (err) {
    console.error("Error fetching truck owner orders:", err);
    next(err);
  }
};
 