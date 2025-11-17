import mongoose from "mongoose";

const { Schema } = mongoose;

const documentSchema = new Schema({
  name: { type: String, required: true },
  filePath: { type: String, required: true },
});

const vehicleSchema = new Schema(
  {
    vehicleType: { type: String, required: true },
    plateNumber: {
      headPlate: { type: String },
      trailerPlate: { type: String, required: true },
      specialPlate: { type: String },
    },
    vehicleColor: { type: String, required: true },
    vehicleModelYear: { type: Number, required: true },
    latitude: { type: Number, default: null },
    longitude: { type: Number, default: null },
    numberOfCompartments: { type: Number, required: true },
    compartmentCapacities: [
      {
        id: { type: String, required: true },
        capacity: { type: Number, required: true },
      },
    ],
    // fuelType: {
    //   type: String,
    //   enum: ["Diesel", "Petrol", "Kerosine"],
    //   required: true,
    // },
    tankCapacity: { type: Number, required: true },
    vehicleIdentity: { type: String, unique: true, required: true },
    documents: [documentSchema],
    status: {
      type: String,
      enum: ["Submitted", "Approved", "Rejected", "Available", "Busy"],
      default: "Submitted",
    },
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    truckOwner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    gpsImei: {
      type: String,
      default: null,
    },
    
  },
  { timestamps: true }
);

export default mongoose.model("Vehicle", vehicleSchema);
