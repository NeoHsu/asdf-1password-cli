#!/usr/bin/env bash

set -euo pipefail

TOOL_NAME="1password-cli"
TOOL_TEST="op --version"
TOOL_GPG_KEY="3FEF9748469ADBE15DA7CA80AC2D62742012EA22"

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
    <(curl -s https://app-updates.agilebits.com/product_history/CLI |
      sed -n '/<h3/{n;p;}' |
      sed 's/[[:space:]]//g') \
    <(curl -s https://app-updates.agilebits.com/product_history/CLI2 |
      sed -n '/<h3/{n;p;}' |
      sed 's/[[:space:]]//g')
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
    url=$(curl -s https://app-updates.agilebits.com/product_history/CLI)
  elif [[ "$version" =~ ^2\..*$ ]]; then
    url=$(curl -s https://app-updates.agilebits.com/product_history/CLI2)
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

  (
    platform=$(get_platform)
    mkdir -p "$install_path/bin"
    case $platform in
      darwin)
        ext="pkg"
        pkgutil --expand "${ASDF_DOWNLOAD_PATH}/${TOOL_NAME}-${ASDF_INSTALL_VERSION}.${ext}" "${ASDF_DOWNLOAD_PATH}/extracted/"
        pushd "$install_path/bin"
        cpio -i -F "${ASDF_DOWNLOAD_PATH}/extracted/op.${ext}/Payload" 2>/dev/null
        popd
        ;;
      *)
        cp -R "$ASDF_DOWNLOAD_PATH/." "$install_path/bin"
        is_exists=$(program_exists)
        echo "$is_exists"
        if [ "$is_exists" != 0 ]; then
          gpg --keyserver hkps://keyserver.ubuntu.com:443 --receive-keys "$TOOL_GPG_KEY"
          gpg --verify "$install_path/bin/op.sig" "$install_path/bin/op" || fail "asdf-$TOOL_NAME download file verify fail with GPG."
        fi
        ;;
    esac

    local tool_cmd
    tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
    test -x "$install_path/bin/$tool_cmd" || fail "Expected $install_path/bin/$tool_cmd to be executable."

    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error ocurred while installing $TOOL_NAME $version."
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
  local ret='0'
  command -v gpg gpg2 >/dev/null 2>&1 || { local ret='1'; }

  if [ "$ret" -ne 0 ]; then
    return 1
  fi

  return 0
}
