import mongoose from "mongoose";

const stationSchema = new mongoose.Schema({
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  stationName: { type: String, required: true },
  label: { type: String, required: true },
  region: { type: String, required: true },
  district: { type: String, required: true },
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true },
});

export default mongoose.model("Station", stationSchema);
