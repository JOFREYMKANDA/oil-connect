const swaggerDefinition = {
  openapi: "3.0.0",
  info: {
    title: "API Documentation",
    version: "1.0.0",
    description:
      "Comprehensive documentation for the APIs, including all endpoints.",
    contact: {
      name: "Support Team",
      email: "africomenergies@gmail.com",
      url: "https://aei.co.tz/",
    },
    license: {
      name: "MIT License",
      url: "https://opensource.org/licenses/MIT",
    },
  },
  servers: [
    {
      url: "http://localhost:4000",
      description: "Local development server",
    },
  ],
  paths: {
    "/api/v1/auth/register": {
      post: {
        summary: "Register a New User",
        description:
          "Creates a new user account, validates email and phone number, and sends an OTP to the provided phone number for verification.",
        tags: ["Register"],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["firstname", "lastname", "phoneNumber", "password"],
                properties: {
                  firstname: {
                    type: "string",
                    example: "John",
                    description: "The user’s first name.",
                  },
                  lastname: {
                    type: "string",
                    example: "Doe",
                    description: "The user’s last name.",
                  },
                  phoneNumber: {
                    type: "string",
                    example: "+255624279007",
                    description:
                      "The user’s phone number in international format.",
                  },
                  email: {
                    type: "string",
                    example: "john.doe@example.com",
                    description:
                      "The user’s email address (optional). Must be a valid email format.",
                  },
                  password: {
                    type: "string",
                    example: "123456",
                    description: "A secure password for the user account.",
                  },
                  role: {
                    type: "string",
                    example: "Customer",
                    description:
                      "The user’s role in the system (Admin, TruckOwner, or Customer). Defaults to Customer.",
                  },
                },
              },
            },
          },
        },
        responses: {
          201: {
            description:
              "OTP sent successfully. The user should verify using the OTP.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example:
                        "User registered successfully. OTP sent to phone number.",
                      description:
                        "Confirmation message for successful registration.",
                    },
                    userId: {
                      type: "string",
                      example: "64a9f239a8c7fa00450a234b",
                      description: "The ID of the newly created user.",
                    },
                  },
                },
              },
            },
          },
          400: {
            description:
              "Invalid input data or phone number already registered.",
          },
        },
      },
    },
    "/api/v1/auth/login": {
      post: {
        summary: "Authenticate a User",
        description:
          "Authenticates a user with their phone number and password, returning a JWT token upon success.",
        tags: ["Auth"],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["phoneNumber", "password"],
                properties: {
                  phoneNumber: {
                    type: "string",
                    example: "+255624279007",
                    description: "The user’s registered phone number.",
                  },
                  password: {
                    type: "string",
                    example: "123456",
                    description:
                      "The password associated with the user account.",
                  },
                },
              },
            },
          },
        },
        responses: {
          200: {
            description:
              "Login successful. Returns a JWT token for authenticated requests.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example: "Login successful",
                      description:
                        "Confirmation message indicating successful login.",
                    },
                    token: {
                      type: "string",
                      example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                      description:
                        "JWT token to be used for subsequent authenticated requests.",
                    },
                  },
                },
              },
            },
          },
          400: {
            description:
              "Invalid phone number or password. Authentication failed.",
          },
        },
      },
    },

    "/api/v1/auth/verify-otp": {
      post: {
        summary: "Verify OTP",
        description:
          "Verifies the OTP sent to the user’s phone number during registration or login.",
        tags: ["Verify OTP"],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["phoneNumber", "otp"],
                properties: {
                  phoneNumber: {
                    type: "string",
                    example: "+255624279007",
                    description:
                      "The user’s phone number to which the OTP was sent.",
                  },
                  otp: {
                    type: "string",
                    example: "123456",
                    description: "The OTP sent to the user’s phone number.",
                  },
                },
              },
            },
          },
        },
        responses: {
          200: {
            description:
              "OTP verification successful. Returns a JWT token for authenticated requests.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example: "Authentication successful",
                      description:
                        "Confirmation message indicating successful OTP verification.",
                    },
                    token: {
                      type: "string",
                      example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                      description:
                        "JWT token to be used for subsequent authenticated requests.",
                    },
                  },
                },
              },
            },
          },
          400: {
            description: "Invalid OTP or phone number.",
          },
        },
      },
    },

    "/api/auth/resend-otp": {
      post: {
        summary: "Resend OTP",
        description:
          "Generates and sends a new OTP to the user’s phone number, invalidating the previous OTP.",
        tags: ["Resend OTP"],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["phoneNumber"],
                properties: {
                  phoneNumber: {
                    type: "string",
                    example: "+255624279007",
                    description: "The user’s registered phone number.",
                  },
                },
              },
            },
          },
        },
        responses: {
          200: {
            description: "OTP resent successfully. Please check your phone.",
          },
          400: {
            description: "Invalid phone number or user does not exist.",
          },
        },
      },
    },

    "/api/auth/add-staff": {
      post: {
        summary: "Add Staff",
        description: "Allows an admin to add a new staff member to the system.",
        tags: ["Admin Add Staff"],
        security: [{ bearerAuth: [] }], // Assuming you use Bearer token for authentication
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["firstname", "lastname", "phoneNumber", "password"],
                properties: {
                  firstname: {
                    type: "string",
                    example: "John",
                    description: "First name of the staff member.",
                  },
                  lastname: {
                    type: "string",
                    example: "Doe",
                    description: "Last name of the staff member.",
                  },
                  phoneNumber: {
                    type: "string",
                    example: "+1234567890",
                    description:
                      "Phone number of the staff member in international format.",
                  },
                  email: {
                    type: "string",
                    example: "staff@example.com",
                    description:
                      "Email address of the staff member (optional).",
                  },
                  password: {
                    type: "string",
                    example: "securepassword",
                    description: "Password for the staff account.",
                  },
                  role: {
                    type: "string",
                    example: "Staff",
                    description: 'Role of the new user. Defaults to "Staff".',
                  },
                },
              },
            },
          },
        },
        responses: {
          201: {
            description: "Staff member added successfully.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example: "Staff member added successfully",
                    },
                    staffId: {
                      type: "string",
                      example: "64a9f239a8c7fa00450a234b",
                    },
                  },
                },
              },
            },
          },
          403: {
            description: "Access denied. Admins only.",
          },
          400: {
            description: "Phone number or email already registered.",
          },
        },
      },
    },

    "/api/trucks/register": {
      post: {
        summary: "Register TruckOwner",
        description:
          "Register a new TruckOwner by providing their details (firstname, lastname, email, and phone number). An OTP is generated and sent to the phone number for login verification.",
        tags: ["Register Truck Owner"],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["firstname", "lastname", "email", "phoneNumber"],
                properties: {
                  firstname: {
                    type: "string",
                    example: "John",
                    description: "The first name of the TruckOwner.",
                  },
                  lastname: {
                    type: "string",
                    example: "Doe",
                    description: "The last name of the TruckOwner.",
                  },
                  email: {
                    type: "string",
                    example: "johndoe@example.com",
                    description: "The email address of the TruckOwner.",
                  },
                  phoneNumber: {
                    type: "string",
                    example: "+255624279007",
                    description:
                      "The phone number of the TruckOwner in international format.",
                  },
                },
              },
            },
          },
        },
        responses: {
          201: {
            description:
              "TruckOwner registered successfully. OTP sent to phone number.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example:
                        "TruckOwner registered successfully. OTP sent to phone number.",
                    },
                    userId: {
                      type: "string",
                      example: "64a9f239a8c7fa00450a234b",
                      description:
                        "The unique ID of the newly created TruckOwner.",
                    },
                  },
                },
              },
            },
          },
          400: {
            description: "Phone number or email already registered.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example: "Phone number already registered.",
                    },
                  },
                },
              },
            },
          },
        },
      },
    },

    "/api/trucks/login": {
      post: {
        summary: "Verify OTP Truck Owner",
        description:
          "Verify the OTP sent to the TruckOwner's phone number during registration or login. Returns a JWT token upon successful verification.",
        tags: ["Verify OTP Truck Owner"],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["phoneNumber", "otp"],
                properties: {
                  phoneNumber: {
                    type: "string",
                    example: "+255624279007",
                    description: "The phone number of the TruckOwner.",
                  },
                  otp: {
                    type: "string",
                    example: "123456",
                    description:
                      "The OTP sent to the phone number for verification.",
                  },
                },
              },
            },
          },
        },
        responses: {
          200: {
            description: "Authentication successful.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example: "Authentication successful.",
                    },
                    token: {
                      type: "string",
                      example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                      description: "JWT token for authenticated requests.",
                    },
                  },
                },
              },
            },
          },
          400: {
            description: "Invalid OTP or OTP expired.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example: "OTP has expired or is invalid.",
                    },
                  },
                },
              },
            },
          },
          404: {
            description: "User not found.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example: "User not found.",
                    },
                  },
                },
              },
            },
          },
        },
      },
    },

    "api/drives/login": {
      post: {
        summary: "Driver Login",
        description:
          "Allows a driver to log in by generating an OTP sent to their phone number.",
        tags: ["Driver Login"],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["phoneNumber"],
                properties: {
                  phoneNumber: {
                    type: "string",
                    example: "+255624279007",
                    description: "The phone number of the driver.",
                  },
                },
              },
            },
          },
        },
        responses: {
          200: {
            description: "OTP sent to phone number.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example: "OTP sent to phone number.",
                    },
                  },
                },
              },
            },
          },
          404: {
            description: "Driver not found.",
          },
        },
      },
    },

    "api/drives/verify-otp": {
      post: {
        summary: "Verify Driver OTP",
        description:
          "Verifies the OTP sent to the driver's phone number and generates a JWT token.",
        tags: ["Verify Driver OTP"],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["phoneNumber", "otp"],
                properties: {
                  phoneNumber: {
                    type: "string",
                    example: "+255624279007",
                    description: "The phone number of the driver.",
                  },
                  otp: {
                    type: "string",
                    example: "123456",
                    description: "The OTP sent to the driver's phone number.",
                  },
                },
              },
            },
          },
        },
        responses: {
          200: {
            description: "Authentication successful.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example: "Authentication successful.",
                    },
                    token: {
                      type: "string",
                      example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                    },
                  },
                },
              },
            },
          },
          400: {
            description: "Invalid OTP or OTP expired.",
          },
          404: {
            description: "Driver not found.",
          },
        },
      },
    },

    "api/vehicles/register": {
      "post": {
        "summary": "Register a Vehicle",
        "description": "Allows a TruckOwner to register a vehicle by providing details and uploading necessary documents.",
        "tags": ["Truck owner Register a Vehicle"],
        "requestBody": {
          "required": true,
          "content": {
            "multipart/form-data": {
              "schema": {
                "type": "object",
                "properties": {
                  "vehicleType": { "type": "string", "example": "Truck" },
                  "plateNumber[headPlate]": { "type": "string", "example": "T123ABC" },
                  "plateNumber[trailerPlate]": { "type": "string", "example": "T456DEF" },
                  "plateNumber[specialPlate]": { "type": "string", "example": "SP123XYZ" },
                  "vehicleMake": { "type": "string", "example": "Toyota" },
                  "vehicleColor": { "type": "string", "example": "White" },
                  "vehicleModelYear": { "type": "integer", "example": 2020 },
                  "fuelType": { "type": "string", "example": "Diesel" },
                  "tankCapacity": { "type": "integer", "example": 100 },
                  "documents": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "format": "binary"
                    },
                    "description": "Array of uploaded documents."
                  }
                }
              }
            }
          }
        },
        "responses": {
          "201": {
            "description": "Vehicle registered successfully."
          }
        }
      }
    },

    "api/vehicles/status/:vehicleId": {
      "patch": {
        "summary": "Update Vehicle Status",
        "description": "Allows an admin to approve or reject a vehicle registration.",
        "tags": ["Admin Update Vehicle Status"],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "status": {
                    "type": "string",
                    "enum": ["Approved", "Rejected"]
                  }
                }
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Vehicle status updated successfully."
          }
        }
      }
    },
    
    "/api/vehicle/status/:vehicleId": {
      "get": {
        "summary": "Update Vehicle Status",
        "description": "Retrieve the status of a registered vehicle.",
        "tags": ["Get Vehicle Status"],
        "responses": {
          "200": {
            "description": "Returns the vehicle status."
          }
        }
      }
    },
    
    "/api/driver/update": {
      patch: {
        summary: "Update Driver Information",
        description: "Allows a driver to update their personal information, including uploading a profile image.",
        tags: ["Update Driver Information"],
        security: [
          {
            bearerAuth: [],
          },
        ],
        requestBody: {
          required: true,
          content: {
            "multipart/form-data": {
              schema: {
                type: "object",
                properties: {
                  workingPosition: {
                    type: "string",
                    example: "Lead Driver",
                    description: "The working position of the driver.",
                  },
                  region: {
                    type: "string",
                    example: "Dar es Salaam",
                    description: "The region where the driver is based.",
                  },
                  district: {
                    type: "string",
                    example: "Kinondoni",
                    description: "The district where the driver is based.",
                  },
                  profileImage: {
                    type: "string",
                    format: "binary",
                    description: "The driver's profile image (JPEG, JPG, PNG).",
                  },
                },
              },
            },
          },
        },
        responses: {
          200: {
            description: "Driver information updated successfully.",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    message: {
                      type: "string",
                      example: "Driver information updated successfully.",
                    },
                    driver: {
                      type: "object",
                      properties: {
                        id: { type: "string", example: "64b1e5e3a65c1f00123a7b45" },
                        firstname: { type: "string", example: "John" },
                        lastname: { type: "string", example: "Doe" },
                        phoneNumber: { type: "string", example: "+255624279007" },
                        email: { type: "string", example: "john.doe@example.com" },
                        profileImage: {
                          type: "string",
                          example: "public/profileImages/profileImage-1689238736.jpg",
                        },
                        workingPosition: { type: "string", example: "Lead Driver" },
                        region: { type: "string", example: "Dar es Salaam" },
                        district: { type: "string", example: "Kinondoni" },
                      },
                    },
                  },
                },
              },
            },
          },
          400: {
            description: "Invalid file type or missing required fields.",
          },
          404: {
            description: "Driver not found.",
          },
          403: {
            description: "Access denied. Only drivers can access this endpoint.",
          },
        },
      },
    },
  },
  components: {
    securitySchemes: {
      bearerAuth: {
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT",
      },
    },
    
  },
};

export default swaggerDefinition;
