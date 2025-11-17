import mongoose from "mongoose";

const gpsSchema = new mongoose.Schema({
  imei: String,
  timestamp: Date,
  latitude: Number,
  longitude: Number,
  altitude: Number,
  speed: Number,
  ignition: String,
  generatedId: String,
  status: {
    type: String,
    enum: ["CONFIGURED", "INSTALLED"],
    default: "CONFIGURED",
  },
  vehicleIdentity: {
    type: String,
  },
  
});

export default mongoose.model("GpsData", gpsSchema);
