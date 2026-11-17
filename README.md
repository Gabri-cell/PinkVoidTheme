# PinkVoidTheme

Cross-browser dark theme with pink accents. Works on Chrome, Edge, and Firefox.

## Project Structure

```
src/
  manifest.json            # Chrome / Edge (Manifest V3)
  manifest.firefox.json    # Firefox (Manifest V2)
  bubble-dark-pink.css     # Cross-browser website CSS (content script)
```

## What It Does

1. **Browser UI theming** — Colors the browser frame, toolbar, tabs, omnibox, NTP, scrollbars, etc. via the `theme.colors` block in each manifest.
2. **Website content theming** — Injects `bubble-dark-pink.css` into every page via a content script to style links, headings, code, buttons, scrollbars, focus outlines, syntax highlighting, and more.

## Installation

### Chrome / Edge

1. Open `chrome://extensions/` (or `edge://extensions/`).
2. Enable **Developer mode** (toggle in the top-right).
3. Click **Load unpacked** and select the `src/` folder.
4. The extension uses `manifest.json` (Manifest V3).

### Firefox

1. Open `about:debugging#/runtime/this-firefox`.
2. Click **Load Temporary Add-on**.
3. Select `src/manifest.firefox.json`.
4. The extension uses `manifest.firefox.json` (Manifest V2).

> For permanent Firefox installation, package `manifest.firefox.json` as `.zip` and rename to `.xpi`, then submit to addons.mozilla.org.

## Bundling for Store Submission

Zip the contents of `src/` (not the folder itself):

```bash
# Chrome / Edge
cd src
zip ../PinkVoidTheme-chrome.zip manifest.json bubble-dark-pink.css

# Firefox
cd src
zip ../PinkVoidTheme-firefox.zip manifest.firefox.json bubble-dark-pink.css
```

Upload the `.zip` to the Chrome Web Store or addons.mozilla.org respectively.

## CSS Compatibility Notes

The original CSS (`bubble-dark-pink.md`) was written for Chrome and used several non-standard or limited-support features. It has been rewritten as `bubble-dark-pink.css` with the following fixes:

| Issue | Original | Fixed |
|-------|----------|-------|
| Scrollbars | `::-webkit-scrollbar-*` (WebKit only) | Added `scrollbar-width`/`scrollbar-color` for Firefox + kept `-webkit-` for Chrome/Edge/Safari |
| `:has()` | `button:has(.icon, ...)` | Flattened selectors — no `:has()` needed |
| CSS nesting | `& span`, `& svg` | Fully flattened selectors |
| 8-digit hex | `#DB5C85A6`, `#A72B5338`, etc. | Converted to `rgba()` equivalents |
| File type | `.md` | Renamed to `.css` |

## Files

- `src/manifest.json` — Chrome/Edge manifest with `theme.colors` + `content_scripts`
- `src/manifest.firefox.json` — Firefox manifest with `theme.colors` + `content_scripts` + `applications.gecko`
- `src/bubble-dark-pink.css` — Cross-browser website CSS