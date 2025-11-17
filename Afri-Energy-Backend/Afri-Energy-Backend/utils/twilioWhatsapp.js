import twilio from 'twilio';

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const fromNumber = process.env.TWILIO_WHATSAPP_NUMBER;

const client = twilio(accountSid, authToken);

/**
 * @param {string} to 
 * @param {string} message 
 * @returns {Promise<any>} 
 */
export const sendWhatsappMessage = async (to, message) => {
  try {
    const result = await client.messages.create({
      from: fromNumber,
      body: message,
      to: to // must include "whatsapp:" prefix, e.g., "whatsapp:+255XXXXXXXXX"
    });
    return result;
  } catch (error) {
    console.error(`Error sending WhatsApp message to ${to}:`, error.message);
    throw error;
  }
};
