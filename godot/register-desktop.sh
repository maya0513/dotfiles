#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
readonly APP_EXECUTABLE="/usr/local/bin/godot"
readonly DESKTOP_ID="org.godotengine.Godot.desktop"
readonly MIME_TYPE="application/x-godot-project"
readonly MANAGED_MARKER="X-Chezmoi-Dotfiles-Managed=true"
readonly DATA_HOME="${XDG_DATA_HOME:-${HOME:?HOME must be set}/.local/share}"
readonly APPLICATIONS_DIR="${DATA_HOME}/applications"
readonly DESKTOP_FILE="${APPLICATIONS_DIR}/${DESKTOP_ID}"
readonly ICON_NAME="org.godotengine.Godot"
readonly ICON_SOURCE="${SCRIPT_DIR}/assets/${ICON_NAME}.svg"
readonly ICON_THEME_DIR="${DATA_HOME}/icons/hicolor"
readonly ICON_DIR="${ICON_THEME_DIR}/scalable/apps"

TEMP_FILE=""
cleanup() {
  [[ -z "${TEMP_FILE}" || ! -e "${TEMP_FILE}" ]] || rm -f -- "${TEMP_FILE}"
}
trap cleanup EXIT

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

main() {
  [[ $# -eq 0 ]] || die "usage: $0"
  local command_name
  for command_name in cat chmod grep install mkdir mktemp mv rm xdg-mime; do
    command -v "${command_name}" >/dev/null 2>&1 || die "required command is missing: ${command_name}"
  done
  [[ -x "${APP_EXECUTABLE}" ]] || die "application executable is unavailable: ${APP_EXECUTABLE}"
  [[ -r "${ICON_SOURCE}" ]] || die "application icon is unavailable: ${ICON_SOURCE}"

  mkdir -p -- "${APPLICATIONS_DIR}"
  if [[ -e "${DESKTOP_FILE}" || -L "${DESKTOP_FILE}" ]]; then
    if [[ ! -f "${DESKTOP_FILE}" ]] || ! grep -Fqx "${MANAGED_MARKER}" "${DESKTOP_FILE}"; then
      die "refusing to replace an unmanaged desktop entry: ${DESKTOP_FILE}"
    fi
  fi

  mkdir -p -- "${ICON_DIR}"
  TEMP_FILE="$(mktemp "${ICON_DIR}/.${ICON_NAME}.XXXXXX")"
  install -m 0644 -- "${ICON_SOURCE}" "${TEMP_FILE}"
  mv -f -- "${TEMP_FILE}" "${ICON_DIR}/${ICON_NAME}.svg"
  TEMP_FILE=""
  printf '[OK] installed %s\n' "${ICON_DIR}/${ICON_NAME}.svg"

  TEMP_FILE="$(mktemp "${APPLICATIONS_DIR}/.${DESKTOP_ID}.XXXXXX")"
  cat >"${TEMP_FILE}" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Godot Engine
GenericName=Game engine
Exec=${APP_EXECUTABLE} %f
TryExec=${APP_EXECUTABLE}
Icon=${ICON_NAME}
Terminal=false
Categories=Development;IDE;
MimeType=application/x-godot-project;
StartupWMClass=Godot
${MANAGED_MARKER}
EOF
  chmod 0644 "${TEMP_FILE}"
  mv -f -- "${TEMP_FILE}" "${DESKTOP_FILE}"
  TEMP_FILE=""
  printf '[OK] registered %s\n' "${DESKTOP_FILE}"

  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache --force --ignore-theme-index "${ICON_THEME_DIR}"
  fi

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${APPLICATIONS_DIR}"
  else
    printf '[WARN] update-desktop-database is unavailable; the app list may refresh at login\n' >&2
  fi

  xdg-mime default "${DESKTOP_ID}" "${MIME_TYPE}"
  printf '[OK] %s\n' 'project.godot files default to Godot'
  printf '[INFO] current default: %s\n' "$(xdg-mime query default "${MIME_TYPE}")"
}

main "$@"
