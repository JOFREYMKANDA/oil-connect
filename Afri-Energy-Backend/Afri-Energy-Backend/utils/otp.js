// import twilio from "twilio";
// import dotenv from "dotenv";
// dotenv.config();

// const client = twilio(
//   process.env.TWILIO_ACCOUNT_SID,
//   process.env.TWILIO_AUTH_TOKEN
// );

// export const generateOTP = () =>
//   Math.floor(100000 + Math.random() * 900000).toString();

// export const sendOTP = async (phoneNumber, otp) => {
//   try {
//     const message = await client.messages.create({
//       body: `Your verification code is: ${otp}`,
//       from: process.env.TWILIO_PHONE_NUMBER,
//       to: phoneNumber,
//     });
//     return message.sid;
//   } catch (error) {
//     throw new Error("Error sending OTP: " + error.message);
//   }
// };

import axios from "axios";
import dotenv from "dotenv";

dotenv.config();

// Beem API credentials
const BEEM_API_KEY = process.env.BEEM_API_KEY;
const BEEM_SECRET_KEY = process.env.BEEM_SECRET_KEY;
const BEEM_SENDER_NAME = process.env.BEEM_SENDER_NAME;

// Beem API URL
const BEEM_URL = "https://apisms.beem.africa/v1/send";

function sanitizeMessage(text) {
  return text
    .replace(/[^\x00-\x7F]/g, "") // Remove non-ASCII
    .replace(/[^\w\s.,:;?!'"()@&%-]/g, ""); // Clean message for SMS
}

function formatPhoneNumber(number) {
  const clean = number.replace(/[^0-9]/g, "");
  if (clean.startsWith("0")) {
    return "255" + clean.slice(1);
  }
  if (clean.startsWith("255")) {
    return clean;
  }
  return clean;
}

// Generate OTP
export const generateOTP = () =>
  Math.floor(100000 + Math.random() * 900000).toString();

export const sendOTP = async (phoneNumber, otp) => {
  try {
    phoneNumber = formatPhoneNumber(phoneNumber);

    const messageBody = sanitizeMessage(
      `${otp} is your verification code. Please do not share your code with anyone.`
    );

    const encodedCredentials = Buffer.from(
      `${BEEM_API_KEY}:${BEEM_SECRET_KEY}`
    ).toString("base64");

    const payload = {
      source_addr: BEEM_SENDER_NAME,
      schedule_time: null,
      encoding: 0,
      message: messageBody,
      recipients: [{ recipient_id: "1", dest_addr: phoneNumber }],
    };

    const headers = {
      Authorization: `Basic ${encodedCredentials}`,
      "Content-Type": "application/json",
    };

    const response = await axios.post(BEEM_URL, payload, { headers });

    if (response.data.code === 100) {
      return response.data.request_id;
    } else {
      console.error("Beem OTP error:", response.data);
      throw new Error(`Failed to send OTP: ${response.data.message}`);
    }
  } catch (error) {
    console.error("OTP error:", error.response?.data || error.message);
    throw new Error("Error sending OTP: " + error.message);
  }
};

/**
 * Sends an SMS message using Beem API
 * @param {string} phoneNumber
 * @param {string} message
 */
export const sendSMS = async (phoneNumber, message) => {
  try {
    phoneNumber = String(phoneNumber);

    // Validate phone number format
    if (!/^\d{10,15}$/.test(phoneNumber)) {
      throw new Error(`Invalid phone number format: ${phoneNumber}`);
    }

    // Sanitize message to avoid special character issues
    const sanitizedMessage = message
      .replace(/[^\x00-\x7F]/g, "") // Remove non-ASCII chars
      .replace(/[^\w\s.,:;?!'"()@&%-]/g, ""); // Allow readable punctuation

    // Encode API credentials
    const credentials = `${BEEM_API_KEY}:${BEEM_SECRET_KEY}`;
    const encodedCredentials = Buffer.from(credentials).toString("base64");

    // Construct payload
    const payload = {
      source_addr: BEEM_SENDER_NAME,
      schedule_time: "",
      encoding: 0, // 0 = plain text
      message: sanitizedMessage,
      recipients: [
        {
          recipient_id: "1",
          dest_addr: phoneNumber,
        },
      ],
    };

    const headers = {
      Authorization: `Basic ${encodedCredentials}`,
      "Content-Type": "application/json",
    };

    // Send request
    const response = await axios.post(BEEM_URL, payload, { headers });

    if (response.data.code === 100) {
      return response.data.request_id;
    } else {
      throw new Error(`Failed to send SMS: ${response.data.message}`);
    }
  } catch (error) {
    throw new Error("Error sending SMS: " + error.message);
  }
};
