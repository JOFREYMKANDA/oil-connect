import moment from "moment";
import crypto from "crypto";

export async function generateVehicleIdentity(trailerPlate) {
  const cleanPlate = trailerPlate.replace(/[^a-zA-Z0-9]/g, "").toUpperCase();

  const timestamp = moment().format("YYYYMMDDHHmmss");

  const hash = crypto
    .createHash("sha1")
    .update(`${cleanPlate}${timestamp}`)
    .digest("hex")
    .slice(0, 4)
    .toUpperCase();

  return `${cleanPlate}-${timestamp}-${hash}`;
}
