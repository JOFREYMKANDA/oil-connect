import mongoose from "mongoose";
import moment from "moment";

const orderSchema = new mongoose.Schema({
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  fuelType: {
    type: String,
    enum: ["Diesel", "Petrol", "Kerosine"],
    required: true,
  },
  orderId: {
    type: String,
    required: true,
    validate: {
      validator: function (v) {
        return /^OD-\d{14}-\d{2}-\d+$/.test(v); // Example: OD-20240518153045-12-0001
      },
      message: (props) => `${props.value} is not a valid order ID format!`,
    },
  },

  routeWay: { type: String, enum: ["shared", "private"], required: true },
  capacity: { type: Number },
  deliveryTime: { type: Date },
  region: { type: String },
  district: { type: String },
  source: { type: String, required: true },
  longitude: { type: Number },
  distance: { type: Number },
  latitude: { type: Number },
  depot: { type: String, enum: ["Tanga", "Dar", "Mtwara"], required: true },
  price: { type: Number, required: true, default: 0 },
  sharedGroupId: { type: String, default: null },
  companies: [
    {
      name: { type: String, required: true },
      latitude: { type: Number },
      longitude: { type: Number },
    },
    1,
  ],
  stations: [{ type: mongoose.Schema.Types.ObjectId, ref: "Station" }],
  driverId: { type: mongoose.Schema.Types.ObjectId, ref: "Driver" },
  vehicleId: { type: mongoose.Schema.Types.ObjectId, ref: "Vehicle" },
  truckOwnerId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  status: {
    type: String,
    enum: [
      "Pending",
      "Requested",
      "Approved",
      "Accepted",
      "Assigned",
      "onDelivery",
      "Completed",
      "Cancelled",
    ],
    default: "Pending",
  },
  merged: { type: Boolean, default: false },
  tripStartedAt: { type: Date },
  createdAt: { type: Date, default: Date.now },
});

// Virtual field to format createdAt
orderSchema.virtual("formattedCreatedAt").get(function () {
  return moment(this.createdAt).format("YYYY-MM-DD HH:mm");
});

// Virtual field to format deliveryTime
orderSchema.virtual("formattedDeliveryTime").get(function () {
  return moment(this.deliveryTime).format("YYYY-MM-DD HH:mm");
});

// Virtual field to format tripStartedAt
orderSchema.virtual("formattedTripStartedAt").get(function () {
  return moment(this.tripStartedAt).format("YYYY-MM-DD HH:mm");
});

// Ensure virtuals are included in JSON output
orderSchema.set("toJSON", { virtuals: true });
orderSchema.set("toObject", { virtuals: true });

export default mongoose.model("Order", orderSchema);
