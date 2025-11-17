import mongoose from "mongoose";

const suggestionSchema = new mongoose.Schema({
  orderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Order",
    required: true,
  },
  vehicleId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Vehicle",
    required: true,
  },
  status: {
    type: String,
    enum: ["Suggested", "Used", "Rejected"],
    default: "Suggested",
  },
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model("Suggestion", suggestionSchema);
