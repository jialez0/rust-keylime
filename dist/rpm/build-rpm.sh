#!/usr/bin/env bash
set -euo pipefail

# Simple RPM build helper for keylime-agent
# - Creates ~/rpmbuild tree if missing
# - Packs current rust-keylime tree as Source0 with correct version
# - Invokes rpmbuild -ba with provided spec

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"   # .../rust-keylime
spec_path="${repo_root}/dist/rpm/keylime-agent.spec"

if [[ ! -f "${spec_path}" ]]; then
  echo "Spec not found: ${spec_path}" >&2
  exit 1
fi

require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 1; }; }
require_cmd rpmbuild
require_cmd tar
require_cmd awk

# Extract workspace package version from rust-keylime/Cargo.toml
version_file="${repo_root}/Cargo.toml"
if [[ ! -f "${version_file}" ]]; then
  echo "Cargo.toml not found at ${version_file}" >&2
  exit 1
fi

VERSION="$(awk '
  $0 ~ /^\[workspace.package\]/ { inwp=1; next }
  $0 ~ /^\[/ && $0 !~ /^\[workspace.package\]/ { inwp=0 }
  inwp && $0 ~ /^version\s*=\s*"/ { match($0, /"([^"]+)"/, a); print a[1]; exit }
' "${version_file}")"

if [[ -z "${VERSION}" ]]; then
  echo "Failed to parse version from ${version_file}" >&2
  exit 1
fi

rpmbuild_dir="${RPMBUILD_DIR:-${HOME}/rpmbuild}"
mkdir -p "${rpmbuild_dir}/SOURCES" "${rpmbuild_dir}/SPECS"

source_tar="${rpmbuild_dir}/SOURCES/rust-keylime-${VERSION}.tar.gz"

echo "Packing source to ${source_tar} ..."
tar -C "$(dirname "${repo_root}")" \
    -czf "${source_tar}" \
    --transform "s,^rust-keylime/,rust-keylime-${VERSION}/," \
    rust-keylime/

echo "Copying spec to ${rpmbuild_dir}/SPECS ..."
cp "${spec_path}" "${rpmbuild_dir}/SPECS/"

echo "Building binary RPMs (no SRPM) ..."
rpmbuild -bb "${rpmbuild_dir}/SPECS/$(basename "${spec_path}")"

echo "Artifacts:"
find "${rpmbuild_dir}/RPMS" -type f -name "keylime-agent-${VERSION}-*.rpm" -print || true

echo "Done."

