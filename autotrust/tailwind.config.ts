import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#E30613',
          50:  '#FFF1F1',
          100: '#FFE0E1',
          200: '#FFC0C2',
          300: '#FF8F93',
          400: '#FF545A',
          500: '#E30613',
          600: '#CC0511',
          700: '#A0040D',
          800: '#840710',
          900: '#6E0B13',
        },
        dark: '#0A0A0A',
        silver: '#C0C0C0',
        surface: '#111111',
        muted: '#6B7280',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        heading: ['Montserrat', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        'card': '0 4px 24px rgba(0,0,0,0.12)',
        'card-hover': '0 12px 48px rgba(0,0,0,0.2)',
        'red': '0 8px 24px rgba(227,6,19,0.35)',
      },
      animation: {
        'fade-up': 'fadeUp 0.5s ease-out forwards',
        'fade-in': 'fadeIn 0.3s ease-out forwards',
        'slide-in': 'slideIn 0.4s ease-out forwards',
        'pulse-red': 'pulseRed 2s infinite',
      },
      keyframes: {
        fadeUp: {
          from: { opacity: '0', transform: 'translateY(20px)' },
          to:   { opacity: '1', transform: 'translateY(0)' },
        },
        fadeIn: {
          from: { opacity: '0' },
          to:   { opacity: '1' },
        },
        slideIn: {
          from: { opacity: '0', transform: 'translateX(-20px)' },
          to:   { opacity: '1', transform: 'translateX(0)' },
        },
        pulseRed: {
          '0%, 100%': { boxShadow: '0 0 0 0 rgba(227,6,19,0.4)' },
          '70%':      { boxShadow: '0 0 0 10px rgba(227,6,19,0)' },
        },
      },
    },
  },
  plugins: [],
};

export default config;
