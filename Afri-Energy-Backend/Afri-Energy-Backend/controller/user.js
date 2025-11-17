import User from "../models/User.js";
import path from "path";
import fs from "fs";

import { __dirname, BASE_URL } from '../index.js';
import { createError } from "../utils/error.js";
import bcrypt from "bcryptjs";


export const updateUserProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { firstname, lastname, phoneNumber, email, region, district, workingPosition } = req.body;

    // Find the user by ID
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Update user fields except password
    user.firstname = firstname || user.firstname;
    user.lastname = lastname || user.lastname;
    user.email = email || user.email;
    user.phoneNumber = phoneNumber || user.phoneNumber;
    user.region = region || user.region;
    user.district = district || user.district;
    user.workingPosition = workingPosition || user.workingPosition;

    // Handle profile picture upload
    if (req.file) {
      // Delete old profile picture if it exists
      if (user.profileImage) {
        const oldPath = path.join(__dirname, "..", user.profileImage.replace(BASE_URL + "/", ""));
        if (fs.existsSync(oldPath)) {
          fs.unlinkSync(oldPath);
        }
      }

      // Save new profile picture with full URL
      user.profileImage = `${BASE_URL}/public/drivers/${req.file.filename}`;
    }

    user.lastUpdatedAt = Date.now();

    // Save the updated user
    await user.save();

    res.status(200).json({ message: "User profile updated successfully", user });
  } catch (err) {
    next(err);
  }
};


export const addRole = async (req, res, next) => {
  try {
    const { userId, role } = req.body;

    if (
      !["Admin", "User", "StationOwner", "TankOwner", "Driver"].includes(role)
    ) {
      return res.status(400).send("Invalid role");
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).send("User not found");
    }

    user.role = role;
    await user.save();
    res.status(200).send("Role updated successfully");
  } catch (err) {
    next(err);
  }
};


export const getAdminStaffUsers = async (req, res, next) => {
  try {
    const loggedInUserId = req.user.id;
    
    const users = await User.find({
      role: { $in: ["Admin", "Staff"] },
      _id: { $ne: loggedInUserId }
    }).select("firstname lastname email phoneNumber role");

    if (!users.length) {
      return res.status(404).json({ message: "No Admin or Staff users found." });
    }

    res.status(200).json({
      message: "Admin and Staff users retrieved successfully.",
      users,
    });
  } catch (err) {
    console.error("Error retrieving users:", err);
    next(err);
  }
};


export const updateStaffStatus = async (req, res, next) => {
  try {
    const { staffId } = req.params;
    const { action } = req.body; 

    if (action !== "block" && action !== "unblock") {
      return next(createError(400, "Invalid action. Use 'block' or 'unblock'."));
    }

    const user = await User.findById(staffId);
    if (!user) {
      return next(createError(404, "User not found."));
    }

    if (user.role !== "Staff") {
      return next(createError(403, "Only staff users can be blocked or unblocked."));
    }

    user.status = action === "block" ? "INACTIVE" : "ACTIVE";
    await user.save();

    res.status(200).json({
      message: `Staff user ${action === "block" ? "blocked" : "unblocked"} successfully.`,
      user: {
        id: user._id,
        status: user.status,
      },
    });
  } catch (err) {
    next(err);
  }
};


export const changePassword = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { currentPassword, newPassword, confirmNewPassword } = req.body;

    if (!currentPassword || !newPassword || !confirmNewPassword) {
      return next(createError(400, "All fields are required."));
    }

    if (newPassword !== confirmNewPassword) {
      return next(createError(400, "New passwords do not match."));
    }

    const user = await User.findById(userId);
    if (!user) {
      return next(createError(404, "User not found."));
    }

    const isPasswordCorrect = await bcrypt.compare(currentPassword, user.password);
    if (!isPasswordCorrect) {
      return next(createError(400, "Current password is incorrect."));
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    user.password = hashedPassword;
    await user.save();

    res.status(200).json({
      message: "Password changed successfully.",
    });
  } catch (err) {
    next(err);
  }
};