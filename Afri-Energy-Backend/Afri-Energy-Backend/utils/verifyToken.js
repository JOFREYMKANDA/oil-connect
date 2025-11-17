import jwt from "jsonwebtoken";
import { createError } from "../utils/error.js";
import User from "../models/User.js";

export const verifyToken = (req, res, next) => {
  let token;

  // Check for token in Authorization header or cookies
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    token = req.headers.authorization.split(" ")[1]; // Extract token from Bearer scheme
  } else if (req.cookies.access_token) {
    token = req.cookies.access_token; 
  }

  if (!token) {
    return next(createError(401, "You are not authenticated!"));
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return next(createError(403, "Token is not valid! Please login"));
    }
    req.user = user;
    next();
  });
};


//Verifu user
export const verifyUser = (req, res, next) => {
  verifyToken(req, res, (err) => {
    if (err) {
      return next(createError(403, "You are not authorized!"));
    }

    if (req.user.id === req.params.id || req.user.isAdmin) {
      next();
    } else {
      return next(createError(403, "You are not authorized!"));
    }
  });
};

//Verify Admin
export const verifyAdmin = (req, res, next) => {
  verifyToken(req, res, (err) => {
    if (err) {
      return next(createError(401, "Authentication failed. Please log in."));
    }

    // Check if the user has the Admin role
    if (req.user.role === "Admin") {
      next(); // Proceed if the user is an Admin
    } else {
      return next(createError(403, "Access denied. Admins only."));
    }
  });
};


//Verify Staff
export const verifyStaff = (req, res, next) => {
  verifyToken(req, res, (err) => {
    if (err) {
      return next(createError(401, "Authentication failed. Please log in."));
    }

    // Check if the user has the Staff role
    if (req.user.role === "Staff" || req.user.role === "Admin") {
      next(); // Allow access for Staff and Admin
    } else {
      return next(createError(403, "Access denied. Staff only."));
    }
  });
};

//Veify a Truck Owner
export const verifyTruckOwner = (req, res, next) => {
  verifyToken(req, res, (err) => {
    if (err) {
      return next(createError(401, "Authentication failed. Please log in."));
    }

    if (req.user.role === "TruckOwner") {
      next();
    } else {
      return next(createError(403, "Access denied. Truck Owners only."));
    }
  });
};


export const verifyDriver = (req, res, next) => {
  verifyToken(req, res, (err) => {
    if (err) {
      return next(createError(401, "Authentication failed. Please log in."));
    }

    if (req.user.role !== "Driver") {
      return next(createError(403, "Access denied. Only drivers can have access."));
    }

    next();
  });
};


export const verifyAdminOrStaff = (req, res, next) => {
  if (req.user.role === "Admin" || req.user.role === "Staff") {
    next();
  } else {
    res.status(403).json({ message: "Access denied. Only Admin or Staff allowed." });
  }
};
