import moment from "moment";
import Order from "../models/orders/Order.js";

export async function generateOrderId(customerId) {
  const date = moment().format("YYYYMMDDHHmmss"); // Timestamp (numeric)
  const customerSuffix = customerId.slice(-2).replace(/\D/g, "0"); // Ensures 2 digits (replaces non-digits with '0')
  const orderCount = await Order.countDocuments({
    customerId,
    createdAt: { $gte: moment().startOf("day").toDate() }, // Today's orders only
  });

  return `OD-${date}-${customerSuffix.padStart(2, "0")}-${String(
    orderCount + 1
  ).padStart(4, "0")}`;
}

