import mongoose from "mongoose";

const sharedSchema = new mongoose.Schema({
  message: { type: String, required: true },
  vehicle: {
    id: { type: mongoose.Schema.Types.ObjectId, ref: "Vehicle", required: true },
    tankCapacity: { type: Number, required: true },
    numberOfCompartments: { type: Number, required: true },
    compartments: [
      {
        label: { type: String, required: true }, // A, B, C...
        customer: { type: String, required: true },
        capacity: { type: Number, required: true },
      },
    ],
  },
  totalCapacity: { type: Number, required: true },
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model("Shared", sharedSchema);
