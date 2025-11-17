import express from "express";
import { login } from "../../controller/staff/staffController.js";
const router = express.Router();

// Login
router.post("/staff-login", login);

export default router;
