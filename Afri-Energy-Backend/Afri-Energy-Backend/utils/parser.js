let deviceIMEI = {};

export const parseRuptelaData = (data, socket) => {
  const timestamp = parseTimestamp(data);
  const gps = parseGPS(data);
  const speed = parseSpeed(data);

  return {
    imei: extractIMEI(data, socket),
    timestamp,
    latitude: gps.latitude,
    longitude: gps.longitude,
    altitude: gps.altitude,
    speed,
    ignition: data.readUInt8(18) & 1 ? "ON" : "OFF",
  };
};

const extractIMEI = (data, socket) => {
  try {
    if (!deviceIMEI[socket.remoteAddress]) {
      const imeiBuffer = data.slice(2, 10);
      const imei = parseInt(imeiBuffer.toString("hex"), 16).toString();
      deviceIMEI[socket.remoteAddress] = imei;
    }
    return deviceIMEI[socket.remoteAddress];
  } catch {
    return "Unknown";
  }
};

const parseTimestamp = (data) => {
  try {
    const ts = data.readUInt32BE(0);
    return ts < 1000000000 || ts > Date.now() / 1000
      ? new Date()
      : new Date(ts * 1000);
  } catch {
    return new Date();
  }
};

const parseGPS = (data) => {
  try {
    const lonRaw = data.readInt32BE(20);
    const latRaw = data.readInt32BE(24);
    const altRaw = data.readUInt16BE(28);

    const latitude = latRaw / 1e7;
    const longitude = lonRaw / 1e7;
    const altitude = altRaw / 10.0;

    if (
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180
    ) {
      return {
        latitude: null,
        longitude: null,
        altitude: null,
      };
    }

    return {
      latitude,
      longitude,
      altitude,
    };
  } catch {
    return {
      latitude: null,
      longitude: null,
      altitude: null,
    };
  }
};

const parseSpeed = (data) => {
  try {
    const speed = data.readUInt16BE(18) / 10;
    return speed < 0.5 ? 0 : speed;
  } catch {
    return 0;
  }
};
