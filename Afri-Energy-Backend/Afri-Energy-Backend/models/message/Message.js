import mongoose from "mongoose";

const messageSchema = new mongoose.Schema({
  truckOwnerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },

  adminId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: false,
  },
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
  staffId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: false,
  },
  message: { type: String, required: true },
  status: {
    type: String,
    enum: ["unread", "read"],
    default: "unread",
  },
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model("Message", messageSchema);
