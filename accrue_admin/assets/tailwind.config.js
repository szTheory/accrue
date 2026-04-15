const preset = require("./tailwind_preset");

module.exports = {
  content: ["../lib/**/*.{ex,heex}"],
  darkMode: ["variant", '&:where([data-theme="dark"], [data-theme="dark"] *, [data-theme="system"])'],
  presets: [preset]
};
