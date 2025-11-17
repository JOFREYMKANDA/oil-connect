import mongoose from "mongoose";
const { Schema } = mongoose;

const userSchema = new Schema(
  {
    firstname: { type: String, required: true },
    lastname: { type: String, required: true },
    phoneNumber: { type: Number, unique: true },
    region: { type: Number, unique: true },
    email: { type: String, unique: true },
    profileImage: { type: String },
    region: { type: String },
    district: { type: String },
    licenseNumber: {
      type: Number,
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
          // Check if the expiration date is in the future
          return value > Date.now();
        },
        message: "License expiration date must be in the future.",
      },
    },
    latitude: { type: Number },
    longitude: { type: Number },
    userDepot: { type: String },
    password: { type: String },
    workingPosition: { type: String },
    role: {
      type: String,
      enum: ["Admin", "TruckOwner", "Customer", "Driver", "Staff"],
      required: true,
      default: "Customer",
    },

    status: { type: String, enum: ["ACTIVE", "INACTIVE"], default: "ACTIVE" },
    otp: { type: String },
    otpExpiresAt: { type: Date },
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

userSchema.virtual("id").get(function () {
  return this._id.toHexString();
});

userSchema.set("toJSON", {
  virtuals: true,
});

export default mongoose.model("User", userSchema);
