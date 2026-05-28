#!/usr/bin/env bash

set -euo pipefail

TOOL_NAME="1password-cli"
TOOL_TEST="op --version"
TOOL_GPG_KEY="3FEF9748469ADBE15DA7CA80AC2D62742012EA22"
TOOL_GROUP="onepassword-cli"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_all_versions() {
  cat \
    <(curl "${curl_opts[@]}" https://app-updates.agilebits.com/product_history/CLI |
      sed -n '/<h3/{n;p;}' |
      sed 's/[[:space:]]//g') \
    <(curl "${curl_opts[@]}" https://app-updates.agilebits.com/product_history/CLI2 |
      sed -n '/<h3/{n;p;}' |
      sed 's/[[:space:]]//g')
}

latest_stable_version() {
  local query="${1:-}"
  local latest=""

  while IFS= read -r version; do
    [ -z "$version" ] && continue
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
    if [ -n "$query" ] && [ "${version#"$query"}" = "$version" ]; then
      continue
    fi
    latest="$version"
  done < <(list_all_versions | sort_versions)

  [ -n "$latest" ] || fail "No stable version found matching '${query}'"
  printf "%s\n" "$latest"
}

resolve_version() {
  local version="$1"

  case "$version" in
    latest)
      latest_stable_version
      ;;
    latest:*)
      latest_stable_version "${version#latest:}"
      ;;
    *)
      printf "%s\n" "$version"
      ;;
  esac
}

download_release() {
  local version filename url
  version="$1"
  filename="$2"
  platform=$(get_platform)
  arch=$(get_arch)
  ext="zip"
  filter_platform=$platform

  case $platform in
    darwin)
      ext="pkg"
      filter_platform="apple\|darwin"
      arch="${arch}\|universal"
      ;;
  esac

  if [[ "$version" =~ ^1\..*$ ]]; then
    url=$(curl "${curl_opts[@]}" https://app-updates.agilebits.com/product_history/CLI)
  elif [[ "$version" =~ ^2\..*$ ]]; then
    url=$(curl "${curl_opts[@]}" https://app-updates.agilebits.com/product_history/CLI2)
  else
    fail "Unsupported $TOOL_NAME version '$version'"
  fi

  # Limit to version ${version}/
  url=$(echo "${url}" | grep "${version}\/")

  # Limit to ${filter_platform}
  url=$(echo "${url}" | grep "${filter_platform}")

  # Limit to architecture ${arch}
  url=$(echo "${url}" | grep "${arch}")

  # Limit to trailing extension \.${ext} (not /${ext}/ in path)
  url=$(echo "${url}" | grep "\.${ext}")

  # Ensure each link is on its own line
  # shellcheck disable=SC2001 # (bash 3.2.x parameter expansion can't handle newlines)
  url=$(echo "${url}" | sed -e "s/<a /\n<a /g")

  # Strip off HTML
  url=$(echo "${url}" | sed -e 's/<a .*href=['"'"'"]//' -e 's/["'"'"'].*$//' -e '/^$/ d')

  # Lose extraneous spaces
  url=$(echo "${url}" | sed '/^[[:space:]]*$/d')

  # Require HTTPS
  url=$(echo "${url}" | grep -o "https.*$")

  # Expect only one line
  if [[ $(echo "$url" | wc -l | tr -d ' ') -gt 1 ]]; then
    echo "Unable to winnow down to a single URL:"
    echo "$url"
    exit 1
  elif [[ ${url} == "" ]]; then
    echo "Failed to extract a URL for version ${version}"
    exit 1
  fi

  echo "* Downloading $TOOL_NAME release $version..."
  curl "${curl_opts[@]}" -o "$filename.${ext}" -C - "$url" || fail "Could not download $url"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="$3"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  local resolved_version
  resolved_version=$(resolve_version "$version")

  (
    platform=$(get_platform)
    mkdir -p "$install_path/bin"
    case $platform in
      darwin)
        ext="pkg"
        pkgutil --expand "${ASDF_DOWNLOAD_PATH}/${TOOL_NAME}-${resolved_version}.${ext}" "${ASDF_DOWNLOAD_PATH}/extracted/"
        pushd "$install_path/bin"
        cpio -i -F "${ASDF_DOWNLOAD_PATH}/extracted/op.${ext}/Payload" 2>/dev/null
        popd
        ;;
      *)
        cp -R "$ASDF_DOWNLOAD_PATH/." "$install_path/bin"
        chmod +x "$install_path/bin/op"
        set_onepassword_group_permissions "$install_path/bin/op"
        if gpg_cmd=$(get_gpg_command); then
          "$gpg_cmd" --keyserver hkps://keyserver.ubuntu.com:443 --receive-keys "$TOOL_GPG_KEY"
          "$gpg_cmd" --verify "$install_path/bin/op.sig" "$install_path/bin/op" || fail "asdf-$TOOL_NAME download file verify fail with GPG."
        fi
        ;;
    esac

    local tool_cmd
    tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
    test -x "$install_path/bin/$tool_cmd" || fail "Expected $install_path/bin/$tool_cmd to be executable."

    echo "$TOOL_NAME $resolved_version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error ocurred while installing $TOOL_NAME $resolved_version."
  )
}

get_arch() {
  local arch=""

  case "$(uname -m)" in
    x86_64 | amd64) arch="amd64" ;;
    i686 | i386) arch="386" ;;
    armv6l | armv7l) arch="arm" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)
      fail "Arch '$(uname -m)' not supported!"
      ;;
  esac

  echo -n $arch
}

get_platform() {
  local platform=""

  case "$(uname | tr '[:upper:]' '[:lower:]')" in
    darwin) platform="darwin" ;;
    freebsd) platform="freebsd" ;;
    linux) platform="linux" ;;
    openbsd) platform="openbsd" ;;
    windows) platform="windows" ;;
    *)
      fail "Platform '$(uname -m)' not supported!"
      ;;
  esac

  echo -n $platform
}

program_exists() {
  command -v "$1" >/dev/null 2>&1
}

get_gpg_command() {
  if program_exists gpg; then
    printf "%s\n" "gpg"
  elif program_exists gpg2; then
    printf "%s\n" "gpg2"
  else
    return 1
  fi
}

set_onepassword_group_permissions() {
  local executable="$1"

  if ! program_exists getent; then
    return 0
  fi

  if getent group "$TOOL_GROUP" >/dev/null 2>&1; then
    if ! chgrp "$TOOL_GROUP" "$executable" 2>/dev/null; then
      echo "Could not change group of $executable to $TOOL_GROUP. Run the README app integration commands with sudo if needed." >&2
      return 0
    fi
    if ! chmod g+s "$executable" 2>/dev/null; then
      echo "Could not set setgid bit on $executable. Run the README app integration commands with sudo if needed." >&2
      return 0
    fi
    echo "Set $TOOL_GROUP group permissions on $executable"
  fi
}
