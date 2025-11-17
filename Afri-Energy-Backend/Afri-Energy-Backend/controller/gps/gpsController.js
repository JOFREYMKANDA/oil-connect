import GpsData from "../../models/gps/GpsData.js";
import Order from "../../models/orders/Order.js";
import Vehicle from "../../models/vehicles/Vehicle.js";
import { parseRuptelaData } from "../../utils/parser.js";

export const handleGpsData = async (data, socket, io) => {
  try {
    const parsedData = parseRuptelaData(data, socket);

    const installedRecord = await GpsData.findOne({
      imei: parsedData.imei,
      status: "INSTALLED",
    });

    parsedData.status = installedRecord ? "INSTALLED" : "CONFIGURED";

    const existingId = await GpsData.findOne({
      imei: parsedData.imei,
      generatedId: { $exists: true },
    });

    if (existingId) {
      parsedData.generatedId = existingId.generatedId;
    } else {
      const count = await GpsData.countDocuments({ generatedId: { $exists: true } });
      parsedData.generatedId = `ECO5 LITE-${count + 1}`;
    }

    const existingVehicleIdentity = await GpsData.findOne({
      imei: parsedData.imei,
      vehicleIdentity: { $exists: true },
    });

    if (existingVehicleIdentity) {
      parsedData.vehicleIdentity = existingVehicleIdentity.vehicleIdentity;
    }

    await new GpsData(parsedData).save();

    // Emit to everyone for general display
    io.emit("gps-data", parsedData);

    // Emit to Truck Owner Room
    const approvedVehicle = await Vehicle.findOne({
      gpsImei: parsedData.imei,
      status: { $in: ["Approved", "Busy"] },
    }).populate("owner");

    if (parsedData.status === "INSTALLED" && approvedVehicle?.truckOwner?._id) {
      const truckOwnerRoom = `truckowner:${approvedVehicle.truckOwner._id}`;
      io.to(truckOwnerRoom).emit("truckowner-gps", parsedData);
    }

    // Emit to Driver Room if a driver is assigned
    const assignedOrder = await Order.findOne({
      vehicleId: approvedVehicle?._id,
      status: "Assigned",
    });

    if (assignedOrder?.driverId) {
      const driverRoom = `driver:${assignedOrder.driverId}`;
      console.log("Emitting to driver:", driverRoom, parsedData);
      io.to(driverRoom).emit("driver-gps", parsedData);
    }

    // Emit to Customer Room if the order is onDelivery
    const deliveryOrder = await Order.findOne({
      vehicleId: approvedVehicle?._id,
      status: "onDelivery",
    });

    if (deliveryOrder?.customerId) {
      const customerRoom = `customer:${deliveryOrder.customerId}`;
      console.log("Emitting to customer:", customerRoom, parsedData);
      io.to(customerRoom).emit("customer-gps", parsedData);
    }

    // Acknowledge to GPS device
    socket.write(Buffer.from([0x01]));
  } catch (err) {
    console.error("Error handling GPS data:", err);
  }
};


// export const getAllGpsData = async (req, res) => {
//   try {
//     const { imei } = req.query;

//     let data;

//     if (imei) {
//       // For specific IMEI
//       data = await GpsData.find({
//         imei,
//         latitude: { $ne: null },
//         longitude: { $ne: null },
//       }).sort({ timestamp: -1 });
//     } else {
//       // For all grouped by IMEI
//       data = await GpsData.aggregate([
//         {
//           $match: {
//             imei: { $regex: /^\d{15}$/ },
//             latitude: { $ne: null },
//             longitude: { $ne: null },
//           },
//         },
//         { $sort: { timestamp: -1 } },
//         {
//           $group: {
//             _id: "$imei",
//             imei: { $first: "$imei" },
//             generatedId: { $first: "$generatedId" },
//             timestamp: { $first: "$timestamp" },
//             vehicleIdentity: { $first: "$vehicleIdentity" },
//             ignition: { $first: "$ignition" },
//             status: { $first: "$status" },
//             id: { $first: "$_id" },
//             latitude: { $first: "$latitude" },
//             longitude: { $first: "$longitude" },
//             altitude: { $first: "$altitude" },
//             speed: { $first: "$speed" },
//           },
//         },
//         {
//           $project: {
//             _id: 0,
//             imei: 1,
//             id: 1,
//             generatedId: 1,
//             timestamp: 1,
//             vehicleIdentity: 1,
//             status: 1,
//             ignition: 1,
//             latitude: 1,
//             longitude: 1,
//             altitude: 1,
//             speed: 1,
//           },
//         },
//         { $sort: { timestamp: -1 } },
//       ]);
//     }

//     res.status(200).json(data);
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ message: "Failed to fetch GPS data" });
//   }
// };

export const getAllGpsData = async (req, res) => {
  try {
    const { imei } = req.query;

    let data;

    if (imei) {
      // For specific IMEI
      data = await GpsData.find({
        imei,
        latitude: { $ne: null },
        longitude: { $ne: null },
      }).sort({ timestamp: -1 }).limit(100);  
    } else {
      // For all grouped by IMEI
      data = await GpsData.aggregate([
        {
          $match: {
            imei: { $regex: /^\d{15}$/ },
            latitude: { $ne: null },
            longitude: { $ne: null },
          },
        },
        {
          $group: {
            _id: "$imei",
            imei: { $first: "$imei" },
            generatedId: { $first: "$generatedId" },
            timestamp: { $first: "$timestamp" },
            vehicleIdentity: { $first: "$vehicleIdentity" },
            ignition: { $first: "$ignition" },
            status: { $first: "$status" },
            id: { $first: "$_id" },
            latitude: { $first: "$latitude" },
            longitude: { $first: "$longitude" },
            altitude: { $first: "$altitude" },
            speed: { $first: "$speed" },
          },
        },
        {
          $project: {
            _id: 0,
            imei: 1,
            id: 1,
            generatedId: 1,
            timestamp: 1,
            vehicleIdentity: 1,
            status: 1,
            ignition: 1,
            latitude: 1,
            longitude: 1,
            altitude: 1,
            speed: 1,
          },
        },
        // Step 2: Sort after the group stage
        { $sort: { timestamp: -1 } },
        { $limit: 100 },  
      ]).allowDiskUse(true); 
    }

    res.status(200).json(data);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Failed to fetch GPS data" });
  }
};


export const getConfiguredGps = async (req, res, next) => {
  try {
    const latestPerImei = await GpsData.aggregate([
      // Only configured GPS
      { $match: { status: "CONFIGURED" } },

      // Sort newest first per IMEI
      { $sort: { timestamp: -1 } },

      // Group by IMEI and keep only latest entry
      {
        $group: {
          _id: "$imei",
          imei: { $first: "$imei" },
          generatedId: { $first: "$generatedId" },
          timestamp: { $first: "$timestamp" },
          latitude: { $first: "$latitude" },
          longitude: { $first: "$longitude" },
          altitude: { $first: "$altitude" },
          speed: { $first: "$speed" },
          ignition: { $first: "$ignition" },
          status: { $first: "$status" },
          vehicleIdentity: { $first: "$vehicleIdentity" },
        },
      },

      // Optional: Only valid IMEIs (15 digits)
      {
        $match: {
          imei: { $regex: /^\d{15}$/ },
        },
      },
    ]);

    res.status(200).json({
      success: true,
      gps: latestPerImei,
    });
  } catch (err) {
    console.error("Error fetching GPS data:", err);
    next(err);
  }
};
