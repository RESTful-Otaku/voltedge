// Security utilities for VoltEdge frontend

/**
 * Sanitize HTML content to prevent XSS attacks
 * @param {string} html - HTML string to sanitize
 * @returns {string} - Sanitized HTML
 */
export function sanitizeHTML(html) {
  if (typeof html !== "string") return "";

  // Create a temporary div element
  const temp = document.createElement("div");
  temp.textContent = html;
  return temp.innerHTML;
}

/**
 * Validate and sanitize user input
 * @param {string} input - User input to validate
 * @param {string} type - Type of validation ('text', 'number', 'email', 'url')
 * @returns {object} - { isValid: boolean, sanitized: string, error?: string }
 */
export function validateInput(input, type = "text") {
  if (typeof input !== "string") {
    return { isValid: false, sanitized: "", error: "Input must be a string" };
  }

  // Remove leading/trailing whitespace
  const sanitized = input.trim();

  // Check for empty input
  if (sanitized.length === 0) {
    return { isValid: false, sanitized: "", error: "Input cannot be empty" };
  }

  // Type-specific validation
  switch (type) {
    case "text":
      // Allow alphanumeric, spaces, and common punctuation
      if (!/^[a-zA-Z0-9\s\-_.,!?()]+$/.test(sanitized)) {
        return {
          isValid: false,
          sanitized: "",
          error: "Invalid characters in text input",
        };
      }
      break;

    case "number":
      if (!/^-?\d+(\.\d+)?$/.test(sanitized)) {
        return {
          isValid: false,
          sanitized: "",
          error: "Invalid number format",
        };
      }
      break;

    case "email":
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(sanitized)) {
        return { isValid: false, sanitized: "", error: "Invalid email format" };
      }
      break;

    case "url":
      try {
        new URL(sanitized);
      } catch {
        return { isValid: false, sanitized: "", error: "Invalid URL format" };
      }
      break;

    default:
      return { isValid: true, sanitized };
  }

  return { isValid: true, sanitized };
}

/**
 * Validate simulation parameters
 * @param {object} params - Simulation parameters
 * @returns {object} - { isValid: boolean, errors: string[], sanitized: object }
 */
export function validateSimulationParams(params) {
  const errors = [];
  const sanitized = {};

  // Validate simulation name
  if (params.name) {
    const nameValidation = validateInput(params.name, "text");
    if (!nameValidation.isValid) {
      errors.push(`Name: ${nameValidation.error}`);
    } else {
      sanitized.name = nameValidation.sanitized;
    }
  }

  // Validate power plant count
  if (params.powerPlantCount !== undefined) {
    const countValidation = validateInput(
      params.powerPlantCount.toString(),
      "number"
    );
    if (!countValidation.isValid) {
      errors.push(`Power plant count: ${countValidation.error}`);
    } else {
      const count = parseInt(countValidation.sanitized);
      if (count < 1 || count > 1000) {
        errors.push("Power plant count must be between 1 and 1000");
      } else {
        sanitized.powerPlantCount = count;
      }
    }
  }

  // Validate simulation duration
  if (params.duration !== undefined) {
    const durationValidation = validateInput(
      params.duration.toString(),
      "number"
    );
    if (!durationValidation.isValid) {
      errors.push(`Duration: ${durationValidation.error}`);
    } else {
      const duration = parseInt(durationValidation.sanitized);
      if (duration < 1 || duration > 86400) {
        // Max 24 hours
        errors.push("Duration must be between 1 and 86400 seconds");
      } else {
        sanitized.duration = duration;
      }
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
    sanitized,
  };
}

/**
 * Generate CSRF token
 * @returns {string} - CSRF token
 */
export function generateCSRFToken() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, (byte) => byte.toString(16).padStart(2, "0")).join(
    ""
  );
}

/**
 * Validate CSRF token
 * @param {string} token - Token to validate
 * @param {string} expected - Expected token
 * @returns {boolean} - Whether token is valid
 */
export function validateCSRFToken(token, expected) {
  if (!token || !expected) return false;
  return token === expected;
}

/**
 * Rate limiting helper
 */
export class RateLimiter {
  constructor(maxRequests = 100, windowMs = 60000) {
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
    this.requests = new Map();
  }

  isAllowed(identifier) {
    const now = Date.now();
    const windowStart = now - this.windowMs;

    // Clean old entries
    for (const [key, timestamp] of this.requests.entries()) {
      if (timestamp < windowStart) {
        this.requests.delete(key);
      }
    }

    // Check if limit exceeded
    if (this.requests.size >= this.maxRequests) {
      return false;
    }

    // Add current request
    this.requests.set(identifier, now);
    return true;
  }
}

/**
 * Content Security Policy helper
 * @returns {string} - CSP header value
 */
export function getCSPHeader() {
  return [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: https:",
    "font-src 'self' data:",
    "connect-src 'self' ws: wss:",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
  ].join("; ");
}

/**
 * Security headers for API requests
 * @returns {object} - Security headers
 */
export function getSecurityHeaders() {
  return {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "X-XSS-Protection": "1; mode=block",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
  };
}

/**
 * Log security events
 * @param {string} event - Event type
 * @param {object} details - Event details
 */
export function logSecurityEvent(event, details = {}) {
  console.warn(`[SECURITY] ${event}:`, details);

  // In production, this would send to a security monitoring service
  if (import.meta.env.PROD) {
    // Send to security monitoring service
    fetch("/api/security/log", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...getSecurityHeaders(),
      },
      body: JSON.stringify({
        event,
        details,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        url: window.location.href,
      }),
    }).catch((error) => {
      console.error("Failed to log security event:", error);
    });
  }
}
