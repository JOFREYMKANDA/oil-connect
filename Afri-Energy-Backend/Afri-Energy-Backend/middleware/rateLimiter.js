import rateLimit from 'express-rate-limit';

// OTP Resend Rate Limiter
export const otpRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP to 5 OTP requests per windowMs
  message: {
    success: false,
    status: 429,
    message: 'Too many OTP requests. Please try again after 15 minutes.',
  },
  headers: true,
});

// General API Rate Limiter (Optional)
export const apiRateLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100, // Limit each IP to 100 requests per minute
  message: {
    success: false,
    status: 429,
    message: 'Too many requests. Please try again later.',
  },
  headers: true,
});
