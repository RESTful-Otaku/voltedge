/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
          950: '#172554'
        },
        energy: {
          coal: '#374151',
          gas: '#f59e0b',
          nuclear: '#10b981',
          hydro: '#06b6d4',
          wind: '#8b5cf6',
          solar: '#f59e0b',
          battery: '#ef4444'
        },
        grid: {
          healthy: '#10b981',
          warning: '#f59e0b',
          critical: '#ef4444',
          offline: '#6b7280'
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace']
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'bounce-slow': 'bounce 2s infinite',
        'spin-slow': 'spin 3s linear infinite'
      },
      boxShadow: {
        'energy': '0 4px 14px 0 rgba(59, 130, 246, 0.15)',
        'grid': '0 2px 8px 0 rgba(0, 0, 0, 0.1)'
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography')
  ]
};

