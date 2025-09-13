// Accessibility utilities for VoltEdge frontend

/**
 * Generate unique ID for accessibility
 * @param {string} prefix - ID prefix
 * @returns {string} - Unique ID
 */
export function generateId(prefix = "voltedge") {
  return `${prefix}-${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Announce message to screen readers
 * @param {string} message - Message to announce
 * @param {string} priority - Priority level ('polite' or 'assertive')
 */
export function announceToScreenReader(message, priority = "polite") {
  const announcement = document.createElement("div");
  announcement.setAttribute("aria-live", priority);
  announcement.setAttribute("aria-atomic", "true");
  announcement.className = "sr-only";
  announcement.textContent = message;

  document.body.appendChild(announcement);

  // Remove after announcement
  setTimeout(() => {
    document.body.removeChild(announcement);
  }, 1000);
}

/**
 * Focus management utilities
 */
export class FocusManager {
  constructor() {
    this.focusableElements =
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';
    this.previousFocus = null;
  }

  /**
   * Trap focus within an element
   * @param {HTMLElement} container - Container element
   */
  trapFocus(container) {
    const focusableElements = container.querySelectorAll(
      this.focusableElements
    );
    const firstElement = focusableElements[0];
    const lastElement = focusableElements[focusableElements.length - 1];

    const handleTabKey = (e) => {
      if (e.key === "Tab") {
        if (e.shiftKey) {
          if (document.activeElement === firstElement) {
            lastElement.focus();
            e.preventDefault();
          }
        } else {
          if (document.activeElement === lastElement) {
            firstElement.focus();
            e.preventDefault();
          }
        }
      }
    };

    container.addEventListener("keydown", handleTabKey);

    // Focus first element
    if (firstElement) {
      firstElement.focus();
    }

    return () => {
      container.removeEventListener("keydown", handleTabKey);
    };
  }

  /**
   * Save current focus and restore later
   */
  saveFocus() {
    this.previousFocus = document.activeElement;
  }

  /**
   * Restore previously saved focus
   */
  restoreFocus() {
    if (this.previousFocus && this.previousFocus.focus) {
      this.previousFocus.focus();
    }
  }
}

/**
 * Keyboard navigation utilities
 */
export const keyboardNavigation = {
  // Arrow key navigation for grid layouts
  handleArrowKeys(event, currentIndex, totalItems, columns = 1) {
    const { key } = event;
    let newIndex = currentIndex;

    switch (key) {
      case "ArrowUp":
        newIndex = Math.max(0, currentIndex - columns);
        break;
      case "ArrowDown":
        newIndex = Math.min(totalItems - 1, currentIndex + columns);
        break;
      case "ArrowLeft":
        newIndex = Math.max(0, currentIndex - 1);
        break;
      case "ArrowRight":
        newIndex = Math.min(totalItems - 1, currentIndex + 1);
        break;
      case "Home":
        newIndex = 0;
        break;
      case "End":
        newIndex = totalItems - 1;
        break;
      default:
        return currentIndex;
    }

    if (newIndex !== currentIndex) {
      event.preventDefault();
      return newIndex;
    }

    return currentIndex;
  },

  // Handle Enter and Space key activation
  handleActivation(event, callback) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      callback();
    }
  },
};

/**
 * Color contrast utilities
 */
export const colorContrast = {
  /**
   * Calculate relative luminance
   * @param {number} r - Red component (0-255)
   * @param {number} g - Green component (0-255)
   * @param {number} b - Blue component (0-255)
   * @returns {number} - Relative luminance
   */
  getRelativeLuminance(r, g, b) {
    const [rs, gs, bs] = [r, g, b].map((c) => {
      c = c / 255;
      return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
  },

  /**
   * Calculate contrast ratio between two colors
   * @param {string} color1 - First color (hex)
   * @param {string} color2 - Second color (hex)
   * @returns {number} - Contrast ratio
   */
  getContrastRatio(color1, color2) {
    const rgb1 = this.hexToRgb(color1);
    const rgb2 = this.hexToRgb(color2);

    const l1 = this.getRelativeLuminance(rgb1.r, rgb1.g, rgb1.b);
    const l2 = this.getRelativeLuminance(rgb2.r, rgb2.g, rgb2.b);

    const lighter = Math.max(l1, l2);
    const darker = Math.min(l1, l2);

    return (lighter + 0.05) / (darker + 0.05);
  },

  /**
   * Convert hex color to RGB
   * @param {string} hex - Hex color
   * @returns {object} - RGB object
   */
  hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result
      ? {
          r: parseInt(result[1], 16),
          g: parseInt(result[2], 16),
          b: parseInt(result[3], 16),
        }
      : null;
  },

  /**
   * Check if contrast ratio meets WCAG standards
   * @param {string} foreground - Foreground color
   * @param {string} background - Background color
   * @param {string} level - WCAG level ('AA' or 'AAA')
   * @returns {boolean} - Whether contrast meets standards
   */
  meetsWCAG(foreground, background, level = "AA") {
    const ratio = this.getContrastRatio(foreground, background);
    const requiredRatio = level === "AAA" ? 7 : 4.5;
    return ratio >= requiredRatio;
  },
};

/**
 * Screen reader utilities
 */
export const screenReader = {
  /**
   * Create screen reader only text
   * @param {string} text - Text for screen readers
   * @returns {string} - HTML with screen reader class
   */
  only(text) {
    return `<span class="sr-only">${text}</span>`;
  },

  /**
   * Create visually hidden but accessible text
   * @param {string} text - Text to hide visually
   * @returns {string} - HTML with visually hidden class
   */
  visuallyHidden(text) {
    return `<span class="visually-hidden">${text}</span>`;
  },

  /**
   * Create accessible button text
   * @param {string} visibleText - Visible text
   * @param {string} screenReaderText - Additional context for screen readers
   * @returns {string} - Combined accessible text
   */
  buttonText(visibleText, screenReaderText) {
    return `${visibleText} ${this.only(screenReaderText)}`;
  },
};

/**
 * Responsive design utilities
 */
export const responsive = {
  /**
   * Get current breakpoint
   * @returns {string} - Current breakpoint name
   */
  getCurrentBreakpoint() {
    const width = window.innerWidth;
    if (width < 640) return "sm";
    if (width < 768) return "md";
    if (width < 1024) return "lg";
    if (width < 1280) return "xl";
    return "2xl";
  },

  /**
   * Check if current viewport is mobile
   * @returns {boolean} - Whether viewport is mobile
   */
  isMobile() {
    return window.innerWidth < 768;
  },

  /**
   * Check if current viewport is tablet
   * @returns {boolean} - Whether viewport is tablet
   */
  isTablet() {
    return window.innerWidth >= 768 && window.innerWidth < 1024;
  },

  /**
   * Check if current viewport is desktop
   * @returns {boolean} - Whether viewport is desktop
   */
  isDesktop() {
    return window.innerWidth >= 1024;
  },
};

/**
 * Animation utilities for reduced motion
 */
export const animation = {
  /**
   * Check if user prefers reduced motion
   * @returns {boolean} - Whether user prefers reduced motion
   */
  prefersReducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  },

  /**
   * Get appropriate animation duration based on user preferences
   * @param {number} defaultDuration - Default duration in ms
   * @returns {number} - Appropriate duration
   */
  getDuration(defaultDuration = 300) {
    return this.prefersReducedMotion() ? 0 : defaultDuration;
  },

  /**
   * Get appropriate animation easing based on user preferences
   * @param {string} defaultEasing - Default easing function
   * @returns {string} - Appropriate easing
   */
  getEasing(defaultEasing = "ease-in-out") {
    return this.prefersReducedMotion() ? "linear" : defaultEasing;
  },
};
