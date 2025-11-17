import Station from "../../models/customer/Station.js";
import Depot from "../../models/deport/Depot.js";
import Order from "../../models/orders/Order.js";
import mongoose from "mongoose";
import Message from "../../models/message/Message.js";
import { sendMessageToTruckOwner } from "../../utils/websocket.js";
import User from "../../models/User.js";
import Vehicle from "../../models/vehicles/Vehicle.js";
import Shared from "../../models/orders/Shared.js";
import { sendSMS } from "../../utils/otp.js";
import Suggestion from "../../models/suggestion/Suggestion.js";
import crypto from "crypto";
import { generateOrderId } from "../../utils/orderId.js";
import GpsData from "../../models/gps/GpsData.js";
import { haversineDistance } from "../../utils/haversine.js";

export const placeSharedOrder = async (req, res, next) => {
  try {
    const {
      fuelType,
      capacity,
      source,
      stationName,
      depot,
      district,
      companyName,
      price,
      distance,
    } = req.body;

    const customerId = req.user.id;

    if (
      !fuelType ||
      !capacity ||
      !source ||
      !stationName ||
      !depot ||
      !companyName ||
      !price ||
      !district ||
      !distance
    ) {
      return res.status(400).json({ message: "Missing required fields." });
    }

    const station = await Station.findOne({ stationName, district });
    if (!station) {
      return res
        .status(404)
        .json({ message: "Station not found in this district." });
    }

    const orderId = await generateOrderId(customerId);
    const newOrder = new Order({
      orderId,
      customerId,
      fuelType,
      routeWay: "shared",
      capacity,
      source,
      stations: [station._id],
      depot,
      price,
      distance,
      companies: [{ name: companyName }],
      status: "Pending",
      merged: false,
      createdAt: new Date(),
    });

    await newOrder.save();

    //  Fetch depot coordinates
    const selectedDepot = await Depot.findOne({ depot });
    if (!selectedDepot || !selectedDepot.sources) {
      return res.status(404).json({ message: `Depot ${depot} not found.` });
    }

    const sourceDetails = selectedDepot.sources.find(
      (s) => s.name.toLowerCase() === source.toLowerCase()
    );
    if (!sourceDetails) {
      return res
        .status(400)
        .json({ message: `Invalid source ${source} for depot.` });
    }
    // Find the company in the selected source
    const selectedCompany = sourceDetails.companies.find(
      (c) => c.name.toLowerCase() === companyName.toLowerCase()
    );
    if (!selectedCompany) {
      return res
        .status(400)
        .json({ message: `Company ${companyName} not found.` });
    }

    newOrder.companies[0].latitude = selectedCompany.latitude;
    newOrder.companies[0].longitude = selectedCompany.longitude;

    await newOrder.save();

    const approvedVehicles = await Vehicle.find({
      status: "Approved",
      // fuelType,
    }).populate("truckOwner");

    //  Get latest GPS data
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

    for (const v of nearVehicles) {
      const vehicle = approvedVehicles.find((veh) => veh.gpsImei === v.imei);
      if (vehicle?.truckOwner?.phoneNumber) {
        const msg = `Nearby Shared Order!\nDepot: ${depot}\nCompany: ${companyName}\nVehicle: ${vehicle.vehicleIdentity}`;
        try {
          await sendSMS(vehicle.truckOwner.phoneNumber, msg);
        } catch (err) {
          console.error(`Failed to send GPS alert: ${err.message}`);
        }
      }
    }

    //  Try to match shared orders
    const stationIds = (await Station.find({ district }).select("_id")).map(
      (s) => s._id
    );
    const matchingOrder = await Order.findOne({
      routeWay: "shared",
      fuelType,
      source,
      stations: { $in: stationIds },
      depot,
      "companies.name": companyName,
      status: "Pending",
      merged: false,
      customerId: { $ne: customerId },
    });

    if (matchingOrder) {
      const totalCapacity = newOrder.capacity + matchingOrder.capacity;
      const suitableVehicles = await Vehicle.find({
        status: "Approved",
        // fuelType,
      }).sort({ tankCapacity: 1 });

      let matchingVehicles = [];
      let bestFitVehicle = null;
      let bestFitUtilization = 0;

      for (const vehicle of suitableVehicles) {
        const totalCompartmentsCapacity = vehicle.compartmentCapacities.reduce(
          (sum, c) => sum + c.capacity,
          0
        );
        const utilization = totalCapacity / totalCompartmentsCapacity;

        if (utilization <= 1) {
          matchingVehicles.push(vehicle);
        } else if (utilization <= 1.05 && utilization > bestFitUtilization) {
          bestFitVehicle = vehicle;
          bestFitUtilization = utilization;
        }
      }

      if (matchingVehicles.length === 0 && bestFitVehicle) {
        matchingVehicles.push(bestFitVehicle);
      }

      if (matchingVehicles.length === 0) {
        const customers = await User.find({
          _id: { $in: [newOrder.customerId, matchingOrder.customerId] },
        });

        await Promise.all(
          customers.map((customer) =>
            sendSMS(
              customer.phoneNumber,
              `Dear ${customer.firstname}, we found a match but need to wait for a vehicle to carry ${totalCapacity}L.`
            )
          )
        );

        return res.status(200).json({
          message: "Waiting for suitable vehicle.",
          waitingForVehicle: true,
          totalCapacityRequired: totalCapacity,
          orders: [newOrder.orderId, matchingOrder.orderId],
        });
      }

      const selectedVehicle = matchingVehicles[0];
      const sharedGroupId = `matchedId${Date.now().toString(36)}${crypto
        .randomBytes(3)
        .toString("hex")}`;

      const customers = [
        {
          id: newOrder.customerId,
          capacity: newOrder.capacity,
          price,
          distance: newOrder.distance,
        },
        {
          id: matchingOrder.customerId,
          capacity: matchingOrder.capacity,
          price: matchingOrder.price,
          distance: matchingOrder.distance,
        },
      ].sort((a, b) => b.distance - a.distance);

      const compartments = [];
      let remainingCapacities = [...customers];

      for (let i = 0; i < selectedVehicle.numberOfCompartments; i++) {
        const compCap = selectedVehicle.compartmentCapacities[i]?.capacity || 0;
        const customerIndex = remainingCapacities.findIndex(
          (c) => c.capacity > 0 && c.capacity <= compCap
        );

        if (customerIndex >= 0) {
          const customer = remainingCapacities[customerIndex];
          compartments.push({
            label: String.fromCharCode(65 + i),
            customer: customer.id,
            capacity: customer.capacity,
            price: customer.price,
          });
          remainingCapacities.splice(customerIndex, 1);
        }
      }

      if (remainingCapacities.length > 0) {
        for (
          let i = 0;
          i < selectedVehicle.numberOfCompartments &&
          remainingCapacities.length > 0;
          i++
        ) {
          const compCap =
            selectedVehicle.compartmentCapacities[i]?.capacity || 0;
          const compartment = compartments.find(
            (c) => c.label === String.fromCharCode(65 + i)
          );

          if (!compartment) {
            const customer = remainingCapacities[0];
            const allocate = Math.min(customer.capacity, compCap);
            compartments.push({
              label: String.fromCharCode(65 + i),
              customer: customer.id,
              capacity: allocate,
              price: customer.price,
            });
            customer.capacity -= allocate;
            if (customer.capacity <= 0) remainingCapacities.shift();
          }
        }
      }

      if (remainingCapacities.some((c) => c.capacity > 0)) {
        return res.status(200).json({
          message: "Could not fully allocate. Waiting for better match.",
          waitingForVehicle: true,
        });
      }

      matchingOrder.status = "Requested";
      matchingOrder.merged = true;
      matchingOrder.sharedGroupId = sharedGroupId;
      matchingOrder.vehicleId = selectedVehicle._id;
      await matchingOrder.save();

      newOrder.status = "Requested";
      newOrder.merged = true;
      newOrder.sharedGroupId = sharedGroupId;
      newOrder.vehicleId = selectedVehicle._id;
      await newOrder.save();

      await Suggestion.insertMany(
        matchingVehicles.flatMap((v) => [
          { orderId: newOrder._id, vehicleId: v._id, status: "Suggested" },
          { orderId: matchingOrder._id, vehicleId: v._id, status: "Suggested" },
        ])
      );

      const customersInfo = await User.find({
        _id: { $in: customers.map((c) => c.id) },
      }).select("_id firstname lastname phoneNumber");

      const customerMap = {};
      customersInfo.forEach((c) => {
        customerMap[c._id.toString()] = {
          name: `${c.firstname} ${c.lastname}`,
          phone: c.phoneNumber,
        };
      });

      const fullDetails = compartments
        .map(
          (c) =>
            `- Compartment ${c.label}: ${customerMap[c.customer].name} (${
              c.capacity
            }L)`
        )
        .join("\n");

      const truckOwnerIds = matchingVehicles.map((v) => v.truckOwner);
      const truckOwners = await User.find({
        _id: { $in: truckOwnerIds },
        role: "TruckOwner",
      }).select("firstname lastname phoneNumber");

      const notifyMessage = `New Shared Order Available:
- Fuel Type: ${fuelType}
- Total Capacity: ${totalCapacity} Liters
- Source: ${source}
- Depot: ${depot}
- Vehicle Capacity: ${selectedVehicle.tankCapacity} Liters
- Utilization: ${Math.round(
        (totalCapacity / selectedVehicle.tankCapacity) * 100
      )}%

Compartments Allocation:
${fullDetails}

Please check your dashboard to accept.`;

      await Promise.all(
        truckOwners.map((owner) =>
          sendSMS(
            owner.phoneNumber,
            `Dear ${owner.firstname} ${owner.lastname},\n\n${notifyMessage}`
          )
        )
      );

      return res.status(200).json({
        message: "Matching shared order found and merged.",
        sharedGroupId,
        totalCapacity,
        vehicle: selectedVehicle,
        compartments,
        utilization: totalCapacity / selectedVehicle.tankCapacity,
      });
    }

    //  Fallback if no match found
    setTimeout(async () => {
      try {
        const updatedOrder = await Order.findById(newOrder._id);
        if (updatedOrder?.status === "Pending") {
          const customer = await User.findById(customerId);
          await sendSMS(
            customer.phoneNumber,
            `Dear ${customer.firstname}, your shared order has been waiting 24 hours without a match.\nOptions:\n1. Upgrade to private.\n2. Wait.\n3. Cancel the order.`
          );
        }
      } catch (err) {
        console.error("Timeout reminder error:", err);
      }
    }, 24 * 60 * 60 * 1000);

    return res.status(201).json({
      message: "Shared order placed and is waiting for a match.",
      orderId: newOrder.orderId,
    });
  } catch (err) {
    console.error("Error placing shared order:", err);
    next(err);
  }
};


export const getSharedOrders = async (req, res, next) => {
  try {
    // Step 1: Fetch all shared orders that are requested or pending
    const sharedOrders = await Order.find({
      routeWay: "shared",
      status: { $in: ["Requested", "Pending"] },
    })
      .populate("customerId", "firstname lastname phoneNumber email")
      .populate("stations", "stationName district district")
      .populate("vehicleId");

    if (!sharedOrders.length) {
      return res.status(404).json({
        message: "No shared orders found.",
      });
    }

    // Step 2: Process Compartments and Customers
    const processedOrders = await Promise.all(
      sharedOrders.map(async (order) => {
        //  Fetch Vehicle Information
        const vehicle = await Vehicle.findById(order.vehicleId).select(
          "-documents -__v -plateNumber"
        );

        if (!vehicle) {
          return {
            ...order.toObject(),
            vehicle: null,
            compartments: [],
            message: "No assigned vehicle yet.",
          };
        }

        // Fetch Customer Names from Compartments
        const customersInfo = await User.find({
          _id: { $in: vehicle.compartments.map((c) => c.customer) },
        }).select("_id firstname lastname");

        // Create Customer Map for Name Lookup
        const customerMap = {};
        customersInfo.forEach((cust) => {
          customerMap[
            cust._id.toString()
          ] = `${cust.firstname} ${cust.lastname}`;
        });

        // Map Compartments with Customer Names
        const compartments = vehicle.compartments.map((c) => ({
          label: c.label,
          customer: customerMap[c.customer] || "Not Assigned",
          capacity: c.capacity,
        }));

        return {
          ...order.toObject(),
          vehicle,
          compartments,
        };
      })
    );

    res.status(200).json({
      message: "Shared orders retrieved successfully.",
      orders: processedOrders,
    });
  } catch (err) {
    console.error("Error retrieving shared orders:", err);
    next(err);
  }
};

export const getAllStationsForCustomer = async (req, res, next) => {
  try {
    const customerId = req.user.id;

    const stations = await Station.find({ customerId });

    if (!stations.length) {
      return res
        .status(404)
        .json({ message: "No stations found for this customer." });
    }

    res.status(200).json({
      message: "Stations retrieved successfully.",
      stations,
    });
  } catch (err) {
    console.error("Error fetching stations:", err);
    next(err);
  }
};

export const getAllDepotsWithSources = async (req, res, next) => {
  try {
    const depots = await Depot.find();

    if (!depots.length) {
      return res.status(404).json({ message: "No depots found." });
    }

    res.status(200).json({
      message: "Depots retrieved successfully.",
      depots,
    });
  } catch (err) {
    console.error("Error retrieving depots:", err);
    next(err);
  }
};

//Get all customers that match
export const getSharedOrdersAndCustomers = async (req, res, next) => {
  try {
    const loggedInCustomerId = req.user.id;

    const loggedInCustomerOrders = await Order.find({
      customerId: loggedInCustomerId,
      routeWay: "shared",
      status: "Pending",
    });

    if (!loggedInCustomerOrders.length) {
      return res.status(404).json({
        message:
          "No pending orders found for the current customer with shared route.",
      });
    }

    const loggedInCustomerDepotAndRegions = loggedInCustomerOrders.map(
      (order) => ({
        depot: order.depot,
        district: order.district,
      })
    );

    const matchingOrders = await Order.find({
      routeWay: "shared",
      status: "Pending",
      customerId: { $ne: loggedInCustomerId },
      $or: loggedInCustomerDepotAndRegions,
    })
      .populate("customerId", "firstname lastname")
      .select(
        "-fuelType -routeWay -deliveryTime -source -longitude -price -status -createdAt"
      );

    if (!matchingOrders.length) {
      return res.status(404).json({
        message:
          "No matching pending orders found with shared route and criteria.",
      });
    }

    res.status(200).json({
      message: "Matching customers with pending orders retrieved successfully.",
      orders: matchingOrders,
    });
  } catch (err) {
    console.error("Error retrieving matching customers:", err);
    next(err);
  }
};

//Searching the match order
export const searchMatchingOrders = async (req, res, next) => {
  try {
    const { fuelType, depot, source, company, district } = req.body;

    if (!fuelType || !depot || !district || !source || !company) {
      return res.status(400).json({
        message:
          "Fuel type, depot, source, company, and district are required to search.",
      });
    }

    const loggedInCustomerId = req.user.id;

    const matchingOrders = await Order.aggregate([
      {
        $lookup: {
          from: "stations",
          localField: "stations",
          foreignField: "_id",
          as: "stationDetails",
        },
      },
      {
        $unwind: "$stationDetails",
      },
      {
        $match: {
          fuelType,
          depot,
          source,
          "companies.name": company,
          "stationDetails.district": district,
          status: "Pending",
          customerId: { $ne: new mongoose.Types.ObjectId(loggedInCustomerId) },
        },
      },
      {
        $lookup: {
          from: "users",
          localField: "customerId",
          foreignField: "_id",
          as: "customerDetails",
        },
      },
      {
        $unwind: "$customerDetails",
      },
      {
        $project: {
          // Fields from Order
          fuelType: 1,
          depot: 1,
          source: 1,
          capacity: 1,
          status: 1,
          deliveryTime: 1,
          createdAt: 1,
          // Fields from Station
          "stationDetails.stationName": 1,
          "stationDetails.district": 1,
          "stationDetails.district": 1,
          // Fields from Customer
          "customerDetails.firstname": 1,
          "customerDetails.lastname": 1,
          "customerDetails.district": 1,
          "customerDetails.district": 1,
        },
      },
    ]);

    if (!matchingOrders.length) {
      return res.status(404).json({
        message: "No matching orders found with the provided criteria.",
      });
    }

    res.status(200).json({
      message: "Matching orders retrieved successfully.",
      orders: matchingOrders,
    });
  } catch (err) {
    console.error("Error retrieving matching orders:", err);
    next(err);
  }
};

//Save match shared
export const processCustomerOrder = async (req, res, next) => {
  const { orderId } = req.params;
  const loggedInCustomerId = req.user.id;

  try {
    // Step 1: Fetch the existing order and logged-in customer's order
    const existingOrder = await Order.findById(orderId).populate("customerId");
    const loggedInCustomerOrder = await Order.findOne({
      customerId: loggedInCustomerId,
      status: { $in: ["Pending", "Requested"] },
    }).populate("customerId");

    if (!existingOrder || !loggedInCustomerOrder) {
      return res
        .status(404)
        .json({ message: "Order(s) not found or no active order" });
    }

    const C1 = existingOrder.capacity || 0;
    const C2 = loggedInCustomerOrder.capacity || 0;
    const totalCapacity = C1 + C2;

    // Step 2: Find a suitable vehicle
    const vehicles = await Vehicle.find({
      status: "Available",
      tankCapacity: { $gte: totalCapacity },
      compartmentCapacities: { $exists: true, $type: "array" },
    }).sort({ tankCapacity: 1 });

    if (!vehicles.length) {
      return res.status(404).json({
        message: `No available vehicle matches the total capacity (${totalCapacity} litres).`,
      });
    }

    const vehicle = vehicles[0];
    const compartmentCapacities = [
      ...vehicle.compartmentCapacities.map((comp) => comp.capacity),
    ];
    const customerCapacities = [
      {
        customer: `${existingOrder.customerId.firstname} ${existingOrder.customerId.lastname}`,
        capacity: C1,
      },
      {
        customer: `${loggedInCustomerOrder.customerId.firstname} ${loggedInCustomerOrder.customerId.lastname}`,
        capacity: C2,
      },
    ];

    const compartments = [];
    for (
      let i = 0;
      i < compartmentCapacities.length && customerCapacities.length;
      i++
    ) {
      const compartmentCapacity = compartmentCapacities[i];
      const currentCustomer = customerCapacities[0];

      if (currentCustomer.capacity <= compartmentCapacity) {
        compartments.push({
          label: String.fromCharCode(65 + i),
          customer: currentCustomer.customer,
          capacity: currentCustomer.capacity,
        });

        compartmentCapacities[i] -= currentCustomer.capacity;
        customerCapacities.shift();
      } else {
        compartments.push({
          label: String.fromCharCode(65 + i),
          customer: currentCustomer.customer,
          capacity: compartmentCapacity,
        });

        currentCustomer.capacity -= compartmentCapacity;
        compartmentCapacities[i] = 0;
      }
    }

    if (customerCapacities.length > 0) {
      const excessCapacities = customerCapacities.map((customer) => ({
        customer: customer.customer,
        excess: customer.capacity,
      }));

      return res.status(400).json({
        message: "The total capacity cannot fit into the vehicle compartments.",
        details: excessCapacities.map(
          (e) =>
            `${e.customer} has ${e.excess} litres that cannot fit into available compartments.`
        ),
        vehicle: {
          id: vehicle._id,
          tankCapacity: vehicle.tankCapacity,
          compartmentCapacities: vehicle.compartmentCapacities,
        },
      });
    }

    // Step 3: Save the total capacity (CT) in both orders
    existingOrder.status = "Requested";
    loggedInCustomerOrder.status = "Requested";
    existingOrder.totalCapacity = totalCapacity;
    loggedInCustomerOrder.totalCapacity = totalCapacity;

    await existingOrder.save();
    await loggedInCustomerOrder.save();

    // Step 4: Update the vehicle status to Busy
    vehicle.status = "Busy";
    await vehicle.save();

    // Step 5: Save data to Shared collection
    const sharedData = new Shared({
      vehicle: {
        id: vehicle._id,
        tankCapacity: vehicle.tankCapacity,
        numberOfCompartments: vehicle.numberOfCompartments,
        compartments,
      },
      totalCapacity,
    });
    await sharedData.save();

    // Step 6: Notify the truck owner
    const truckOwner = await User.findOne({ role: "TruckOwner" });
    if (truckOwner) {
      const message = `Customers have placed orders with a combined capacity of ${totalCapacity} litres. Compartments: ${compartments
        .map((c) => `${c.label} (${c.customer}: ${c.capacity}L)`)
        .join(", ")}`;
      try {
        await sendMessageToTruckOwner(truckOwner._id.toString(), message);
      } catch (err) {
        console.error(
          `Failed to send notification to TruckOwner: ${err.message}`
        );
        await new Message({
          truckOwnerId: truckOwner._id,
          message,
          status: "unread",
        }).save();
      }
    }

    res.status(200).json({
      message: "Order processed successfully.",
      vehicle: {
        id: vehicle._id,
        tankCapacity: vehicle.tankCapacity,
        numberOfCompartments: vehicle.numberOfCompartments,
        compartments,
      },
      totalCapacity,
    });
  } catch (err) {
    console.error("Error processing customer order:", err);
    next(err);
  }
};

//Delete Station
export const deleteStation = async (req, res, next) => {
  try {
    const { stationId } = req.params;
    const customerId = req.user.id; // Logged-in customer

    // Find the station
    const station = await Station.findOne({ _id: stationId, customerId });

    if (!station) {
      return res
        .status(404)
        .json({ message: "Station not found or not owned by you." });
    }

    // Check if the station is associated with any active orders
    const existingOrder = await Order.findOne({ stations: stationId });

    if (existingOrder) {
      return res.status(400).json({
        message:
          "Station cannot be deleted because it is associated with an order.",
      });
    }

    // Delete the station
    await Station.findByIdAndDelete(stationId);

    res.status(200).json({
      message: "Station deleted successfully.",
      stationId,
    });
  } catch (err) {
    console.error("Error deleting station:", err);
    next(err);
  }
};
