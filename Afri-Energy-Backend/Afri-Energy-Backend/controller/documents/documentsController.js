import path from "path";
import fs from "fs";
import Vehicle from "../../models/vehicles/Vehicle.js";
import mongoose from "mongoose";
import PDFDocument from "pdfkit";
import Order from "../../models/orders/Order.js";
import { createError } from "../../utils/error.js";

export const downloadVehicleFile = async (req, res, next) => {
  try {
    const { vehicleId } = req.params;
    const { fileType, fileName } = req.query;

    if (!fileType || !fileName) {
      return res.status(400).json({
        message: "fileType and fileName are required as query parameters.",
      });
    }

    // Find the vehicle by ID
    const vehicle = await Vehicle.findById(vehicleId);
    if (!vehicle) {
      return res.status(404).json({ message: "Vehicle not found." });
    }

    const fileEntry = vehicle.documents.find((doc) => {
      const basename = path.basename(doc.filePath);
      return (
        (doc.name && doc.name.toLowerCase() === fileName.toLowerCase()) ||
        (basename && basename.toLowerCase() === fileName.toLowerCase())
      );
    });

    if (!fileEntry) {
      return res
        .status(404)
        .json({ message: "File not found for this vehicle." });
    }

    const ext = fileName.split(".").pop().toLowerCase();
    const imageExts = ["jpg", "jpeg", "png"];
    const allowedDocExts = [
      "pdf",
      "doc",
      "docx",
      "txt",
      "ppt",
      "pptx",
      "xls",
      "xlsx",
    ];

    // Validate extension based on fileType
    if (fileType === "image") {
      if (!imageExts.includes(ext)) {
        return res.status(400).json({
          message:
            "Requested file is not an image. If you're trying to download a document, please set fileType to 'document'.",
        });
      }
    } else if (fileType === "document") {
      if (!allowedDocExts.includes(ext)) {
        return res.status(400).json({
          message: "Requested file is not a supported document type.",
        });
      }
    } else {
      return res.status(400).json({ message: "Invalid fileType provided." });
    }

    // Resolve the file path (assuming filePath stored is relative to the project root)
    const resolvedFilePath = path.resolve(fileEntry.filePath);
    if (!fs.existsSync(resolvedFilePath)) {
      return res
        .status(404)
        .json({ message: "File does not exist on the server." });
    }

    res.download(resolvedFilePath, fileEntry.name);
  } catch (err) {
    console.error("Error downloading file:", err);
    next(err);
  }
};

export const getAllVehicleFiles = async (req, res, next) => {
  try {
    const { vehicleId } = req.params;

    // Find the vehicle and select only the 'documents' field
    const vehicle = await Vehicle.findById(vehicleId).select("documents");
    if (!vehicle) {
      return res.status(404).json({ message: "Vehicle not found." });
    }

    res.status(200).json({
      message: "Vehicle files retrieved successfully.",
      files: vehicle.documents,
    });
  } catch (err) {
    console.error("Error retrieving vehicle files:", err);
    next(err);
  }
};

export const generateVehiclePDF = async (req, res, next) => {
  const { vehicleId } = req.params;

  try {
    const vehicle = await Vehicle.findById(vehicleId).populate("owner").lean();
    if (!vehicle) return res.status(404).json({ message: "Vehicle not found" });

    const truckOwner = vehicle.owner;
    const documentImage = vehicle.documents?.[0]?.filePath;

    const doc = new PDFDocument({ size: "A4", margin: 50 });
    const fileName = `Vehicle_Report_${vehicle.vehicleIdentity}.pdf`;
    const filePath = path.resolve(`./public/reports/${fileName}`);

    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    const stream = fs.createWriteStream(filePath);
    doc.pipe(stream);
    doc.y = 100;

    // ======= Header =======
    doc
      .image("public/assets/afri-logo.png", 50, 85, { width: 40, height: 45 })
      .fillColor("#0E2A47")
      .font("Helvetica-Bold")
      .fontSize(16)
      .text("OIL CONNECT VEHICLE INSPECTION DOCUMENT", 120, doc.y, 45);

    doc.moveDown(1.5);

    const sectionTitle = (title) => {
      doc
        .moveDown()
        .fillColor("#0E2A47")
        .font("Helvetica-Bold")
        .fontSize(14)
        .text(title.toUpperCase(), { underline: true })
        .moveDown(0.5);
    };

    // ======= Truck Owner Info =======
    const infoX = 50;

    doc
      .moveDown(0.5)
      .fillColor("#0E2A47")
      .font("Helvetica-Bold")
      .fontSize(14)
      .text("TRUCK OWNER INFORMATION", infoX, doc.y, { underline: true })
      .moveDown(0.5);

    // Full Name
    doc
      .font("Helvetica-Bold")
      .fontSize(12)
      .fillColor("#000")
      .text("Full Name:", infoX, doc.y, { continued: true })
      .font("Helvetica")
      .text(` ${truckOwner?.firstname || ""} ${truckOwner?.lastname || ""}`)
      .moveDown(0.5);

    // Phone Number
    doc
      .font("Helvetica-Bold")
      .text("Phone Number:", infoX, doc.y, { continued: true })
      .font("Helvetica")
      .text(` ${truckOwner?.phoneNumber || "N/A"}`)
      .moveDown(0.5);

    // Email
    doc
      .font("Helvetica-Bold")
      .text("Email Address:", infoX, doc.y, { continued: true })
      .font("Helvetica")
      .text(` ${truckOwner?.email || "N/A"}`)
      .moveDown();

    // ======= VEHICLE DETAILS Section =======
    sectionTitle("Vehicle Details");

    const drawVehicleDetails = (doc, vehicle, startY) => {
      const labelX = 50;
      const valueX = 180;
      const dashX = 330;
      const checkboxX = 500;
      const checkboxSize = 14;
      let y = startY;
      const lineHeight = 26;

      doc
        .font("Helvetica-Bold")
        .fontSize(12)
        .text("Mark", checkboxX - 10, y - 22); // Adjusted left & up

      const drawSingle = (label, value) => {
        value = value || "N/A";

        // Label
        doc
          .font("Helvetica-Bold")
          .fontSize(12)
          .fillColor("#000")
          .text(`${label}`, labelX, y);

        // Value
        doc.font("Helvetica").text(`${value}`, valueX, y);

        // Dashes
        doc
          .font("Helvetica")
          .fillColor("#888")
          .text("------------------------------", dashX, y);

        // Checkbox (larger and better aligned)
        doc.rect(checkboxX, y + 2, checkboxSize, checkboxSize).stroke();

        y += lineHeight;
      };

      // Draw all vehicle fields
      drawSingle("Vehicle Type", vehicle.vehicleType);
      drawSingle("Model Year", vehicle.vehicleModelYear);
      drawSingle("Plate (Head)", vehicle.plateNumber?.headPlate);
      drawSingle("Plate (Trailer)", vehicle.plateNumber?.trailerPlate);
      drawSingle("Special Plate", vehicle.plateNumber?.specialPlate);
      drawSingle("Fuel Type", vehicle.fuelType);
      drawSingle("Vehicle Color", vehicle.vehicleColor);
      drawSingle("Tank Capacity", `${vehicle.tankCapacity || "N/A"} L`);
      drawSingle("Compartments", vehicle.numberOfCompartments);

      return y + 10;
    };

    const nextY = drawVehicleDetails(doc, vehicle, doc.y);

    // ======= Compartment Capacities =======
    if (vehicle.compartmentCapacities?.length > 0) {
      const labelX = 50;
      const valueX = 180;
      const dashX = 330;
      const checkboxX = 500;
      const checkboxSize = 14;
      const lineHeight = 26;
      let y = nextY + 10;

      // Title
      doc
        .font("Helvetica-Bold")
        .fontSize(14)
        .fillColor("#0E2A47")
        .text("Compartment Capacities", labelX, y, { underline: true });

      y += 25;

      vehicle.compartmentCapacities.forEach((c, i) => {
        const label = `Compartment ${c.id || String.fromCharCode(65 + i)}`;
        const value = `${c.capacity} Liter(s)`;

        // Label
        doc
          .font("Helvetica-Bold")
          .fontSize(12)
          .fillColor("#000")
          .text(label, labelX, y);

        // Value
        doc.font("Helvetica").text(value, valueX, y);

        // Dashes
        doc
          .font("Helvetica")
          .fillColor("#888")
          .text("------------------------------", dashX, y);

        // Checkbox (larger)
        doc.rect(checkboxX, y + 2, checkboxSize, checkboxSize).stroke();

        y += lineHeight;
      });
    }

    // ======= Document Image Page =======
    if (documentImage) {
      const normalizedPath = path.resolve(documentImage.replace(/\\/g, "/"));
      if (fs.existsSync(normalizedPath)) {
        doc.addPage();
        sectionTitle("VEHICLE CARD DOCUMENT");

        doc.image(normalizedPath, doc.x, doc.y, {
          fit: [500, 400],
          align: "center",
          valign: "top",
        });
      }
    }

    // ======= Signature Block =======
    doc.addPage();

    doc
      .font("Helvetica-Oblique")
      .fontSize(13)
      .fillColor("#444")
      .text(
        "The following section should be completed by the verifying authority only.",
        60,
        doc.y
      );

    // Add a space before the comment section
    doc.moveDown(1.5);

    doc
      .font("Helvetica-Bold")
      .fontSize(14)
      .fillColor("#0E2A47")
      .text("Comment", 60, doc.y, { underline: true });

    const commentY = doc.y + 10;
    const lineSpacing = 25;
    const commentLines = 4;

    // Draw blank lines for user to write comments
    for (let i = 0; i < commentLines; i++) {
      doc
        .moveTo(60, commentY + i * lineSpacing)
        .lineTo(540, commentY + i * lineSpacing)
        .stroke();
    }

    // Move below comment section
    doc.y = commentY + commentLines * lineSpacing + 10;

    // ================= Verification Section =================
    sectionTitle("VERIFICATION");

    const labelFontSize = 12;
    const labelX = 60;
    const fieldX = 150;
    const lineWidth = 250; // ⬅️ Reduced from 400
    const lineGap = 30;
    let y = doc.y + 20;

    doc.font("Helvetica").fontSize(labelFontSize).fillColor("#000");

    doc
      .text("Name:", labelX, y)
      .moveTo(fieldX, y + 15)
      .lineTo(fieldX + lineWidth, y + 15)
      .stroke();

    y += lineGap;

    doc
      .text("Signature:", labelX, y)
      .moveTo(fieldX, y + 15)
      .lineTo(fieldX + lineWidth, y + 15)
      .stroke();

    y += lineGap;

    doc
      .text("Date:", labelX, y)
      .moveTo(fieldX, y + 15)
      .lineTo(fieldX + lineWidth, y + 15)
      .stroke();

    // ======= Footer =======
    doc
      .font("Helvetica-Oblique")
      .fontSize(10)
      .fillColor("#888")
      .text("Generated by OIL CONNECT System", 50, 780, {
        align: "center",
        width: 500,
      });

    doc.end();

    stream.on("finish", () => {
      res.download(filePath, fileName);
    });
  } catch (error) {
    next(error);
  }
};

export const downloadVehicleDocument = async (req, res, next) => {
  try {
    const { orderId } = req.params;

    const order = await Order.findOne({ orderId })
      .populate("vehicleId")
      .populate("driverId");

    if (!order) {
      return next(createError(404, "Order not found"));
    }

    if (order.status !== "Completed") {
      return next(
        createError(
          403,
          "Documents can only be downloaded when the order is Accepted."
        )
      );
    }

    // Get first document from vehicle
    const vehicle = order.vehicleId;
    if (!vehicle || !vehicle.documents || vehicle.documents.length === 0) {
      return next(createError(404, "No documents found for this vehicle."));
    }

    const documentPath = path.resolve(
      `public/${vehicle.documents[0].filePath}`
    );
    return res.download(documentPath, vehicle.documents[0].name);
  } catch (err) {
    next(err);
  }
};

export const downloadDriverLicense = async (req, res, next) => {
  try {
    const { orderId } = req.params;

    let order;
    if (mongoose.Types.ObjectId.isValid(orderId)) {
      order = await Order.findOne({
        $or: [{ _id: orderId }, { orderId }],
      }).populate("driverId");
    } else {
      order = await Order.findOne({ orderId }).populate("driverId");
    }

    if (!order) {
      return next(createError(404, "Order not found"));
    }

    if (!["Assigned"].includes(order.status)) {
      return next(
        createError(
          403,
          "Driver license can only be downloaded when the order is Assigned."
        )
      );
    }

    const driver = order.driverId;
    if (!driver || !driver.licenseImage) {
      return next(
        createError(404, "No license image found for assigned driver.")
      );
    }

    const licenseFileName = path.basename(driver.licenseImage); // Ensure only filename
    const licensePath = path.resolve(`public/licenses/${licenseFileName}`);

    if (!fs.existsSync(licensePath)) {
      return next(createError(404, "Driver license file not found on server."));
    }

    return res.download(licensePath, licenseFileName);
  } catch (err) {
    next(err);
  }
};

export const downloadFirstVehicleDocument = async (req, res, next) => {
  try {
    const { vehicleId } = req.params;

    const vehicle = await Vehicle.findById(vehicleId);

    if (!vehicle || !vehicle.documents || vehicle.documents.length === 0) {
      return res.status(404).json({ message: "No document found for this vehicle." });
    }

    const firstDoc = vehicle.documents[0];

    const relativePath = firstDoc.filePath.replace(/^public[\/\\]/, "");

    const filePath = path.join(process.cwd(), "public", relativePath);

    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ message: "File does not exist on server." });
    }

    res.download(filePath, firstDoc.name || "vehicle-document.pdf");
  } catch (err) {
    console.error(err);
    next(err);
  }
};