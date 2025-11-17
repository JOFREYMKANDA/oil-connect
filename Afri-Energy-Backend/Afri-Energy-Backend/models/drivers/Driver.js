import mongoose from "mongoose";

const driverSchema = new mongoose.Schema(
  {
    firstname: { type: String, required: true },
    lastname: { type: String, required: true },
    phoneNumber: { type: Number, unique: true },
    email: { type: String },
    profileImage: { type: String },
    workingPosition: { type: String },
    region: { type: String },
    district: { type: String },
    role: {
      type: String,
      enum: ["Driver"],
      default: "Driver",
    },
    licenseNumber: {
      type: String,
      validate: {
        validator: function (value) {
          // Check if the license number has exactly 10 digits
          return /^\d{10}$/.test(value);
        },
        message: "License number must be exactly 10 digits.",
      },
    },
    licenseExpireDate: {
      type: Date,
      validate: {
        validator: function (value) {
          return value > Date.now();
        },
        message: "License expiration date must be in the future.",
      },
    },
    licenseImage: { type: String },
    status: {
      type: String,
      enum: ["unverified", "available", "busy", "completed"],
      default: "unverified",
    },
    otp: { type: String },
    otpExpiresAt: { type: Date },

    truckOwnerId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    assignedOrder: { type: mongoose.Schema.Types.ObjectId, ref: "Order" },
    createdAt: {
      type: Date,
      default: Date.now,
      immutable: true,
    },
    lastUpdatedAt: {
      type: Date,
      default: Date.now,
    },
    lastLoginDate: {
      type: Date,
    },
  },
  { timestamps: true }
);

driverSchema.virtual("id").get(function () {
  return this._id.toHexString();
});

driverSchema.set("toJSON", {
  virtuals: true,
});

export default mongoose.model("Driver", driverSchema);
