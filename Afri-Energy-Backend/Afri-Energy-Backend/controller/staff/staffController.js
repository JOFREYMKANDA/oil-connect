import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "../../models/User.js";
import { createError } from "../../utils/error.js";

export const login = async (req, res, next) => {
  const { phoneNumber, email, password } = req.body;

  try { 
    // Find the user by email or phone number
    const user = await User.findOne({
      $or: [{ email }, { phoneNumber }],
    });

    if (!user) {
      return next(createError(404, "User not found"));
    }

    // Validate password
    if (!password) {
      return next(createError(400, "Password is required"));
    }

    const isPasswordCorrect = await bcrypt.compare(password, user.password);
    if (!isPasswordCorrect) {
      return next(createError(400, "Invalid credentials"));
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    res.status(200).json({
      message: "Login successful",
      token,
      role: user.role,
    });
  } catch (err) {
    next(err);
  }
};
