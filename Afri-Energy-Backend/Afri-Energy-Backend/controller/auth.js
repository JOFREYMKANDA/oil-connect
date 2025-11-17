import bcrypt from "bcryptjs";
import { createError } from "./../utils/error.js";
import jwt from "jsonwebtoken";
import User from "../models/User.js";
import { generateOTP, sendOTP } from "./../utils/otp.js";
import Order from "../models/orders/Order.js";
import Driver from "../models/drivers/Driver.js";

const otps = new Map();

// Register
export const register = async (req, res, next) => {
  try {
    const { firstname, lastname, phoneNumber, email, role } = req.body;

    if (!firstname || !lastname || !phoneNumber) {
      return next(
        createError(400, "Firstname, lastname, and phone number are required")
      );
    }

    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return next(createError(400, "Invalid email format"));
    }

    const [existingUser, existingEmail] = await Promise.all([
      User.findOne({ phoneNumber }),
      email ? User.findOne({ email }) : null,
    ]);

    if (existingUser)
      return next(createError(400, "Phone number already registered"));
    if (existingEmail)
      return next(createError(400, "Email already registered"));

    const otp = generateOTP();
    const otpExpiresAt = new Date(Date.now() + 5 * 60 * 1000);

    const newUser = new User({
      firstname,
      lastname,
      phoneNumber,
      email,
      role: role || "Customer",
      status: "ACTIVE",
      otp,
      otpExpiresAt,
    });

    const savedUser = await newUser.save();

    try {
      await sendOTP(phoneNumber, otp);
    } catch (otpErr) {
      console.error("OTP send failed:", otpErr.message);
      await User.findByIdAndDelete(savedUser._id); // Optional: rollback
      return next(createError(500, "User saved but OTP failed to send"));
    }

    return res.status(200).json({
      message: "User registered successfully! OTP sent for verification.",
      userId: savedUser.id,
    });

  } catch (err) {
    console.error("Registration error:", err);
    next(err);
  }
};

// Create Default Admin User
export const createDefaultAdmin = async () => {
  try {
    const salt = bcrypt.genSaltSync(10);
    const hash = bcrypt.hashSync("admin123", salt);

    const adminData = {
      firstname: "Admin",
      lastname: "Admin",
      email: "system@admin.com",
      phoneNumber: "+255123456789",
      password: hash,
      role: "Admin",
    };

    const admin = await User.findOneAndUpdate(
      { role: "Admin" }, // Match existing Admin by role
      adminData,
      { upsert: true, new: true }
    );

    console.log("Admin created successfully");
  } catch (err) {
    console.error("Error ensuring default admin user:", err);
  }
};


// Map of default phone numbers and their fixed OTPs
const defaultUsers = {
  "255700000001": "123456",
  "255700000002": "654321",
  "255700000003": "234567",
};


//Users Login
export const loginWithPhone = async (req, res, next) => {
  try {
    const { phoneNumber } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({ message: "Phone number is required." });
    }

    const sanitizedPhone = phoneNumber.trim().replace(/[^\d]/g, "");

    // Look up in User, then Driver
    let entity = await User.findOne({ phoneNumber: sanitizedPhone });
    if (!entity) {
      entity = await Driver.findOne({ phoneNumber: sanitizedPhone });
    }

    if (!entity) {
      return res.status(404).json({ message: "User not found." });
    }

    // Generate OTP
    // const otp = generateOTP();
     // Check if user has a default OTP
     let otp;
     if (defaultUsers[sanitizedPhone]) {
       otp = defaultUsers[sanitizedPhone];
     } else {
       otp = generateOTP();
     }
     
    entity.otp = otp;
    entity.otpExpiresAt = new Date(Date.now() + 5 * 60 * 1000);
    await entity.save();

    await sendOTP(sanitizedPhone, otp).catch((err) =>
      console.error("OTP send failed:", err.message)
    );

    return res.status(200).json({
      message: `OTP sent to ${sanitizedPhone}. Please verify within 5 minutes.`,
      role: entity.role,
      phoneNumber: sanitizedPhone,
    });
  } catch (err) {
    console.error("Error during login:", err);
    return res.status(500).json({ message: "Internal server error." });
  }
};


//Users verify using otp
export const verifyPhoneOTP = async (req, res, next) => {
  const { phoneNumber, otp } = req.body;

  try {
    if (!phoneNumber || !otp) {
      return res
        .status(400)
        .json({ message: "Phone number and OTP are required." });
    }

    const numericPhone = Number(phoneNumber);
    if (isNaN(numericPhone)) {
      return res.status(400).json({ message: "Invalid phone number format." });
    }

    // Look for user or driver
    let entity = await User.findOne({ phoneNumber: numericPhone });
    if (!entity) {
      entity = await Driver.findOne({ phoneNumber: numericPhone });
    }

    if (!entity) {
      return res.status(404).json({ message: "User not found." });
    }

    // Check OTP and expiry
    if (
      !entity.otp ||
      entity.otp !== otp ||
      !entity.otpExpiresAt ||
      new Date(entity.otpExpiresAt) < Date.now()
    ) {
      return res
        .status(400)
        .json({ message: "OTP is invalid or has expired." });
    }

    // Clear OTP fields after successful verification
    entity.otp = null;
    entity.otpExpiresAt = null;

    // Generate JWT token
    const token = jwt.sign(
      {
        id: entity._id,
        phoneNumber: entity.phoneNumber,
        role: entity.role,
        firstname: entity.firstname,
        lastname: entity.lastname,
      },
      process.env.JWT_SECRET,
      { expiresIn: "90d" }
      
    );

    entity.sessionToken = token;
    await entity.save();

    return res.status(200).json({
      token,
      message: "Login successful.",
    });
  } catch (err) {
    console.error("Error during OTP verification:", err);
    return res.status(500).json({ message: "Internal server error." });
  }
};


//Get Logged in User
export const getLoggedInUser = async (req, res, next) => {
  try {
    let user;
    if (req.user.role === "Driver") {
      user = await Driver.findById(req.user.id).select(
        "-password -__v -createdAt -lastUpdatedAt -updatedAt "
      );
    } else {
      user = await User.findById(req.user.id).select(
        "-password -__v -createdAt -lastUpdatedAt -updatedAt"
      );
    }

    if (!user) {
      return res.status(404).json({ message: "User not found." });
    }

    res.status(200).json({
      message: "User details retrieved successfully.",
      user,
    });
  } catch (err) {
    console.error("Error retrieving logged-in user:", err);
    next(err);
  }
};

//Resend OTP
export const resendOTP = async (req, res, next) => {
  try {
    const { phoneNumber } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({ message: "Phone number is required." });
    }

    const sanitizedPhone = phoneNumber.trim().replace(/[^\d]/g, "");

    // Look up in User, then Driver (consistent with other functions)
    let entity = await User.findOne({ phoneNumber: sanitizedPhone });
    if (!entity) {
      entity = await Driver.findOne({ phoneNumber: sanitizedPhone });
    }

    if (!entity) {
      return res.status(404).json({ message: "User not found." });
    }

    // Generate new OTP and update in database (consistent with loginWithPhone)
    const newOtp = generateOTP();
    entity.otp = newOtp;
    entity.otpExpiresAt = new Date(Date.now() + 5 * 60 * 1000);
    await entity.save();

    // Send OTP (same as loginWithPhone)
    await sendOTP(sanitizedPhone, newOtp).catch((err) =>
      console.error("OTP resend failed:", err.message)
    );

    return res.status(200).json({
      message: `OTP resent to ${sanitizedPhone}. Please verify within 5 minutes.`,
      role: entity.role,
      phoneNumber: sanitizedPhone,
    });
  } catch (err) {
    console.error("Error during OTP resend:", err);
    return res.status(500).json({ message: "Internal server error." });
  }
};

//Login
export const AdminOrStaffLogin = async (req, res, next) => {
  const { email, phoneNumber, password } = req.body;

  try {
    // Admin & Staff Login using Email & Password
    if (email && password) {
      const user = await User.findOne({
        email,
        role: { $in: ["Admin", "Staff"] },
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "Unauthorized. Please log in again.",
        });
      }

      // Check if the user's account is blocked
      if (user.status === "INACTIVE") {
        return res.status(403).json({
          success: false,
          message: "Your account has been blocked. Please contact support.",
        });
      }

      const isPasswordCorrect = await bcrypt.compare(password, user.password);
      if (!isPasswordCorrect) {
        return res.status(400).json({
          success: false,
          message: "Invalid Email or password.",
        });
      }

      // Generate JWT token
      const token = jwt.sign(
        { id: user._id, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: "24h" }
      );

      return res.status(200).json({
        success: true,
        message: "Successfully logged in!",
        token,
        role: user.role,
      });
    }

    // Customer Login using Phone Number & OTP
    if (phoneNumber) {
      const user = await User.findOne({
        phoneNumber,
        role: { $in: ["Customer", "Driver"] },
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User not found.",
        });
      }

      // Check if the user's account is blocked
      if (user.status === "INACTIVE") {
        return res.status(403).json({
          success: false,
          message: "Your account has been blocked. Please contact support.",
        });
      }

      // Generate OTP
      const otp = generateOTP();
      otps.set(phoneNumber, { otp, expiresAt: Date.now() + 300000 }); // OTP expires in 5 minutes

      await sendOTP(phoneNumber, otp);

      return res.status(200).json({
        success: true,
        message: "OTP sent to phone number. Please verify to log in.",
      });
    }

    return res.status(400).json({
      success: false,
      message:
        "Invalid login credentials. Please provide valid email or phoneNumber.",
    });
  } catch (err) {
    console.error("Error during login:", err);
    return res.status(500).json({
      success: false,
      message: "Internal server error.",
    });
  }
};

// Sign Out
export const signOut = async (req, res, next) => {
  try {
    res.clearCookie("access_token", { httpOnly: true, secure: true });

    res.status(200).json({ message: "Logged out successfully." });
  } catch (err) {
    console.error("Error logging out:", err);
    next(err);
  }
};

//Request to delete account
export const requestDeleteOTP = async (req, res, next) => {
  const { phoneNumber } = req.body;

  try {
    const numericPhone = Number(phoneNumber);
    if (isNaN(numericPhone)) {
      return next(createError(400, "Invalid phone number format."));
    }

    const user = await User.findOne({ phoneNumber: numericPhone });
    if (!user) {
      return next(createError(404, "User not found."));
    }

    const otp = generateOTP();
    user.otp = otp;
    user.otpExpiresAt = new Date(Date.now() + 5 * 60 * 1000); // OTP valid for 5 minutes
    await user.save();

    // Convert phone number to string when sending the OTP
    await sendOTP(user.phoneNumber.toString(), otp);

    res.status(200).json({
      message: "OTP sent to your registered phone number.",
    });
  } catch (err) {
    console.error("Error sending OTP:", err);
    next(err);
  }
};

//CUSTOMER or TRUCKOWNER Delete its account
export const deleteAccount = async (req, res, next) => {
  const { otp, phoneNumber } = req.body;

  try {
    const user = await User.findOne({ phoneNumber });
    if (!user) {
      return next(createError(404, "User not found."));
    }

    if (!user.otp || !user.otpExpiresAt || new Date() > user.otpExpiresAt) {
      return next(createError(400, "OTP is invalid or has expired."));
    }

    if (user.otp !== otp) {
      return next(createError(400, "Incorrect OTP."));
    }

    const incompleteOrders = await Order.find({
      customerId: user._id,
      status: { $ne: "Completed" },
    });

    if (incompleteOrders.length > 0) {
      return next(
        createError(
          400,
          "Account cannot be deleted. All orders must have a 'Completed' status."
        )
      );
    }

    await User.findByIdAndDelete(user._id);

    res.status(200).json({
      message: "Account deleted successfully.",
    });
  } catch (err) {
    next(err);
  }
};
