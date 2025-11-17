import express from "express";
import { sendBulkMessage } from "../../controller/harusi/harusiController.js";

const router = express.Router();

// Endpoint to send a bulk SMS to a list of phone numbers
router.post("/send-bulk", sendBulkMessage);

// POST endpoint to send bulk WhatsApp messages
// router.post('/send-whatsapp', sendBulkWhatsapp);

export default router;
