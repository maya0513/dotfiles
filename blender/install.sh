#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
# shellcheck source=lib/app-manager.sh
source "${SCRIPT_DIR}/../lib/app-manager.sh"
# shellcheck source=blender/config.sh
source "${SCRIPT_DIR}/config.sh"

readonly RELEASE_BASE_URL="https://download.blender.org/release"

WORK_DIR=""

cleanup() {
  if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
    rm -rf -- "${WORK_DIR}"
  fi
}

trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: blender/install.sh [VERSION]

Install a stable Blender release into /opt/blender/<version>.
VERSION may be X.Y.Z, latest, or omitted.
The installed version is printed to standard output.
EOF
}

resolve_version() {
  local requested="${1:-latest}"

  if [[ -z "${requested}" || "${requested}" == "latest" ]]; then
    info "Resolving the latest stable Blender release..."
    # www.blender.org/download/ is behind a Cloudflare challenge and
    # returns 403 to curl, so resolve from the official release index
    # on download.blender.org instead: the same host that serves the
    # archives and checksums used below.
    local release_index
    release_index="$(curl --fail --silent --show-error --location --retry 3 "${RELEASE_BASE_URL}/")" ||
      die "could not load the Blender release index"

    local -a series_list=()
    mapfile -t series_list < <(
      printf '%s\n' "${release_index}" |
        grep -oE 'Blender[0-9]+\.[0-9]+/' |
        grep -oE '[0-9]+\.[0-9]+' |
        sort -uV || true
    )

    # Newest series first; a series only counts if it actually
    # contains a stable Linux x64 archive.
    local series series_page version
    local i
    for ((i = ${#series_list[@]} - 1; i >= 0; i--)); do
      series="${series_list[i]}"
      [[ -n "${series}" ]] || continue
      series_page="$(curl --fail --silent --show-error --location --retry 3 "${RELEASE_BASE_URL}/Blender${series}/" || true)"
      [[ -n "${series_page}" ]] || continue
      version="$(
        printf '%s\n' "${series_page}" |
          grep -oE 'blender-[0-9]+\.[0-9]+\.[0-9]+-linux-x64\.tar\.xz' |
          grep -oE '[0-9]+\.[0-9]+\.[0-9]+' |
          sort -uV |
          tail -n 1 || true
      )"
      if [[ -n "${version}" ]]; then
        printf '%s\n' "${version}"
        return 0
      fi
    done
    die "could not resolve the latest stable Blender Linux x64 release"
  else
    canonical_version "${requested}"
  fi
}

main() {
  if (($# > 1)); then
    usage >&2
    exit 2
  fi
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  require_commands curl tar xz sha256sum awk mktemp uname cp grep sort tail
  require_linux_x86_64

  local version
  version="$(resolve_version "${1:-latest}")"
  if is_managed_installation "${version}"; then
    info "Blender ${version} is already installed."
    printf '%s\n' "${version}"
    return 0
  fi

  local target
  target="$(version_path "${version}")"
  if [[ -e "${target}" || -L "${target}" ]]; then
    die "${target} exists but is not a complete managed installation"
  fi

  require_root_access
  WORK_DIR="$(mktemp -d "/tmp/blender-${version}.XXXXXX")"

  local release_series="${version%.*}"
  local archive="blender-${version}-linux-x64.tar.xz"
  local release_url="${RELEASE_BASE_URL}/Blender${release_series}"
  local archive_path="${WORK_DIR}/${archive}"
  local sums_path="${WORK_DIR}/blender-${version}.sha256"

  info "Downloading Blender ${version}..."
  curl --fail --silent --show-error --location --retry 3 \
    --output "${archive_path}" "${release_url}/${archive}"
  curl --fail --silent --show-error --location --retry 3 \
    --output "${sums_path}" "${release_url}/blender-${version}.sha256"

  local checksum
  checksum="$(awk -v file="${archive}" '$2 == file || $2 == "*" file { print $1; exit }' "${sums_path}")"
  [[ "${checksum}" =~ ^[[:xdigit:]]{64}$ ]] ||
    die "could not find a valid SHA-256 checksum for ${archive}"
  printf '%s  %s\n' "${checksum}" "${archive}" >"${WORK_DIR}/archive.sha256"
  (cd "${WORK_DIR}" && sha256sum --check --strict archive.sha256 >&2)

  local staged_dir="${WORK_DIR}/staged"
  mkdir -p -- "${staged_dir}"
  tar --extract --xz --file "${archive_path}" --directory "${staged_dir}" --strip-components=1
  [[ -x "${staged_dir}/blender" ]] || die "archive did not contain the expected Blender executable"
  printf '%s %s\n' "${APP_NAME}" "${version}" >"${staged_dir}/.managed-by-chezmoi-dotfiles"

  publish_installation "${staged_dir}" "${version}"
  info "Installed Blender ${version} in ${target}."
  printf '%s\n' "${version}"
}

main "$@"
