# PinkVoidTheme

Cross-browser dark theme with pink accents. Works on Chrome, Edge, and Firefox.

## Project Structure

```
PinkVoidTheme/
├── .vscode/
│   └── settings.json
├── src/
│   ├── chrome/
│   │   └── manifest.json          # Chrome / Edge (Manifest V3)
│   ├── firefox/
│   │   └── manifest.json          # Firefox (Manifest V2)
│   └── styles/
│       └── bubble-dark-pink.css   # Cross-browser website CSS
├── dist/                          # Build output (zipped extensions)
├── .gitignore
└── README.md
```

## What It Does

1. **Browser UI theming** — Colors the browser frame, toolbar, tabs, omnibox, NTP, scrollbars, etc. via the `theme.colors` block in each manifest.
2. **Website content theming** — Injects `bubble-dark-pink.css` into every page via a content script to style links, headings, code, buttons, scrollbars, focus outlines, syntax highlighting, and more.

## Installation

### Chrome / Edge

1. Open `chrome://extensions/` (or `edge://extensions/`).
2. Enable **Developer mode** (toggle in the top-right).
3. Click **Load unpacked** and select the `src/chrome/` folder.
4. The extension uses `src/chrome/manifest.json` (Manifest V3).

### Firefox

1. Open `about:debugging#/runtime/this-firefox`.
2. Click **Load Temporary Add-on**.
3. Select `src/firefox/manifest.json`.
4. The extension uses `src/firefox/manifest.json` (Manifest V2).

> For permanent Firefox installation, package `src/firefox/` as `.zip` and rename to `.xpi`, then submit to addons.mozilla.org.

## Bundling for Store Submission

Zip the contents of each browser folder (not the folder itself):

```bash
# Chrome / Edge
cd src/chrome
zip ../../dist/PinkVoidTheme-chrome.zip manifest.json ../styles/bubble-dark-pink.css

# Firefox
cd src/firefox
zip ../../dist/PinkVoidTheme-firefox.zip manifest.json ../styles/bubble-dark-pink.css
```

Upload the `.zip` to the Chrome Web Store or addons.mozilla.org respectively.

## CSS Compatibility Notes

The original CSS (`bubble-dark-pink.md`) was written for Chrome and used several non-standard or limited-support features. It has been rewritten as `bubble-dark-pink.css` with the following fixes:

| Issue | Original | Fixed |
|-------|----------|-------|
| Scrollbars | `::-webkit-scrollbar-*` (WebKit only) | Added `scrollbar-width`/`scrollbar-color` for Firefox + kept `-webkit-` for Chrome/Edge/Safari |
| `:has()` | `button:has(.icon, ...)` | Removed — flattened selectors |
| CSS nesting | `& span`, `& svg` | Removed — fully flattened selectors |
| 8-digit hex | `#DB5C85A6`, `#A72B5338`, etc. | Converted to `rgba()` equivalents |
| File extension | `.md` | Renamed to `.css` |

## Files

- `src/chrome/manifest.json` — Chrome/Edge manifest with `theme.colors` + `content_scripts`
- `src/firefox/manifest.json` — Firefox manifest with `theme.colors` + `content_scripts` + `applications.gecko`
- `src/styles/bubble-dark-pink.css` — Cross-browser website CSS