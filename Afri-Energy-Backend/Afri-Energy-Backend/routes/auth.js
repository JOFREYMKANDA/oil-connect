import express from "express";
import {
  AdminOrStaffLogin,
  deleteAccount,
  getLoggedInUser,
  loginWithPhone,
  register,
  requestDeleteOTP,
  resendOTP,
  signOut,
  verifyPhoneOTP,
} from "./../controller/auth.js";
import { otpRateLimiter } from "../middleware/rateLimiter.js";
import { verifyToken } from "../utils/verifyToken.js";

const router = express.Router();

//Authentication
router.post("/register", register);

router.post("/login", otpRateLimiter, loginWithPhone);

router.post("/verify-otp", verifyPhoneOTP);

// Get logged-in user details
router.get("/current-user", verifyToken, getLoggedInUser);

// Resend OTP
router.post("/resend-otp", otpRateLimiter, resendOTP);

//Login
router.post("/admin-staff-login", AdminOrStaffLogin);

//Sign-out
router.post("/logout", verifyToken, signOut);

// Request OTP for account deletion
router.post("/request-delete-account", requestDeleteOTP);

// Delete a TruckOwner or Customer account
router.delete("/delete-account", deleteAccount);

export default router;
