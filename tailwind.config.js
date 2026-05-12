/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.{erb,html}',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        bg: '#0A0A0A',
        surface: '#111113',
        'surface-2': '#1A1A1D',
        border: '#27272A',
        'border-2': '#3F3F46',
        text: '#FAFAFA',
        'text-dim': '#A1A1AA',
        'text-mute': '#52525B',
        accent: '#C7F36A',
        'accent-ink': '#0A0A0A',
        'accent-hi': '#D6FF8C',
        danger: '#F87171',
        warn: '#FBBF24',
        ok: '#34D399'
      },
      fontFamily: {
        sans: [
          '-apple-system', 'BlinkMacSystemFont', '"Segoe UI Variable"',
          '"Segoe UI"', 'system-ui', 'Roboto', '"Helvetica Neue"', 'Arial',
          'sans-serif'
        ],
        mono: [
          'ui-monospace', '"SF Mono"', 'Menlo', 'Monaco', 'Consolas',
          '"Liberation Mono"', '"Courier New"', 'monospace'
        ]
      },
      borderRadius: {
        sm: '6px',
        DEFAULT: '10px',
        lg: '14px'
      },
      keyframes: {
        'fade-in-up': {
          '0%': { opacity: '0', transform: 'translateY(6px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        }
      },
      animation: {
        'fade-in-up': 'fade-in-up 0.35s ease forwards'
      }
    }
  },
  plugins: []
}
