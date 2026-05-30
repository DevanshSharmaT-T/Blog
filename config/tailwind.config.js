const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  // Wire `dark:` utilities to the app's in-app theme toggle (data-theme on <html>),
  // not the OS prefers-color-scheme.
  darkMode: ['selector', '[data-theme="dark"]'],
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    // require('@tailwindcss/forms'),
    // require('@tailwindcss/typography'),
    // require('@tailwindcss/container-queries'),
  ]
}
