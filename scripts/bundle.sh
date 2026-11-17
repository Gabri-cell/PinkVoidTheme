#!/usr/bin/env bash
#
# scripts/bundle.sh
#
# Build zip bundles for PinkVoidTheme browser extensions.
#
# Output (one per browser):
#   dist/pink-void.chrome.zip   # Chrome / Edge (Manifest V3)
#   dist/pink-void.firefox.zip  # Firefox (Manifest V2)
#   dist/pink-void.edge.zip     # Edge Add-ons (same payload as Chrome)
#
# Each zip places files at its root (no wrapper folder, no ".." paths):
#   manifest.json
#   styles/bubble-dark-pink.css
#
# Usage:
#   ./scripts/bundle.sh                         # bundle all browsers
#   ./scripts/bundle.sh --browser chrome        # single browser
#   ./scripts/bundle.sh --browser firefox --output-dir ./build
#   ./scripts/bundle.sh --clean                 # remove old zips first
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SRC_DIR="${REPO_ROOT}/src"
STYLES_DIR="${SRC_DIR}/styles"
CSS_FILE="${STYLES_DIR}/bubble-dark-pink.css"

DEFAULT_OUTPUT_DIR="${REPO_ROOT}/dist"

# Browser -> manifest location. Edge reuses the Chrome (MV3) manifest.
declare -A BROWSER_MANIFEST=(
  [chrome]="${SRC_DIR}/chrome/manifest.json"
  [edge]="${SRC_DIR}/chrome/manifest.json"
  [firefox]="${SRC_DIR}/firefox/manifest.json"
)

ALL_BROWSERS=("chrome" "firefox" "edge")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()   { printf '==> %s\n' "$*"; }
warn()  { printf 'warn: %s\n' "$*" >&2; }
err()   { printf 'error: %s\n' "$*" >&2; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Build zip bundles for PinkVoidTheme browser extensions.

Options:
  --browser <name>      Browser to bundle: chrome, firefox, edge, or all
                        (default: all)
  --output-dir <dir>    Directory for output zips (default: dist)
  --clean               Remove existing pink-void.*.zip files in output dir
                        before building
  -h, --help            Show this help message

Output naming: pink-void.<browser>.zip  (e.g. pink-void.chrome.zip)

Requires: zip
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
BROWSERS=()
OUTPUT_DIR="${DEFAULT_OUTPUT_DIR}"
CLEAN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --browser)
      [[ $# -ge 2 ]] || { err "--browser requires a value"; exit 2; }
      BROWSERS+=("$2"); shift 2 ;;
    --output-dir)
      [[ $# -ge 2 ]] || { err "--output-dir requires a value"; exit 2; }
      OUTPUT_DIR="$2"; shift 2 ;;
    --clean)
      CLEAN=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      err "unknown option: $1"; usage; exit 2 ;;
  esac
done

# Default to all browsers when none specified
if [[ ${#BROWSERS[@]} -eq 0 ]]; then
  BROWSERS=("${ALL_BROWSERS[@]}")
fi

# Resolve OUTPUT_DIR to an absolute path so it stays valid after we cd into
# the staging directory to run zip.
case "${OUTPUT_DIR}" in
  /*) ;;
  *) OUTPUT_DIR="${REPO_ROOT}/${OUTPUT_DIR}" ;;
esac

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
command -v zip >/dev/null 2>&1 || {
  err "'zip' is required but not installed."
  err "Install it, e.g. in Git Bash:  pacman -S zip"
  exit 1
}

[[ -f "${CSS_FILE}" ]] || {
  err "shared CSS not found: ${CSS_FILE}"
  exit 1
}

# Read version from the Chrome manifest (single source of truth)
VERSION="$(grep -m1 '"version"' "${SRC_DIR}/chrome/manifest.json" \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)"
VERSION="${VERSION:-unknown}"

mkdir -p "${OUTPUT_DIR}"

if [[ "${CLEAN}" -eq 1 ]]; then
  log "Cleaning old bundles in ${OUTPUT_DIR}"
  rm -f "${OUTPUT_DIR}"/pink-void.*.zip
fi

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
build_bundle() {
  local browser="$1"
  local manifest="${BROWSER_MANIFEST[$browser]:-}"

  if [[ -z "${manifest}" ]]; then
    warn "unsupported browser '${browser}' — skipping"
    return 0
  fi

  if [[ ! -f "${manifest}" ]]; then
    warn "manifest not found for '${browser}': ${manifest} — skipping"
    return 0
  fi

  local zip_name="pink-void.${browser}.zip"
  local zip_path="${OUTPUT_DIR}/${zip_name}"

  log "building ${browser} (v${VERSION}) -> ${zip_path}"

  # Stage files so they land at the zip root with clean paths:
  #   manifest.json
  #   styles/bubble-dark-pink.css
  local staging
  staging="$(mktemp -d)"
  local stage_root="${staging}/${browser}"
  mkdir -p "${stage_root}/styles"

  cp "${manifest}" "${stage_root}/manifest.json"
  cp "${CSS_FILE}" "${stage_root}/styles/bubble-dark-pink.css"

  # Remove any previous zip so the update below starts clean
  rm -f "${zip_path}"

  (cd "${stage_root}" && zip -r -X "${zip_path}" manifest.json styles/ >/dev/null)

  rm -rf "${staging}"

  if [[ -f "${zip_path}" ]]; then
    local size
    size="$(du -h "${zip_path}" | cut -f1)"
    log "  ${zip_name} ready (${size})"
  else
    err "failed to create ${zip_path}"
    return 1
  fi
}

failed=0
for browser in "${BROWSERS[@]}"; do
  if ! build_bundle "${browser}"; then
    failed=1
  fi
done

if [[ "${failed}" -ne 0 ]]; then
  err "one or more bundles failed to build"
  exit 1
fi

log "done — bundles in ${OUTPUT_DIR}/"
ls -1 "${OUTPUT_DIR}"/pink-void.*.zip 2>/dev/null | sed 's/^/  /' || true
