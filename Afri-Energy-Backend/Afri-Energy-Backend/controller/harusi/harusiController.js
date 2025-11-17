import { createError } from "../../utils/error.js";
import { sendSMS } from "../../utils/otp.js";

export const sendBulkMessage = async (req, res, next) => {
    try {
      const { phoneNumbers, message } = req.body;
  
      // Validate input
      if (!phoneNumbers || !Array.isArray(phoneNumbers) || phoneNumbers.length === 0) {
        return next(createError(400, "An array of phone numbers is required."));
      }
      if (!message || typeof message !== "string") {
        return next(createError(400, "A message is required."));
      }
  
      // For each phone number, send SMS.
      const sendPromises = phoneNumbers.map((phone) => {
        // Trim the phone number to avoid any unwanted spaces or formatting issues.
        const phoneStr = phone.toString().trim();
        return sendSMS(phoneStr, message)
          .then((result) => ({ phone: phoneStr, status: "sent", result }))
          .catch((err) => ({ phone: phoneStr, status: "failed", error: err.message }));
      });
  
      const results = await Promise.all(sendPromises);
  
      res.status(200).json({
        message: "Bulk SMS processing completed.",
        results,
      });
    } catch (err) {
      console.error("Error sending bulk messages:", err);
      next(err);
    }
  };
  

  // export const sendBulkWhatsapp = async (req, res) => {
  //   const { phoneNumbers, message } = req.body; 
  //   if (!phoneNumbers || !Array.isArray(phoneNumbers) || !message) {
  //     return res.status(400).json({ error: 'Phone numbers (as an array) and a message are required.' });
  //   }
  
  //   try {
  //     const results = [];
  
  //     for (const number of phoneNumbers) {
  //       try {
  //         const response = await sendWhatsappMessage(number, message);
  //         results.push({ phone: number, status: 'sent', sid: response.sid });
  //       } catch (error) {
  //         results.push({ phone: number, status: 'failed', error: error.message });
  //       }
  //     }
  
  //     res.status(200).json({
  //       message: 'Bulk WhatsApp processing completed.',
  //       results
  //     });
  //   } catch (error) {
  //     console.error('Error in sendBulkWhatsapp:', error);
  //     res.status(500).json({ error: error.message });
  //   }
  // };
  