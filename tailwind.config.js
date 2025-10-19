// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require('tailwindcss/plugin')

module.exports = {
  darkMode: ['selector', '[data-theme="dark"]'],
  content: [
    './js/**/*.js',
    '../lib/yachanakuy_web.ex',
    '../lib/yachanakuy_web/**/*.*ex'
  ],
  theme: {
    extend: {
      colors: {
        'primary': '#144D85',     // CCBOL blue
        'secondary': '#B33536',   // CCBOL red
        'accent': '#FFFFFF',      // CCBOL white
        'primary-dark': '#0d3a66', // Darker blue for contrast
        'primary-light': '#e6f0fa', // Lighter blue for backgrounds
        'secondary-dark': '#8a2a2b', // Darker red for contrast
        'secondary-light': '#f9e6e6', // Lighter red for backgrounds
        'text-primary': '#144D85', // Primary text color
        'text-secondary': '#B33536', // Secondary text color
        'text-accent': '#FFFFFF', // Text on dark backgrounds
        'background-primary': '#FFFFFF', // Primary background
        'background-secondary': '#f9f9f9', // Secondary background
        'border-primary': '#144D85', // Primary border
        'border-secondary': '#B33536', // Secondary border
      },
      fontFamily: {
        'heading': ['Montserrat', 'sans-serif'],
        'body': ['Montserrat', 'sans-serif'],
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio'),
    plugin(({ addVariant }) => addVariant('phx-click-loading', ['&.phx-click-loading', '.phx-click-loading &'])),
    plugin(({ addVariant }) => addVariant('phx-submit-loading', ['&.phx-submit-loading', '.phx-submit-loading &'])),
    plugin(({ addVariant }) => addVariant('phx-change-loading', ['&.phx-change-loading', '.phx-change-loading &']))
  ]
}