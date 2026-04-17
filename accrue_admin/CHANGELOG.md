# Changelog

<!-- Release Please will add entries here. -->

## Unreleased

### Fixed

- The committed `priv/static/accrue_admin.js` bundle is now real esbuild output (Phoenix + LiveView client). The previous single-line placeholder was invalid JavaScript in the browser (`Unexpected identifier 'by'`), which broke LiveView event delivery for admin flows and host Playwright proofs.
