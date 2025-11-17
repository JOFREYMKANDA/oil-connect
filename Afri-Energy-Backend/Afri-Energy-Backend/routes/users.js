import express from "express";
import {
  changePassword,
  getAdminStaffUsers,
  updateStaffStatus,
  updateUserProfile,
} from "../controller/user.js";
import {
  verifyAdmin,
  verifyAdminOrStaff,
  verifyToken,
} from "../utils/verifyToken.js";
import upload from "../middleware/profile_multer.js";

const router = express.Router();

//UPDATE
router.put(
  "/profile",
  verifyToken,
  upload.single("profileImage"),
  updateUserProfile
);

router.get("/get-admin-staff", verifyToken, getAdminStaffUsers);

//Block or unblock a staff account
router.patch(
  "/block-staff/:staffId",
  verifyToken,
  verifyAdmin,
  updateStaffStatus
);

// Admin & Staff: Change Password
router.put("/change-password", verifyToken, verifyAdminOrStaff, changePassword);

export default router;
